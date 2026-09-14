import importlib.util
import re
import shutil
import subprocess
import tempfile
import warnings
from pathlib import Path

import numpy as np
import scipy
from scipy.io import loadmat



    
    
def get_impulse_response(A, input_index, T=None, input_scale=1.0):
    """
    Calculates the impulse response of dx/dt = Ax + u for a specific input element.
    
    Parameters:
    ---
    A (array_like): The known state matrix A of shape (n, n).
    input_index (int): The index (0-based) of the input element u_j to pulse.
    T (array_like, optional): Time steps for the simulation. If None, it is auto-generated.
    input_scale (float, optional): Multiplicative scale for the selected input.
    
    Returns:
    ---
    t (ndarray): 1D array of time values.
    y (ndarray): Array of shape (len(t), n) containing the response of all states over time.
    """
    A = np.atleast_2d(A)
    n = A.shape[0]

    if A.shape != (n, n):
        raise ValueError(f"A must be square, got shape {A.shape}")

    if not 0 <= input_index < n:
        raise IndexError(f"input_index {input_index} out of range for {n} states")
    
    # B matrix isolates the specific input element
    B = np.zeros((n, 1))
    B[input_index, 0] = input_scale
    
    # C matrix is the identity matrix (assuming we want to observe all states)
    C = np.eye(n)
    D = np.zeros((n, 1)) # D matrix is zero
    
    # Define the continuous-time LTI system
    sys = scipy.signal.StateSpace(A, B, C, D)
    
    # Calculate the impulse response
    t, y = scipy.signal.impulse(sys, T=T)
    
    return t, y    


class TESModel:
    """
    Frequency-domain analysis wrapper for a linearized TES thermal model.

    ``TESModel`` combines three sources of information:

    * the OpenModelica-generated Python linearized model,
    * the full Modelica source used to recover conductance endpoints, and
    * steady-state simulation results used for component values.

    It precomputes the complex frequency grid and inverse system matrices used
    by impedance, responsivity, and noise calculations.
    """

    def __init__(self, linearized_model_filename, full_model_filename, simulation_results_filename, config, f_min = 1, f_max = 100e3, points = 1000, frequencies : np.ndarray | None = None):
        """
        Create a TES frequency-domain model.

        config: dict
            Dictionary containing the configuration parameters for the analysis. List of parameters:
            "L": Inductance value of the TES circuit in Henrys (H).
            "RL": Resistance value of the TES circuit in Ohms (Ω).
            
        We need to follow some conventions for the model to work properly. The first state variable must be the voltage across the TES, the second state variable must be the current through the TES. The third state variable must be the temperature of the TES. The rest of the state variables are the temperatures of each heat capacity cN, where N is the 1-based index of the heat capacity following increasing order. Example:
        
        ['CL_v','L_i','c1_T','c2_T','c3_T','c4_T','c5_T','c6_T','c7_T','c8_T','c9_T','c10_T']

        Parameters
        ----------
        linearized_model_filename : str, pathlib.Path, tuple, callable, or module
            Generated Python linearized model, or another supported input form
            accepted by ``load_linearized_model``.
        full_model_filename : str or pathlib.Path
            Full Modelica source file used to map each ``g*`` thermal
            conductance to its two connected heat-capacity endpoints.
        simulation_results : dict[str, array-like]
            Variables loaded from an OpenModelica result file by ``load``.
            The last value of entries such as ``RL.R``, ``CL.C``, ``L.L``,
            ``c*.C``, ``g*.K``, and ``g*.n`` is used as the operating point.
        config : dict
            Dictionary containing the configuration parameters for the
            analysis. Currently stored on the instance for caller use; expected
            keys include ``"L"`` and ``"RL"`` for inductance and load/shunt
            resistance.
        f_min, f_max , points: float, optional
            Minimum and maximum frequencies in Hz for the logarithmic analysis
            grid; Number of frequency samples between ``f_min`` and ``f_max``.
        frequencies: list | np.ndarray | None
            Frequency grid to evaluate the model, has higher priority than (f_min, f_max and points). If frequencies is given, will ignore the frequency range 

        Attributes
        ----------
        frequencies : numpy.ndarray
            Log-spaced frequency grid in Hz.
        iw : numpy.ndarray
            Complex angular frequencies, ``2j * pi * frequencies``.
        model : dict
            Normalized state-space model returned by ``load_linearized_model``.
        matrices_inv : dict
            Precomputed inverse matrix for each complex angular frequency.
        """
        timesteps, self.simulation_results = load(simulation_results_filename)
        self.config = config
        
        if frequencies is None:
            self.frequencies = np.logspace(np.log10(f_min), np.log10(f_max), points)
        else:
            self.frequencies = frequencies
        self.iw = 2j*np.pi*self.frequencies

        # Load models
        self.model = load_linearized_model(linearized_model_filename)
        self.model_conductance_map = parse_thermal_conductance_connections(full_model_filename)
        self.nparams = len(self.model["x0"])
        
        # hardcoded parameters
        self.n_capacities = self.nparams - 2 # First 2 are TES V and I, the rest are heat capacities
        self.index_cload_v = 0
        self.index_tes_i = 1
        self.index_tes_c = 2
        
        # Coefficients to be multiplied to external input if the input is given as [dV, dVbias, dP, ...]
        self.external_input_coeff = np.zeros(self.nparams)
        self.external_input_coeff[0] = 1/self.simulation_results[f"RL.R"][-1]/self.simulation_results[f"CL.C"][-1]
        self.external_input_coeff[1] = 1/self.simulation_results[f"L.L"][-1]
        for i in range(2, self.nparams):
            self.external_input_coeff[i] = 1/self.simulation_results[f"c{i-1}.C"][-1]
        
        # Calculate the matrix and the inverse of the matrix for each frequency
        self.matrices = {iw: self.get_matrix(iw) for iw in self.iw}
        self.matrices_inv = {iw: np.linalg.inv(matrix) for iw, matrix in self.matrices.items()}


    def _heat_capacity_state_index(self, index_cinput):
        """
        Convert a heat-capacity selector to a zero-based state index.
        """
        if index_cinput == 0:
            raise ValueError(
                "index_cinput is 1-based for heat capacities; use 1 for c1 "
                "or a negative value to count from the end"
            )

        if index_cinput < 0:
            ind = self.nparams + index_cinput
        else:
            ind = self.index_tes_c + index_cinput - 1

        if not self.index_tes_c <= ind < self.nparams:
            raise IndexError(
                f"index_cinput {index_cinput} selects state index {ind}, "
                f"but heat-capacity states are {self.index_tes_c}..{self.nparams - 1}"
            )

        return ind


    def _warn_if_unstable(self):
        """
        Warn when the linearized state matrix has unstable poles.
        """
        eigvals = np.linalg.eigvals(self.model["A"])
        max_real = np.max(eigvals.real)

        if max_real > 0:
            pole = eigvals[np.argmax(eigvals.real)]
            warnings.warn(
                "The linearized model has an unstable pole "
                f"({pole.real:.6g}{pole.imag:+.6g}j 1/s); "
                "the impulse response may diverge.",
                RuntimeWarning,
                stacklevel=2,
            )


    def get_matrix(self, iw):
        """
        Compute the matrix of the system of equations for a given frequency iw
        ---
        iw: complex float, complex frequency
        A: array of complex float, matrix of the system of equations

        Parameters
        ----------
        iw : complex
            Complex angular frequency, normally ``2j * pi * f``.

        Returns
        -------
        numpy.ndarray
            Complex matrix ``-A + iw * I`` used to solve the Fourier-domain
            perturbation equations.
        """
        A = self.model["A"]
        N = - A + iw*np.eye(A.shape[0]) # Compute eigenvectors
        return N
        
        
    def get_solution_full(self, external_input, norm = True):
        """
        Compute the solution of the system of equations of iw*X = A*X + external_input

        Parameters
        ----------
        external_input : array-like
            Excitation vector with one entry per state. When ``norm`` is true,
            entries are interpreted as physical perturbations such as voltage
            or power and multiplied by ``external_input_coeff``.
        norm : bool, optional
            If true, scale ``external_input`` by the operating-point
            coefficients before solving. If false, use ``external_input``
            directly as the right-hand side.

        Returns
        -------
        numpy.ndarray
            Complex response array with shape ``(len(frequencies), nparams)``.
        """
        d_out = []
        for iw in self.iw:
            if norm:
                d_in = external_input * self.external_input_coeff
            else:
                d_in = external_input
            d_out.append(self.matrices_inv[iw].dot(d_in))
        d_out = np.array(d_out)
        return d_out
        
    def get_solution_single(self, index_input, index_output):
        """
        Solve the response from one input coordinate to one output coordinate.

        Parameters
        ----------
        index_input : int
            Zero-based state-space coordinate to excite. The excitation uses
            the corresponding ``external_input_coeff`` value.
        index_output : int
            Zero-based state-space coordinate to read from the solved response.

        Returns
        -------
        numpy.ndarray
            Complex transfer function sampled on ``self.frequencies``.
        """
        d_out = []
        for iw in self.iw:
            d_in = np.zeros(self.nparams)  # Pulse to Absorber
            d_in[index_input] = self.external_input_coeff[index_input]
            d_out.append(self.matrices_inv[iw].dot(d_in)[index_output])
        d_out = np.array(d_out)
        return d_out
    
    def get_dIdP(self, index_cinput = -1):
        """
        Compute TES current responsivity to a power input on a heat capacity.

        Parameters
        ----------
        index_cinput : int, optional
            Heat-capacity selector. Positive values are 1-based, so ``1``
            selects ``c1_T``. Negative values count from the final
            heat-capacity state, so ``-1`` selects the last ``c*_T``.

        Returns
        -------
        numpy.ndarray
            Complex ``dI/dP`` transfer function on ``self.frequencies``. The
            value is also stored as ``self.dIdP``.
        """
        ind_c = self._heat_capacity_state_index(index_cinput)
        self.dIdP = self.get_solution_single(index_input=ind_c, index_output=self.index_tes_i)
        return self.dIdP
    
    def get_dIdV(self):
        """
        Compute TES current responsivity to external voltage excitation.

        Returns
        -------
        numpy.ndarray
            Complex ``dI/dV`` transfer function on ``self.frequencies``. The
            value is also stored as ``self.dIdV``.
        """
        self.dIdV = self.get_solution_single(index_input=self.index_cload_v, index_output=self.index_tes_i)
        return self.dIdV
        
            
    def get_impedance(self):
        """
        Compute the complex TES impedance from voltage and current response.

        The method excites the external voltage input, solves for the TES
        current response, subtracts the inductive voltage contribution, and
        returns ``dV / dI``.

        Returns
        -------
        numpy.ndarray
            Complex impedance sampled on ``self.frequencies``. The value is
            also stored as ``self.Z_TES``.
        """
        d_Vext = np.zeros(self.nparams)
        d_Vext[0] = 1
        solution = self.get_solution_full(d_Vext, norm = True)
        dI = solution[:, self.index_tes_i]
        dV = solution[:, self.index_cload_v] - self.iw * self.simulation_results["L.L"]
        self.Z_TES = dV/dI
        return self.Z_TES
    

    
    @staticmethod
    def noise_phonon(K,T1,T2,n):
        """
        Phonon noise density, or say thermal fluctuation noise between 2 components. Defined as noise=sqrt( 2*kb*(G1*T1^2 + G2*T2^2) )
        Since G = nKT1^(n-1), nosie = sqrt( 2*kb*n*K*(T1^(n+1) + T2^(n+1)) )

        Parameters
        ----------
        K : float
            Conductance constant in ``P = K * (T1^n - T2^n)``.
        T1, T2 : float
            Temperatures of the two connected components in K.
        n : float
            Thermal conductance exponent.

        Returns
        -------
        float
            Thermal fluctuation noise amplitude in W/sqrt(Hz).
        """
        noise = np.sqrt(2.* scipy.constants.k * n * K * (T1**(n+1) + T2**(n+1)))
        return noise
    
    
    def get_noise(self, 
                    RL_temperature = None, 
                    noise_electronics = 0, 
                    noise_flicker_corner = 1e-6, 
                    noise_flicker_gamma = 1,
                    index_cinput = -1):
        """
        Compute the noise density.
        Parameters
        ----------
        RL_temperature: float
        noise_electronics: float, in A/sqrt(Hz)
            Additional electronic noise, e.g. from the readout electronics
        noise_flicker_corner: float, in Hz
            Corner frequency of the flicker noise, below which the noise increases as 1/f^gamma
        noise_flicker_gamma: float
            Exponent of the flicker noise, below the corner frequency. The noise increases as 1/f^gamma
        index_cinput: int
            Zero-based index of the heat capacity where the input power is applied. If negative, it counts from the end of the list. For example, -1 means the last heat capacity, -2 means the second to last, etc. For example, if the list of parameters is ['CL_v','L_i','c1_T','c2_T','c3_T','c4_T','c5_T','c6_T','c7_T'], then index_cinput = -1 means c17, index_cinput = -2 means c9, index_cinput = 2 means c1, index_cinput = 3 means c2 etc.

        Returns
        -------
        tuple[dict[str, numpy.ndarray], numpy.ndarray]
            Dictionary of current-noise contributions keyed by source name, and
            the frequency grid in Hz.

        Side Effects
        ------------
        Stores intermediate and derived noise arrays on the instance, including
        ``noise_source_vectors``, ``noise_current``, ``noise_power``, and
        ``noise_power_square_sum``. Prints the estimated sigma energy
        resolution in eV.
        """
        # Initialize the noise source vectors
        self.noise_source_vectors = {}
                
        ## 1. Thermal noise (passive + active)
        TES_R0 = self.simulation_results["c1.R"][-1]
        TES_T0 = self.simulation_results["c1.T"][-1]
        TES_beta = self.simulation_results["c1.beta0"][-1]
        BIAS_RL = self.simulation_results["RL.R"][-1]
        BIAS_L = self.simulation_results["L.L"][-1]
        BIAS_T = RL_temperature if RL_temperature is not None else TES_T0
        
        # External Johnson Noise across shunt resistor
        self.noise_source_vectors["External Johnson noise"] = np.zeros(self.nparams)        
        self.noise_source_vectors["External Johnson noise"][0] = np.sqrt(4.*scipy.constants.k * BIAS_T*BIAS_RL)         
        # Internal Johnson Noise, also called TES Johnson Noise
        self.noise_source_vectors["TES Johnson noise"] = np.zeros(self.nparams)
        self.noise_source_vectors["TES Johnson noise"][1] = np.sqrt(4.*scipy.constants.k * TES_T0*TES_R0 * (1+2*TES_beta)) 

        ## 2. Phonon noise
        for i in self.model_conductance_map:
            ## Index of the two ends
            inds = self.model_conductance_map[i]
            K =  self.simulation_results[f"g{i}.K"][-1]
            n =  self.simulation_results[f"g{i}.n"][-1]
            T1 =  self.simulation_results[f"g{i}.port_a.T"][-1]
            T2 =  self.simulation_results[f"g{i}.port_b.T"][-1]
            
            ## Make a noise vector for each phonon noise term, with the noise term in the two ends of the conductance
            TFN = self.noise_phonon(K,T1,T2,n)
            self.noise_source_vectors[f"TFN_{i}"] = np.zeros(self.nparams)
            if inds[0]!=0:
                self.noise_source_vectors[f"TFN_{i}"][inds[0]+1] = TFN
            if inds[1]!=0:
                self.noise_source_vectors[f"TFN_{i}"][inds[1]+1] = -TFN

        ## 3. Readout noise (electronics + flicker noise)
        ##    It is directly given, and does not go into noise_source_vectors
        self.noise_readout = np.ones(len(self.iw)) * noise_electronics
        self.noise_flicker = (self.frequencies[1:] / noise_flicker_corner) ** (-noise_flicker_gamma)* noise_electronics
        self.noise_flicker = np.concatenate([[self.noise_flicker[0]], self.noise_flicker]) 
        self.noise_readout = np.sqrt(self.noise_readout**2 + self.noise_flicker**2)
        

        ## Convert all noise terms into TES current
        self.noise_current = {}
        self.noise_current["Readout noise"] = self.noise_readout
        for key in self.noise_source_vectors:
            self.noise_current[key] = self.get_solution_full(self.noise_source_vectors[key])[:, self.index_tes_i].real

        ## Also convert it into target energy deposition
        dIdP = self.get_dIdP(index_cinput = index_cinput)
        self.noise_power = {key: abs(self.noise_current[key]/dIdP) for key in self.noise_current}
        self.noise_power_square_sum = np.sum(np.square(list(self.noise_power.values())), axis=0)

        
        # Integrate the NEP
        self.noise_power_integral = np.sum(1/self.noise_power_square_sum) * (self.frequencies[1] - self.frequencies[0])  # Approximate the integral using the trapezoidal rule
        # Compute the resolution of our detector
        resolution_sigma = np.sqrt(4.*self.noise_power_integral)**(-1.)
        resolution_sigma_ev = resolution_sigma/scipy.constants.e
        
        print("Resolution (Sigma) in eV = ",resolution_sigma_ev)
        
        # Compute an ideal TES resolution
        # ctot = cg + ca + cau1 + cwb1 + cau2 + csi + cte + cm + cwb2
        # rough_resolution = np.sqrt(4*p['kb']*p['Tc']**2*ctot/p['alpha0']*np.sqrt(p['ntem']/2.)) # In sigma
        # # Convert this to eV
        # rough_resolution_ev = rough_resolution/p['eVtoJ']
        # ideal_resolution = rough_resolution_ev
        # print("Ideal Resolution in eV = ",rough_resolution_ev)

        return self.noise_current, self.frequencies
    
    def get_impulse(self, index_cinput = -1, T=None):
        """
        Compute the impulse response of the linearized system
        ---
        index_cinput: index of the external input
        
        Returns
        ---
        t (ndarray): 1D array of time values.
        y (ndarray): Array of shape (len(t), n) containing the response of all states over time.
        """
        
        ind = self._heat_capacity_state_index(index_cinput)
        self._warn_if_unstable()
        return get_impulse_response(
            A=self.model["A"],
            input_index=ind,
            T=T,
            input_scale=self.external_input_coeff[ind],
        )
        
    def get_impulse2(self, energy, index_input = -1, T=None):
        """
        Linear solver for pulse.
        ---
        Returns
        ---
        t (ndarray): 1D array of time values.
        y (ndarray): Array of shape (len(t), n) containing the response of all states over time.
        """
        
        N = self.model["A"]
        eigenvalues, eigenvectors  = np.linalg.eig(N) # Compute eigenvalues (Eig) and eigenvectors (P) of M
        eigenvectors_inv = np.linalg.inv(eigenvectors ) # Compute inverse of the eigenvectors      
        u = np.zeros(self.nparams)  # Pulse to Absorber
        u[index_input] = energy
        u = u * self.external_input_coeff
        
        A = eigenvectors_inv.dot(u) # Dot the inverse of the eigenvector with the input pulse to get our coefficients
        taus = 1.0/eigenvalues  # get the time constants from the eigenvalues
        print(taus)
        if T is None:
            T = np.linspace(0, max(taus), num = 1000,endpoint=True) # create an array of times to evaluate our solutions at 
              
        exp_vec = list(map(lambda tau,a: a*np.exp(T/tau), taus, A))
        y = eigenvectors.dot(exp_vec).T # create a vector of the solutions
        
        return T, y



class TESMCMCFit:
    """
    Black-box MCMC wrapper for fitting TES Modelica parameters.

    The class evaluates a parameter vector by writing an OpenModelica override
    file, running the compiled model to equilibrium, running a fine transient
    from that equilibrium, and comparing selected observables to measurements.
    """

    def __init__(
        self,
        model_exe,
        build_dir,
        full_model_file,
        base_override_file,
        equilibrium_time=20.0,
        fine_stop_time=0.1,
        coarse_step_size=2e-4,
        fine_step_size=1e-6,
        tolerance=1e-8,
        solver="dassl",
        linearized_model_file="linearized_model.py",
        init_result_file=None,
        pulse_result_file=None,
        tes_config=None,
        tes_model_kwargs=None,
        keep_runs=False,
        extra_coarse_args=None,
        extra_fine_args=None,
    ):
        self.build_dir = Path(build_dir).resolve()
        self.model_exe = Path(model_exe)
        if not self.model_exe.is_absolute():
            self.model_exe = self.build_dir / self.model_exe

        self.model_name = self.model_exe.name
        self.full_model_file = Path(full_model_file).resolve()
        self.base_override_file = Path(base_override_file).resolve()
        self.equilibrium_time = equilibrium_time
        self.fine_stop_time = fine_stop_time
        self.coarse_step_size = coarse_step_size
        self.fine_step_size = fine_step_size
        self.tolerance = tolerance
        self.solver = solver
        self.linearized_model_file = linearized_model_file
        self.init_result_file = init_result_file or f"{self.model_name}_res_init.mat"
        self.pulse_result_file = pulse_result_file or f"{self.model_name}_res_final.mat"
        self.tes_config = {} if tes_config is None else dict(tes_config)
        self.tes_model_kwargs = {} if tes_model_kwargs is None else dict(tes_model_kwargs)
        self.keep_runs = keep_runs
        self.extra_coarse_args = list(extra_coarse_args or [])
        self.extra_fine_args = list(extra_fine_args or [])

        self.parameter_names = []
        self.priors = {}
        self.initial = None
        self.transforms = {}
        self.measurements = {}
        self.last_result = None
        self.last_chi2 = {}
        self.last_error = None

    def set_parameters(self, names, priors, initial=None, transform=None):
        """
        Set fitted parameter names and scipy.stats-style frozen priors.
        """
        self.parameter_names = list(names)
        self.priors = dict(priors)
        self.transforms = {name: "linear" for name in self.parameter_names}
        if transform is not None:
            self.transforms.update(transform)

        missing = [name for name in self.parameter_names if name not in self.priors]
        if missing:
            raise ValueError(f"Missing priors for parameters: {missing}")

        bad_transforms = {
            name: value
            for name, value in self.transforms.items()
            if value not in ("linear", "log")
        }
        if bad_transforms:
            raise ValueError(f"Unsupported transforms: {bad_transforms}")

        if initial is not None:
            self.initial = self._coerce_initial(initial)

        return self

    def set_measurements(self, measurements):
        """
        Set measurement blocks for bias power, impedance, and pulse response.
        """
        self.measurements = dict(measurements)
        return self

    def _coerce_theta(self, theta):
        if isinstance(theta, dict):
            values = [theta[name] for name in self.parameter_names]
        else:
            values = theta
        return np.asarray(values, dtype=float)

    def _coerce_initial(self, initial):
        if not isinstance(initial, dict):
            return self._coerce_theta(initial)

        values = []
        for name in self.parameter_names:
            value = float(initial[name])
            if self.transforms.get(name, "linear") == "log":
                if value <= 0:
                    raise ValueError(f"Initial value for log parameter {name} must be > 0")
                values.append(np.log(value))
            else:
                values.append(value)
        return np.asarray(values, dtype=float)

    def theta_to_params(self, theta):
        theta = self._coerce_theta(theta)
        if len(theta) != len(self.parameter_names):
            raise ValueError(
                f"Expected {len(self.parameter_names)} parameters, got {len(theta)}"
            )

        params = {}
        for name, value in zip(self.parameter_names, theta):
            if self.transforms.get(name, "linear") == "log":
                params[name] = float(np.exp(value))
            else:
                params[name] = float(value)
        return params

    def log_prior(self, theta):
        theta = self._coerce_theta(theta)
        try:
            params = self.theta_to_params(theta)
        except (ValueError, OverflowError):
            return -np.inf

        total = 0.0
        for theta_value, (name, value) in zip(theta, params.items()):
            prior = self.priors[name]
            logp = prior.logpdf(value)
            if not np.isfinite(logp):
                return -np.inf
            total += logp
            if self.transforms.get(name, "linear") == "log":
                total += theta_value
        return float(total)

    def _write_override_file(self, params, run_dir):
        run_dir = Path(run_dir)
        output = run_dir / "mcmc_override.txt"
        seen = set()
        lines = []

        if self.base_override_file.exists():
            for line in self.base_override_file.read_text().splitlines():
                match = re.match(r"^(\s*)([A-Za-z_]\w*)\s*=", line)
                if match and match.group(2) in params:
                    name = match.group(2)
                    lines.append(f"{name}={params[name]:.17g}")
                    seen.add(name)
                else:
                    lines.append(line)

        for name in self.parameter_names:
            if name not in seen:
                lines.append(f"{name}={params[name]:.17g}")

        output.write_text("\n".join(lines) + "\n")
        return output

    def _prepare_run_dir(self):
        run_dir = Path(tempfile.mkdtemp(prefix="tes_mcmc_", dir=self.build_dir))

        required = [
            self.model_exe,
            self.build_dir / f"{self.model_name}_init.xml",
            self.build_dir / f"{self.model_name}_info.json",
            self.build_dir / f"{self.model_name}_JacA.bin",
        ]

        for source in required:
            if source.exists():
                shutil.copy2(source, run_dir / source.name)

        return run_dir

    def _run_subprocess(self, args, run_dir):
        return subprocess.run(
            args,
            cwd=run_dir,
            check=True,
            capture_output=True,
            text=True,
        )

    def run_model(self, params):
        """
        Run coarse equilibrium, linearization, and fine pulse simulation.
        """
        run_dir = self._prepare_run_dir()
        logs = {}

        try:
            override_file = self._write_override_file(params, run_dir)
            exe = f"./{self.model_name}"

            coarse_args = [
                exe,
                f"-overrideFile={override_file.name}",
                "-startTime=0",
                f"-stopTime={self.equilibrium_time}",
                f"-stepSize={self.coarse_step_size}",
                f"-tolerance={self.tolerance}",
                f"-s={self.solver}",
                "-w",
                "-outputFormat=mat",
                f"-r={self.init_result_file}",
                f"-l={self.equilibrium_time}",
            ] + self.extra_coarse_args
            logs["coarse"] = self._run_subprocess(coarse_args, run_dir)

            fine_args = [
                exe,
                f"-r={self.pulse_result_file}",
                f"-overrideFile={override_file.name}",
                f"-s={self.solver}",
                "-w",
                "-startTime=0",
                f"-stopTime={self.fine_stop_time}",
                f"-stepSize={self.fine_step_size}",
                f"-tolerance={self.tolerance}",
                f"-iif={self.init_result_file}",
                f"-iit={self.equilibrium_time}",
                "-lv=-LOG_STDOUT",
            ] + self.extra_fine_args
            logs["fine"] = self._run_subprocess(fine_args, run_dir)

            result = {
                "run_dir": run_dir,
                "override_file": override_file,
                "init_result": run_dir / self.init_result_file,
                "pulse_result": run_dir / self.pulse_result_file,
                "linearized_model": run_dir / self.linearized_model_file,
                "logs": logs,
                "params": dict(params),
            }
            self.last_result = result
            self.last_error = None
            return result

        except Exception as exc:
            self.last_error = exc
            if not self.keep_runs:
                shutil.rmtree(run_dir, ignore_errors=True)
            return None

    @staticmethod
    def _as_array(value):
        return np.asarray(value, dtype=float)

    @staticmethod
    def _sigma_array(value, shape):
        if value is None:
            return np.ones(shape, dtype=float)
        sigma = np.asarray(value, dtype=float)
        if sigma.shape == ():
            return np.ones(shape, dtype=float) * float(sigma)
        return sigma

    def _chi2_bias_power(self, init_data, block):
        model_key = block.get("model_key", "c1.P_Joule")
        model_value = np.asarray(init_data[model_key])[-1]
        sigma = block["sigma"]
        return float(((block["value"] - model_value) / sigma) ** 2)

    def _chi2_pulse(self, pulse_time, pulse_data, block):
        model_key = block.get("model_key", "L.i")
        model_values = self._as_array(pulse_data[model_key])
        if block.get("baseline", "subtract_initial") == "subtract_initial":
            model_values = model_values - model_values[0]

        time = self._as_array(block["time"])
        values = self._as_array(block["values"])
        sigma = self._sigma_array(block.get("sigma"), values.shape)
        model_interp = np.interp(time, pulse_time, model_values)
        residual = (values - model_interp) / sigma
        return float(np.sum(residual ** 2))

    def _chi2_impedance(self, result, init_result, block):
        frequencies = self._as_array(block["frequencies"])
        values = np.asarray(block["values"], dtype=complex)
        model_kwargs = dict(self.tes_model_kwargs)
        if "f_min" not in model_kwargs:
            model_kwargs["f_min"] = float(np.min(frequencies))
        if "f_max" not in model_kwargs:
            model_kwargs["f_max"] = float(np.max(frequencies))
        if "points" not in model_kwargs:
            model_kwargs["points"] = max(200, len(frequencies))

        model = TESModel(
            result["linearized_model"],
            self.full_model_file,
            init_result,
            config=self.tes_config,
            **model_kwargs,
        )

        observable = block.get("observable", "impedance")
        if observable == "impedance":
            model_values = model.get_impedance()
        elif observable == "dIdV":
            model_values = model.get_dIdV()
        else:
            raise ValueError(f"Unsupported impedance observable: {observable}")

        real_interp = np.interp(frequencies, model.frequencies, model_values.real)
        imag_interp = np.interp(frequencies, model.frequencies, model_values.imag)
        sigma_real = self._sigma_array(block.get("sigma_real"), values.real.shape)
        sigma_imag = self._sigma_array(block.get("sigma_imag"), values.imag.shape)
        chi2_real = ((values.real - real_interp) / sigma_real) ** 2
        chi2_imag = ((values.imag - imag_interp) / sigma_imag) ** 2
        return float(np.sum(chi2_real) + np.sum(chi2_imag))

    def log_likelihood(self, theta):
        params = self.theta_to_params(theta)
        result = self.run_model(params)
        if result is None:
            self.last_chi2 = {}
            return -np.inf

        try:
            init_time, init_data = load(result["init_result"])
            pulse_time, pulse_data = load(result["pulse_result"])

            chi2 = {}
            if "bias_power" in self.measurements:
                chi2["bias_power"] = self._chi2_bias_power(
                    init_data,
                    self.measurements["bias_power"],
                )
            if "pulse" in self.measurements:
                chi2["pulse"] = self._chi2_pulse(
                    pulse_time,
                    pulse_data,
                    self.measurements["pulse"],
                )
            if "impedance" in self.measurements:
                chi2["impedance"] = self._chi2_impedance(
                    result,
                    result["init_result"],
                    self.measurements["impedance"],
                )

            self.last_chi2 = chi2
            self.last_error = None
            return float(-0.5 * sum(chi2.values()))

        except Exception as exc:
            self.last_error = exc
            self.last_chi2 = {}
            return -np.inf

        finally:
            if not self.keep_runs:
                shutil.rmtree(result["run_dir"], ignore_errors=True)

    def log_probability(self, theta):
        logp = self.log_prior(theta)
        if not np.isfinite(logp):
            return -np.inf

        logl = self.log_likelihood(theta)
        if not np.isfinite(logl):
            return -np.inf

        return float(logp + logl)

    def initial_walkers(self, nwalkers, initial=None, scatter=1e-3):
        if initial is None:
            if self.initial is None:
                raise ValueError("Provide initial or call set_parameters(..., initial=...)")
            center = self.initial
        else:
            center = self._coerce_initial(initial)

        center = np.asarray(center, dtype=float)
        ndim = len(center)
        scale = np.where(center != 0, np.abs(center) * scatter, scatter)
        return center + scale * np.random.randn(nwalkers, ndim)

    def run_mcmc(
        self,
        nwalkers,
        nsteps,
        initial=None,
        scatter=1e-3,
        progress=True,
        **sampler_kwargs,
    ):
        try:
            import emcee
        except ImportError as exc:
            raise ImportError("Install emcee with: pip install emcee") from exc

        initial_state = self.initial_walkers(nwalkers, initial=initial, scatter=scatter)
        sampler = emcee.EnsembleSampler(
            nwalkers,
            len(self.parameter_names),
            self.log_probability,
            **sampler_kwargs,
        )
        sampler.run_mcmc(initial_state, nsteps, progress=progress)
        return sampler


def load(filename):
    """
    # File format
    # https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/technical_details.html

    Load an OpenModelica MATLAB ``.mat`` result file.

    The loader decodes the OpenModelica ``name`` matrix and ``dataInfo`` table,
    applies negated aliases, and returns every readable variable as a NumPy
    array. Variables stored in ``data_1`` are typically parameters and
    constants; variables stored in ``data_2`` are time-series results.

    Parameters
    ----------
    filename : str or pathlib.Path
        Path to the OpenModelica result file.

    Returns
    -------
    tuple[numpy.ndarray, dict[str, numpy.ndarray]]
        Time array and a dictionary mapping Modelica variable names to values.
    """
    mat = loadmat(filename, chars_as_strings=False)

    name_matrix = mat["name"]
    data_info = mat["dataInfo"]

    def decode_strings(char_matrix, n_variables):
        """
        Decode OpenModelica character matrix.

        Handles scipy returning either:
          - Unicode/string characters
          - integer character codes

        Also handles either matrix orientation.

        Parameters
        ----------
        char_matrix : numpy.ndarray
            Character matrix from the OpenModelica ``name`` field.
        n_variables : int
            Number of variable names expected from ``dataInfo``.

        Returns
        -------
        list[str]
            Decoded variable names.

        Raises
        ------
        ValueError
            If the matrix orientation cannot be matched to ``n_variables``.
        """

        # Determine which axis represents variables
        if char_matrix.shape[1] == n_variables:
            columns_are_variables = True
        elif char_matrix.shape[0] == n_variables:
            columns_are_variables = False
        else:
            raise ValueError(
                f"Cannot determine name matrix orientation.\n"
                f"name shape: {char_matrix.shape}\n"
                f"number of variables: {n_variables}"
            )

        names = []

        for i in range(n_variables):
            chars = (
                char_matrix[:, i]
                if columns_are_variables
                else char_matrix[i, :]
            )

            chars = np.asarray(chars).ravel()

            if chars.dtype.kind in ("U", "S"):
                # scipy already decoded characters
                parts = []

                for c in chars:
                    if isinstance(c, bytes):
                        c = c.decode("utf-8", errors="ignore")
                    else:
                        c = str(c)

                    if c != "\x00":
                        parts.append(c)

                name = "".join(parts).rstrip()

            else:
                # Numeric character codes
                name = "".join(
                    chr(int(c))
                    for c in chars
                    if int(c) != 0
                ).rstrip()

            names.append(name)

        return names

    n_variables = data_info.shape[1]
    names = decode_strings(name_matrix, n_variables)

    data_1 = mat.get("data_1")
    data_2 = mat.get("data_2")

    variables = {}

    for i, name in enumerate(names):

        data_set = int(data_info[0, i])
        index = int(data_info[1, i])

        # Negative index indicates a negated alias
        sign = -1.0 if index < 0 else 1.0

        # MATLAB indices start at 1
        row = abs(index) - 1

        if data_set == 1 and data_1 is not None:
            values = sign * data_1[row, :]

        elif data_set == 2 and data_2 is not None:
            values = sign * data_2[row, :]

        else:
            continue

        variables[name] = np.asarray(values).squeeze()

    time = np.asarray(data_2[0, :]).squeeze()

    return time, variables

# --------------------------------------------------------
# Parse modelica model

_CONNECT_RE = re.compile(r"\bconnect\s*\(\s*([^,]+?)\s*,\s*([^)]+?)\s*\)", re.DOTALL)
_COMPONENT_RE = re.compile(
    r"\b(?P<type>(?:[\w]+\.)*(?:ThermlConductanceN|HeatCapacitorPoly|TES2|FixedTemperature))\s+"
    r"(?P<name>[A-Za-z_]\w*)\b"
)


class _UnionFind:
    """
    Minimal disjoint-set data structure for grouping connected Modelica ports.

    The connection parser treats every connector name as an item in an
    undirected graph. A union operation joins two connectors from one
    ``connect(a, b)`` statement, and ``find`` returns the representative for
    the connected component that contains a connector.

    Attributes
    ----------
    parent : dict
        Mapping from each seen item to its parent item. Root items point to
        themselves.
    """

    def __init__(self):
        """
        Create an empty union-find container.

        Items are inserted lazily the first time they are passed to ``find`` or
        ``union``.
        """
        self.parent = {}

    def find(self, item):
        """
        Return the representative element for ``item``.

        Parameters
        ----------
        item : hashable
            Connector or node identifier to look up.

        Returns
        -------
        hashable
            Canonical representative for the connected component containing
            ``item``.
        """
        if item not in self.parent:
            self.parent[item] = item
            return item

        root = item
        while self.parent[root] != root:
            root = self.parent[root]

        while self.parent[item] != item:
            item, self.parent[item] = self.parent[item], root

        return root

    def union(self, left, right):
        """
        Join the connected components containing ``left`` and ``right``.

        Parameters
        ----------
        left, right : hashable
            Items that should be treated as connected.
        """
        left_root = self.find(left)
        right_root = self.find(right)

        if left_root != right_root:
            self.parent[right_root] = left_root


def _strip_modelica_comments(text):
    """
    Remove Modelica block and line comments from source text.

    Parameters
    ----------
    text : str
        Raw Modelica source text.

    Returns
    -------
    str
        Source text with ``/* ... */`` block comments and ``//`` line comments
        removed.
    """
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return re.sub(r"//.*", "", text)


def _connector_name(connector):
    """
    Normalize a connector expression for graph matching.

    Parameters
    ----------
    connector : str
        Connector text captured from a Modelica ``connect`` statement.

    Returns
    -------
    str
        Connector name with all whitespace removed.
    """
    return re.sub(r"\s+", "", connector)


def _parse_indexed_name(name, prefix):
    """
    Parse a repository-style indexed component name.

    Parameters
    ----------
    name : str
        Component name such as ``c1`` or ``g14``.
    prefix : str
        Required prefix, for example ``"c"`` for heat capacities or ``"g"``
        for conductance links.

    Returns
    -------
    int or None
        Positive 1-based index if ``name`` matches ``prefix`` followed by an
        integer with no leading zero, otherwise ``None``.
    """
    match = re.fullmatch(rf"{re.escape(prefix)}([1-9]\d*)", name)
    return int(match.group(1)) if match else None


def parse_thermal_conductance_connections(modelica_file):
    """
    Parse a Modelica model and return heat-capacity endpoints for each g*.

    The parser expects the repository naming convention:
      - nonlinear thermal conductances are named g1, g2, ...
      - heat capacities are named c1, c2, ...

    Each returned value is a tuple of HeatCapacitorPoly/TES2 indices connected
    to (port_a, port_b). Connections to fixedTemperature.port are reported as
    index 0.

    Parameters
    ----------
    modelica_file : str or pathlib.Path
        Path to the full Modelica model file whose component declarations and
        ``connect`` equations should be inspected.

    Returns
    -------
    dict[int, tuple[int, int]]
        Mapping from conductance index to the heat-capacity or bath endpoints
        connected to that conductance. For example, ``{3: (1, 4)}`` means
        ``g3.port_a`` is connected to ``c1`` and ``g3.port_b`` is connected to
        ``c4``. Endpoint ``0`` means a ``FixedTemperature.port`` bath.

    Raises
    ------
    ValueError
        If a conductance port cannot be resolved to a single heat capacity or
        fixed-temperature endpoint.
    """

    text = Path(modelica_file).read_text()
    text = _strip_modelica_comments(text)

    conductances = {}
    capacities = {}
    fixed_temperatures = set()

    for match in _COMPONENT_RE.finditer(text):
        component_type = match.group("type").split(".")[-1]
        name = match.group("name")

        if component_type == "ThermlConductanceN":
            index = _parse_indexed_name(name, "g")
            if index is not None:
                conductances[name] = index

        elif component_type in ("HeatCapacitorPoly", "TES2"):
            index = _parse_indexed_name(name, "c")
            if index is not None:
                capacities[name] = index

        elif component_type == "FixedTemperature":
            fixed_temperatures.add(name)

    uf = _UnionFind()

    for left, right in _CONNECT_RE.findall(text):
        uf.union(_connector_name(left), _connector_name(right))

    node_endpoints = {}

    for capacity_name, index in capacities.items():
        for port in ("port", "heatPort"):
            connector = f"{capacity_name}.{port}"
            root = uf.find(connector)
            node_endpoints.setdefault(root, set()).add(index)

    for fixed_name in fixed_temperatures:
        connector = f"{fixed_name}.port"
        root = uf.find(connector)
        node_endpoints.setdefault(root, set()).add(0)

    def resolve_endpoint(conductance_name, port):
        """
        Resolve one conductance port to a capacity index or bath sentinel.

        Parameters
        ----------
        conductance_name : str
            Component name such as ``g1``.
        port : {"port_a", "port_b"}
            Conductance connector to resolve.

        Returns
        -------
        int
            Heat-capacity/TES index, or ``0`` for a fixed-temperature bath.

        Raises
        ------
        ValueError
            If the conductance port has no known endpoint or is connected to
            more than one endpoint.
        """
        connector = f"{conductance_name}.{port}"
        root = uf.find(connector)
        endpoints = node_endpoints.get(root, set())

        if not endpoints:
            raise ValueError(
                f"Cannot resolve {connector} to a c* port or fixedTemperature.port"
            )

        if len(endpoints) > 1:
            endpoint_list = ", ".join(str(endpoint) for endpoint in sorted(endpoints))
            raise ValueError(f"Ambiguous endpoints for {connector}: {endpoint_list}")

        return next(iter(endpoints))

    return {
        index: (
            resolve_endpoint(conductance_name, "port_a"),
            resolve_endpoint(conductance_name, "port_b"),
        )
        for conductance_name, index in sorted(
            conductances.items(), key=lambda item: item[1]
        )
    }

# --------------------------------------------------------
# Load linearized python model

def _load_linearized_model(linearized_model):
    """
    Return the tuple produced by an OpenModelica linearized_model() function.

    linearized_model may be the tuple itself, a callable, an imported module, or
    a path to a Python file containing linearized_model().

    Parameters
    ----------
    linearized_model : tuple, callable, module, str, or pathlib.Path
        OpenModelica linearization result, or an object that can produce one.
        Python file paths are imported dynamically and must define a
        ``linearized_model()`` function.

    Returns
    -------
    tuple
        Raw OpenModelica tuple containing dimensions, operating points,
        state-space matrices, and variable names.

    Raises
    ------
    ValueError
        If a file path cannot be imported or does not define
        ``linearized_model()``.
    TypeError
        If ``linearized_model`` is not one of the supported input forms.
    """

    if isinstance(linearized_model, tuple):
        return linearized_model

    if callable(linearized_model):
        return linearized_model()

    if hasattr(linearized_model, "linearized_model"):
        return linearized_model.linearized_model()

    if isinstance(linearized_model, (str, Path)):
        path = Path(linearized_model)
        spec = importlib.util.spec_from_file_location(path.stem, path)
        if spec is None or spec.loader is None:
            raise ValueError(f"Cannot import linearized model from {path}")

        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        if not hasattr(module, "linearized_model"):
            raise ValueError(f"{path} does not define linearized_model()")

        return module.linearized_model()

    raise TypeError(
        "linearized_model must be a tuple, callable, module, or Python file path"
    )


def _linearized_state_permutation(state_vars):
    """
    Build the canonical state ordering for TES linearized models.

    OpenModelica may emit heat-capacity states lexicographically, for example
    ``c10_T`` before ``c2_T``. This helper validates the state names and returns
    a permutation that orders states as ``CL_v``, ``L_i``, then ``c1_T``,
    ``c2_T``, ... by numeric heat-capacity index.

    Parameters
    ----------
    state_vars : sequence of str
        State variable names from the generated linearized model.

    Returns
    -------
    tuple[list[int], list[str]]
        Index permutation into the original state order and the corresponding
        sorted state-name list.

    Raises
    ------
    ValueError
        If state names are duplicated, required electrical states are missing,
        unknown state names are present, or duplicate ``c*_T`` indices are
        found.
    """
    state_vars = list(state_vars)
    state_positions = {name: i for i, name in enumerate(state_vars)}

    if len(state_positions) != len(state_vars):
        duplicates = sorted(
            {name for name in state_vars if state_vars.count(name) > 1}
        )
        raise ValueError(f"Duplicate state variable names: {duplicates}")

    required_states = ("CL_v", "L_i")
    missing_states = [
        name for name in required_states
        if name not in state_positions
    ]

    if missing_states:
        raise ValueError(f"Missing required state variables: {missing_states}")

    c_states = []
    unknown_states = []

    for name in state_vars:
        if name in required_states:
            continue

        match = re.fullmatch(r"c([1-9]\d*)_T", name)
        if match is None:
            unknown_states.append(name)
        else:
            c_states.append((int(match.group(1)), name))

    if unknown_states:
        raise ValueError(f"Unknown state variable names: {unknown_states}")

    c_indices = [index for index, _ in c_states]
    duplicate_indices = sorted(
        {index for index in c_indices if c_indices.count(index) > 1}
    )

    if duplicate_indices:
        raise ValueError(f"Duplicate c*_T state indices: {duplicate_indices}")

    sorted_state_vars = list(required_states) + [
        name for _, name in sorted(c_states)
    ]

    return [state_positions[name] for name in sorted_state_vars], sorted_state_vars


def _identity_permutation(variable_names, expected_count, axis_name):
    """
    Validate an axis variable list and return its identity permutation.

    Parameters
    ----------
    variable_names : sequence of str
        Input or output variable names from the generated linearized model.
    expected_count : int
        Expected number of names for this axis.
    axis_name : str
        Label used in error messages, for example ``"input"`` or ``"output"``.

    Returns
    -------
    tuple[list[int], list[str]]
        Identity permutation and the validated variable-name list.

    Raises
    ------
    ValueError
        If the number of names does not match ``expected_count``.
    """
    variable_names = list(variable_names)

    if len(variable_names) != expected_count:
        raise ValueError(
            f"Expected {expected_count} {axis_name} variables, "
            f"got {len(variable_names)}"
        )

    return list(range(expected_count)), variable_names


def load_linearized_model(linearized_model):
    """
    Normalize an OpenModelica Python linearized_model() result.

    Returns a dictionary with NumPy arrays for x0, u0, A, B, C, and D plus the
    state, input, and output variable name lists.

    The state order is normalized to the repository convention ``CL_v``,
    ``L_i``, then heat-capacity temperatures ``c1_T``, ``c2_T``, ... . Input
    and output variable lists are validated against the dimensions reported by
    OpenModelica, but their order is otherwise preserved.

    Parameters
    ----------
    linearized_model : tuple, callable, module, str, or pathlib.Path
        Raw linearization tuple, a callable returning that tuple, an imported
        module exposing ``linearized_model()``, or a generated Python file path.

    Returns
    -------
    dict
        Dictionary with integer dimensions ``n``, ``m``, ``p``; arrays ``x0``,
        ``u0``, ``A``, ``B``, ``C``, and ``D``; and variable-name lists
        ``stateVars``, ``inputVars``, and ``outputVars``.

    Raises
    ------
    ValueError
        If the generated names do not match the TES naming convention or array
        dimensions.
    TypeError
        If ``linearized_model`` cannot be loaded by ``_load_linearized_model``.
    """

    (
        n,
        m,
        p,
        x0,
        u0,
        A,
        B,
        C,
        D,
        state_vars,
        input_vars,
        output_vars,
    ) = _load_linearized_model(linearized_model)

    A = np.asarray(A, dtype=float).reshape((n, n))
    x0 = np.asarray(x0, dtype=float).reshape((n,))
    u0 = np.asarray(u0, dtype=float).reshape((m,)) if m else np.empty((0,))

    B = np.asarray(B, dtype=float).reshape((n, m)) if m else np.empty((n, 0))
    C = np.asarray(C, dtype=float).reshape((p, n)) if p else np.empty((0, n))
    D = np.asarray(D, dtype=float).reshape((p, m)) if p and m else np.empty((p, m))

    state_permutation, state_vars = _linearized_state_permutation(state_vars)
    input_permutation, input_vars = _identity_permutation(input_vars, m, "input")
    output_permutation, output_vars = _identity_permutation(output_vars, p, "output")

    x0 = x0[state_permutation]
    u0 = u0[input_permutation]
    A = A[np.ix_(state_permutation, state_permutation)]
    B = B[np.ix_(state_permutation, input_permutation)]
    C = C[np.ix_(output_permutation, state_permutation)]
    D = D[np.ix_(output_permutation, input_permutation)]

    return {
        "n": n,
        "m": m,
        "p": p,
        "x0": x0,
        "u0": u0,
        "A": A,
        "B": B,
        "C": C,
        "D": D,
        "stateVars": list(state_vars),
        "inputVars": list(input_vars),
        "outputVars": list(output_vars),
    }


## Modify SVGs with simulation result

def mod_svg(filename, output_filename, data, system_name="System_LMO", width=900, display=True):
    """
    Write an SVG diagram with simulated LMO values substituted into labels.

    For ``system_name == "System_LMO"``, placeholder labels such as ``K=K1``
    and ``m=m1`` are replaced with the final conductance ``g*.G``, heat
    capacity ``c*.C``, and TES temperature values from a simulation result
    dictionary. The original SVG is read from ``filename`` and the modified SVG
    is written to ``output_filename``.

    Parameters
    ----------
    filename : str or pathlib.Path
        Source SVG file.
    output_filename : str or pathlib.Path
        Destination SVG file to write.
    data : dict[str, array-like]
        Simulation variables, usually the second return value from ``load``.
    system_name : str, optional
        System-specific replacement rule set. Currently only ``"System_LMO"``
        has replacement rules.
    width : int, optional
        Display width in pixels for the returned notebook HTML.
    display : bool, optional
        If true, return an ``IPython.display.HTML`` image tag for notebook
        display. If false, only write the output file.

    Returns
    -------
    IPython.display.HTML or None
        Notebook display object when ``display`` is true, otherwise ``None``.
    """
    with open(filename, 'r') as file:
        content = file.read()

    # Replace the target text
    # updated_content = content.replace(search_text, replace_text)
    
    ## Define for each system name the corresponding replacement rules
    if system_name == "System_LMO":
        for i in range(1, 14+1):
            search_text = f">K=K{i} <"
            replace_text = f">G={data[f'g{i}.G'][-1]:.3g} <"
            content = content.replace(search_text, replace_text)
        
        for i in range(1, 10+1):
            search_text = f">m=m{i} <"
            replace_text = f">C={data[f'c{i}.C'][-1]:.3g} <"
            content = content.replace(search_text, replace_text)
            
        search_text = f">  m=TES_m <"
        replace_text = f">  C={data[f'c1.C'][-1]:.3g} <"
        content = content.replace(search_text, replace_text)
        
        search_text = f">  Tc=TES_Tc <"
        replace_text = f">  T={data[f'c1.T'][-1]:.3g} <"
        content = content.replace(search_text, replace_text)
        
        

    # Open the file in write mode to overwrite it
    with open(output_filename, "w") as file:
        file.write(content)
        

    if display:
        from IPython.display import HTML
        import time

        return HTML(
            f'<img src="{output_filename}?t={time.time()}" '
            f'width="{width}" '
            'style="background-color: #ffffff; padding: 16px; border-radius: 8px;">'
        )
