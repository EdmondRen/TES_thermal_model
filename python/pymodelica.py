import importlib.util
import re
import shutil
import subprocess
import tempfile
import warnings
import xml.etree.ElementTree as ET
from pathlib import Path

import numpy as np
import scipy
from scipy.io import loadmat
import matplotlib.pyplot as plt



if np.lib.NumpyVersion(np.__version__) < "2.4.0":
    trapz = np.trapz
else:
    trapz = np.trapezoid
    
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

    def __init__(self, 
                 linearized_model_filename, 
                 full_model_filename, 
                 simulation_results_filename, 
                 config, 
                 f_min = 1, f_max = 100e3,
                 f_scale = "linear",
                 points = 1000, 
                 frequencies : np.ndarray | None = None):
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
        f_scale: string
            "linear" or "log", default is linear
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
            if f_scale == "linear":
                self.frequencies = np.linspace((f_min), (f_max), points)
            elif f_scale == "log":
                self.frequencies = np.logspace(np.log10(f_min), np.log10(f_max), points)
            self.f_scale = f_scale
                
        else:
            self.frequencies = frequencies
            self.f_scale = None
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
        Compute the complex impedance of entire TES circuit (Z_tes + iwL + Rp).

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
        Compute the TES impedance, excluding circuit components 

        Returns
        -------
        numpy.ndarray
            Complex impedance sampled on ``self.frequencies``. The value is
            also stored as ``self.Z_TES``.
        """
        dIdV = self.get_dIdV()
        dVdI = 1/dIdV
        self.Z_TES = dVdI - self.iw * self.simulation_results["L.L"][-1] - self.simulation_results["Rp.R"][-1]
        return self.Z_TES


    def get_alpha_beta(self, T=None, I=None):
        """Calculate local TES2 logarithmic resistance derivatives.

        The derivatives are evaluated from the exact resistance equation used
        by ``libTES.TES2`` rather than from the calibration parameters alone:

        ``alpha = (T / R) * dR/dT`` and
        ``beta = (I / R) * dR/dI``.

        Args:
            T: TES temperature in kelvin. If omitted, use the final
                ``c1.T`` value from the simulation results.
            I: TES current in amperes. If omitted, use the final ``c1.i``
                value from the simulation results.

        Returns:
            A tuple ``(alpha, beta)``. Scalar inputs produce scalar floats;
            array-like inputs are broadcast and produce NumPy arrays.

        Raises:
            KeyError: If a required TES2 parameter or default state result is
                missing.
            ValueError: If inputs or TES2 parameters are non-finite, or if
                the resistance equation contains a singular parameter.
        """
        def last_result_value(key):
            if key not in self.simulation_results:
                raise KeyError(f"Missing TES2 simulation result: {key}")
            values = np.asarray(self.simulation_results[key])
            if values.size == 0:
                raise ValueError(f"TES2 simulation result is empty: {key}")
            return values.flat[-1]

        T_value = last_result_value("c1.T") if T is None else T
        I_value = last_result_value("c1.i") if I is None else I
        parameter_names = ("Tc", "I0", "alpha0", "beta0", "p0")
        parameters = {
            name: float(last_result_value(f"c1.{name}"))
            for name in parameter_names
        }

        T_value, I_value = np.broadcast_arrays(
            np.asarray(T_value, dtype=float),
            np.asarray(I_value, dtype=float),
        )
        if not np.all(np.isfinite(T_value)) or not np.all(np.isfinite(I_value)):
            raise ValueError("T and I must contain only finite values")
        if not all(np.isfinite(value) for value in parameters.values()):
            raise ValueError("TES2 parameters must contain only finite values")

        Tc = parameters["Tc"]
        I0 = parameters["I0"]
        alpha0 = parameters["alpha0"]
        beta0 = parameters["beta0"]
        p0 = parameters["p0"]
        denominator = p0 * alpha0 + beta0
        if Tc == 0 or I0 <= 0 or alpha0 == 0 or p0 <= 0 or denominator == 0:
            raise ValueError(
                "TES2 parameters must satisfy Tc != 0, I0 > 0, alpha0 != 0, "
                "p0 > 0, and p0 + alpha0 + beta0 != 0"
            )

        current_power = (np.abs(I_value) / I0) ** p0
        resistance_argument = alpha0 / Tc * (
            T_value
            - Tc
            * (1 + beta0 / alpha0 / p0)
            * (1 - current_power * beta0 / denominator)
        )
        transition_factor = 1 - np.tanh(resistance_argument)

        alpha = T_value * alpha0 / Tc * transition_factor
        beta = (
            alpha0
            / Tc
            * Tc
            * (1 + beta0 / alpha0 / p0)
            * p0
            * beta0
            / denominator
            * current_power
            * transition_factor
        )

        if alpha.ndim == 0:
            return float(alpha), float(beta)
        return alpha, beta


    
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
                    Rsh_temperature = None, 
                    Rp_temperature = None, 
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
                
        ## 1. Johnson (Thermal) noise (passive + active)
        T_bath = self.simulation_results["fixedTemperature.T"][-1]
        TES_R0 = self.simulation_results["c1.R"][-1]
        TES_T0 = self.simulation_results["c1.T"][-1]
        TES_I = self.simulation_results["c1.i"][-1]
        TES_beta = self.simulation_results["c1.beta0"][-1]
        BIAS_RL = self.simulation_results["RL.R"][-1]
        BIAS_Rp = self.simulation_results["Rp.R"][-1]
        BIAS_L = self.simulation_results["L.L"][-1]
        BIAS_Rsh_T = Rsh_temperature if Rsh_temperature is not None else T_bath
        BIAS_Rp_T = Rp_temperature if Rp_temperature is not None else T_bath
        
        # External Johnson Noise (PJN, passive Johnson noise) across shunt resistor
        self.noise_source_vectors["PJN"] = np.zeros(self.nparams)        
        self.noise_source_vectors["PJN"][0] = np.sqrt(4.*scipy.constants.k * (BIAS_Rsh_T*BIAS_RL))
        self.noise_source_vectors["PJN"][1] = np.sqrt(4.*scipy.constants.k * (BIAS_Rp_T*BIAS_Rp))
        
        # Internal Johnson Noise, also called TES Johnson Noise (TJN)
        self.noise_source_vectors["TJN"] = np.zeros(self.nparams)
        vn2 = 4.*scipy.constants.k * TES_T0*TES_R0 * (1+2*TES_beta)
        self.noise_source_vectors["TJN"][1] = np.sqrt(vn2) 
        self.noise_source_vectors["TJN"][2] = -np.sqrt(vn2)*TES_I

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
        self.noise_current["Readout"] = self.noise_readout
        for key in self.noise_source_vectors:
            self.noise_current[key] = np.abs(self.get_solution_full(self.noise_source_vectors[key])[:, self.index_tes_i])
        
        ## Get sum of all noise, and sum of TFN
        self.noise_current_total = np.sqrt(np.sum(np.square(list(self.noise_current.values())), axis=0))
        self.noise_current_totaltfn = np.sqrt(np.sum(np.square([self.noise_current[key] for key in self.noise_current if "TFN" in key]), axis=0))

        
        # print("Resolution (Sigma) in eV = ", self.resolution_sigma_ev)
        
        # Compute an ideal TES resolution
        # ctot = cg + ca + cau1 + cwb1 + cau2 + csi + cte + cm + cwb2
        # rough_resolution = np.sqrt(4*p['kb']*p['Tc']**2*ctot/p['alpha0']*np.sqrt(p['ntem']/2.)) # In sigma
        # # Convert this to eV
        # rough_resolution_ev = rough_resolution/p['eVtoJ']
        # ideal_resolution = rough_resolution_ev
        # print("Ideal Resolution in eV = ",rough_resolution_ev)

        return self.frequencies, self.noise_current
    
    def get_resolution(self, dIdP = None, index_cinput = -1, fmin = None, fmax = None, n_interp=None):
        if not hasattr(self, "noise_current_total"):
            raise ValueError("Run get_noise() first!")
        
        dIdP = self.get_dIdP(index_cinput = index_cinput) if dIdP is None else dIdP
        self.noise_power = {key: abs(self.noise_current[key]/dIdP) for key in self.noise_current}
        self.noise_power_square_sum = np.sum(np.square(list(self.noise_power.values())), axis=0)

        # Integration limits
        f_low = self.frequencies[0] if fmin is None else fmin
        f_high = self.frequencies[-1] if fmax is None else fmax

        if f_low < self.frequencies[0]:
            raise ValueError(
                f"fmin={f_low} is below the minimum available frequency "
                f"{self.frequencies[0]}"
            )

        if f_high > self.frequencies[-1]:
            raise ValueError(
                f"fmax={f_high} is above the maximum available frequency "
                f"{self.frequencies[-1]}"
            )
        if f_low >= f_high:
            raise ValueError("fmin must be smaller than fmax.")            

        # Interpolate integrand onto fine grid
        if n_interp is None:
            if self.f_scale is None:
                n_interp = len(self.frequencies)
            else:
                n_interp = len(self.frequencies)*10
        frequencies_interp = np.linspace(f_low, f_high, n_interp)
        integrand = 1 / self.noise_power_square_sum
        integrand_interp = np.interp(
            frequencies_interp,
            self.frequencies,
            integrand,
        )
        
        # Integrate the NEP
        self.noise_power_integral = trapz(
            integrand_interp,
            frequencies_interp,
        )        
        # Compute the resolution of our detector
        self.resolution_sigma = 1/np.sqrt(4.*self.noise_power_integral)
        self.resolution_sigma_ev = self.resolution_sigma/scipy.constants.e
        
        return self.resolution_sigma_ev
    
    def get_resolution_split(self, 
                            index_cinput1 = 2, 
                            index_cinput2 = 2, 
                            fraction_1 = 0.5,
                            fmin = None, fmax = None):
        """
        Calcuate resolution when splitting the input energy in two heat capacities.
        """    
        
        dIdP_1 = self.get_dIdP(index_cinput = index_cinput1)
        dIdP_2 = self.get_dIdP(index_cinput = index_cinput2)
        self.dIdP_combined = dIdP_1*fraction_1 + dIdP_2 * (1-fraction_1)
        self.resolution_combined_sigma_ev = self.get_resolution(dIdP = self.dIdP_combined, fmin = fmin, fmax = fmax)
        return self.resolution_combined_sigma_ev
    
    def get_impulse(self, index = -1, index_cinput = -1, T=None):
        """
        Compute the impulse response of the linearized system with unit Energy/Voltage input.
        ---
        index_cinput: index of the external input
        
        Returns
        ---
        t (ndarray): 1D array of time values.
        y (ndarray): Array of shape (len(t), n) containing the response of all states over time.
        """
        
        if index < 0:
            ind = self._heat_capacity_state_index(index_cinput)
        else:
            ind = index
        self._warn_if_unstable()
        t,y = get_impulse_response(
            A=self.model["A"],
            input_index=ind,
            T=T,
            input_scale=self.external_input_coeff[ind],
        )
        
        # Normalize the input to the energy of the input
        # y = y / self.external_input_coeff[ind]
        return t, y

    def get_linear_phonon_energy_collection_efficiency(
        self,
        time,
        impulse_response,
        deposited_energy,
        voltage_key="c1.v",
        current_key="c1.i",
    ):
        """Calculate Joule-energy collection from a linear impulse response.

        The linearized TES Joule-power perturbation is evaluated to first
        order as ``V0 * delta_I + I0 * delta_V``. The supplied state response
        must already be scaled to the deposited energy. The TES-voltage
        integral is reconstructed from the load-capacitor voltage using the
        series parasitic resistance and inductor voltage drops.

        Args:
            time: Strictly increasing impulse-response samples in seconds.
            impulse_response: Energy-scaled state perturbations with shape
                ``(len(time), nparams)``, such as a scaled result from
                :meth:`get_impulse` or :meth:`get_impulse_split`.
            deposited_energy: Energy represented by ``impulse_response``, in
                joules.
            voltage_key: Simulation-result key containing the operating-point
                TES voltage.
            current_key: Simulation-result key containing the operating-point
                TES current.

        Returns:
            A dictionary containing ``deposited_energy``, ``joule_energy``,
            ``collected_energy``, ``efficiency``, and ``integration_time``.

        Raises:
            KeyError: If a required operating-point result is missing.
            ValueError: If the energy, response arrays, operating point, or
                circuit parameters are invalid.
        """
        if not np.isfinite(deposited_energy) or deposited_energy <= 0:
            raise ValueError("deposited_energy must be positive")
        if voltage_key not in self.simulation_results:
            raise KeyError(f"Missing operating-point voltage result: {voltage_key}")
        if current_key not in self.simulation_results:
            raise KeyError(f"Missing operating-point current result: {current_key}")
        if "L.L" not in self.simulation_results:
            raise KeyError("Missing circuit inductance result: L.L")

        time = np.asarray(time, dtype=float)
        impulse_response = np.asarray(impulse_response, dtype=float)
        if time.ndim != 1:
            raise ValueError("time must be one-dimensional")
        if len(time) < 2 or np.any(np.diff(time) <= 0):
            raise ValueError(
                "time must contain at least two strictly increasing samples"
            )
        expected_shape = (len(time), self.nparams)
        if impulse_response.shape != expected_shape:
            raise ValueError(
                "impulse_response must have shape "
                f"{expected_shape}, got {impulse_response.shape}"
            )
        if not np.all(np.isfinite(time)) or not np.all(
            np.isfinite(impulse_response)
        ):
            raise ValueError("time and impulse_response must contain finite values")

        voltage_0 = float(self.simulation_results[voltage_key][-1])
        current_0 = float(self.simulation_results[current_key][-1])
        inductance = float(self.simulation_results["L.L"][-1])
        series_resistance = 0.0
        if "Rp.R" in self.simulation_results:
            series_resistance = float(self.simulation_results["Rp.R"][-1])
        if not np.isfinite(
            [voltage_0, current_0, inductance, series_resistance]
        ).all():
            raise ValueError(
                "Operating-point values and circuit parameters must be finite"
            )

        delta_load_voltage = impulse_response[:, self.index_cload_v]
        delta_current = impulse_response[:, self.index_tes_i]
        integrated_current = float(trapz(delta_current, time))
        integrated_tes_voltage = float(
            trapz(delta_load_voltage, time)
            - series_resistance * integrated_current
            - inductance * (delta_current[-1] - delta_current[0])
        )
        joule_energy = float(
            voltage_0 * integrated_current
            + current_0 * integrated_tes_voltage
        )
        collected_energy = float(-joule_energy)
        return {
            "deposited_energy": float(deposited_energy),
            "joule_energy": joule_energy,
            "collected_energy": collected_energy,
            "efficiency": collected_energy / deposited_energy,
            "integration_time": float(time[-1] - time[0]),
        }

    def get_nonlinear_energy_template(
        self,
        time,
        deposited_energy,
        simulation_result=None,
        current=None,
        current_key="c1.i",
        baseline_current=None,
        baseline_samples=10,
    ):
        """Convert a nonlinear current pulse into an energy template.

        This computes the one-sided continuous-time Fourier transform of the
        baseline-subtracted current pulse, normalized by the deposited energy.
        The result is a finite-energy secant response rather than a local
        derivative of the nonlinear model. Its units are A/W, matching the
        frequency-domain ``dI/dP`` used by :meth:`get_resolution`.

        OpenModelica result files can repeat timestamps at events. Repeated
        timestamps are collapsed by retaining their final sample, after which
        the current is interpolated onto a uniform grid for the FFT.

        Args:
            time: Nondecreasing simulation timestamps in seconds.
            deposited_energy: Energy represented by the current pulse, in
                joules.
            simulation_result: Optional result dictionary returned by
                :func:`load`. Use this or provide ``current`` directly.
            current: Optional TES current waveform in amperes.
            current_key: Result key for the TES current waveform.
            baseline_current: Optional operating-point current in amperes. If
                omitted, average the first ``baseline_samples`` unique samples.
            baseline_samples: Number of initial unique samples used for the
                default baseline.

        Returns:
            A tuple ``(frequencies, dIdE)`` containing the one-sided FFT
            frequencies in hertz, including DC, and the complex normalized
            energy template in A/W.

        Raises:
            KeyError: If ``current_key`` is absent from ``simulation_result``.
            ValueError: If the energy, waveform, timestamps, baseline, or
                baseline sample count is invalid.
        """
        if not np.isfinite(deposited_energy) or deposited_energy <= 0:
            raise ValueError("deposited_energy must be positive")
        if simulation_result is not None and current is not None:
            raise ValueError("Provide simulation_result or current, not both")
        if simulation_result is not None:
            if current_key not in simulation_result:
                raise KeyError(f"Missing nonlinear current result: {current_key}")
            current = simulation_result[current_key]
        if current is None:
            raise ValueError("Provide simulation_result or current")
        if not isinstance(baseline_samples, (int, np.integer)):
            raise ValueError("baseline_samples must be a positive integer")
        if baseline_samples <= 0:
            raise ValueError("baseline_samples must be a positive integer")

        time = np.asarray(time, dtype=float)
        current = np.asarray(current, dtype=float)
        if time.ndim != 1 or current.ndim != 1:
            raise ValueError("time and current must be one-dimensional")
        if len(time) != len(current):
            raise ValueError("time and current must have equal lengths")
        if len(time) < 2 or np.any(np.diff(time) < 0):
            raise ValueError(
                "time must contain at least two nondecreasing samples"
            )
        if not np.all(np.isfinite(time)) or not np.all(np.isfinite(current)):
            raise ValueError("time and current must contain finite values")

        _, reverse_indices = np.unique(time[::-1], return_index=True)
        unique_indices = np.sort(len(time) - 1 - reverse_indices)
        unique_time = time[unique_indices]
        unique_current = current[unique_indices]
        if len(unique_time) < 2:
            raise ValueError("time must contain at least two unique samples")
        if baseline_current is None and baseline_samples > len(unique_current):
            raise ValueError(
                "baseline_samples cannot exceed the number of unique samples"
            )

        if baseline_current is None:
            baseline = float(np.mean(unique_current[:baseline_samples]))
        else:
            baseline = float(baseline_current)
        if not np.isfinite(baseline):
            raise ValueError("baseline_current must be finite")

        sample_interval = float(np.median(np.diff(unique_time)))
        if not np.isfinite(sample_interval) or sample_interval <= 0:
            raise ValueError("time must define a positive sample interval")
        uniform_sample_count = int(
            np.floor((unique_time[-1] - unique_time[0]) / sample_interval)
        ) + 1
        if uniform_sample_count < 2:
            raise ValueError("time must span at least one sample interval")
        uniform_time = (
            unique_time[0] + np.arange(uniform_sample_count) * sample_interval
        )
        uniform_current = np.interp(
            uniform_time,
            unique_time,
            unique_current,
        )
        delta_current = uniform_current - baseline
        frequencies = np.fft.rfftfreq(uniform_sample_count, sample_interval)
        dIdE = (
            sample_interval
            * np.fft.rfft(delta_current)
            / float(deposited_energy)
        )
        return frequencies, dIdE

    def get_nonlinear_phonon_energy_collection_efficiency(
        self,
        time,
        simulation_result=None,
        deposited_energy=None,
        voltage=None,
        current=None,
        voltage_key="c1.v",
        current_key="c1.i",
        baseline_voltage=None,
        baseline_current=None,
    ):
        """Calculate Joule-energy collection from a nonlinear waveform.

        The full nonlinear TES voltage and current waveforms are required so
        that the exact Joule power ``v * i`` can be integrated after removal
        of the operating-point Joule power.

        Args:
            time: Monotonic simulation time samples in seconds.
            simulation_result: Optional result dictionary, such as the data
                returned by ``load``. Use this or provide ``voltage`` and
                ``current`` arrays directly.
            deposited_energy: Input energy in joules.
            voltage: Optional TES voltage waveform. Defaults to
                ``simulation_result[voltage_key]``.
            current: Optional TES current waveform. Defaults to
                ``simulation_result[current_key]``.
            voltage_key: Result key for the TES voltage waveform.
            current_key: Result key for the TES current waveform.
            baseline_voltage: Operating-point voltage. Defaults to the first
                voltage sample.
            baseline_current: Operating-point current. Defaults to the first
                current sample.

        Returns:
            A dictionary containing ``deposited_energy``, ``joule_energy``,
            ``collected_energy``, ``efficiency``, and ``integration_time``.

        Raises:
            ValueError: If required data is missing, arrays have inconsistent
                lengths, time is not strictly increasing, or energy is invalid.
            KeyError: If a requested waveform key is absent.
        """
        if deposited_energy is None or deposited_energy <= 0:
            raise ValueError("deposited_energy must be positive")
        if simulation_result is not None and (
            voltage is not None or current is not None
        ):
            raise ValueError(
                "Provide simulation_result or voltage/current arrays, not both"
            )
        if simulation_result is not None:
            if voltage_key not in simulation_result:
                raise KeyError(f"Missing nonlinear voltage result: {voltage_key}")
            if current_key not in simulation_result:
                raise KeyError(f"Missing nonlinear current result: {current_key}")
            voltage = simulation_result[voltage_key]
            current = simulation_result[current_key]
        if voltage is None or current is None:
            raise ValueError("Provide simulation_result or both voltage and current")

        time = np.asarray(time, dtype=float)
        voltage = np.asarray(voltage, dtype=float)
        current = np.asarray(current, dtype=float)
        if time.ndim != 1 or voltage.ndim != 1 or current.ndim != 1:
            raise ValueError("time, voltage, and current must be one-dimensional")
        if not (len(time) == len(voltage) == len(current)):
            raise ValueError("time, voltage, and current must have equal lengths")
        if len(time) < 2 or np.any(np.diff(time) < 0):
            raise ValueError("time must contain at least two strictly increasing samples")

        voltage_0 = float(voltage[0] if baseline_voltage is None else baseline_voltage)
        current_0 = float(current[0] if baseline_current is None else baseline_current)
        if not np.isfinite([voltage_0, current_0]).all():
            raise ValueError("Baseline voltage and current must be finite")
        joule_power_perturbation = voltage * current - voltage_0 * current_0
        joule_energy = float(trapz(joule_power_perturbation, time))
        collected_energy = float(-joule_energy)
        return {
            "deposited_energy": float(deposited_energy),
            "joule_energy": joule_energy,
            "collected_energy": collected_energy,
            "efficiency": collected_energy / deposited_energy,
            "integration_time": float(time[-1] - time[0]),
        }
    
    
    def get_impulse_split(self, index_cinput1 = -1, index_cinput2 = 2, fraction_1 = 0.5, T=None, scale_ev = None):
        """
        Compute the impulse response of the linearized system with unit Energy/Voltage input on two inputs
        ---
        index_cinput: index of the external input
        
        Returns
        ---
        t (ndarray): 1D array of time values.
        y (ndarray): Array of shape (len(t), n) containing the response of all states over time.
        """    
        
        t, y1 = self.get_impulse(index_cinput = index_cinput1, T = T)
        t, y2 = self.get_impulse(index_cinput = index_cinput2, T = T)
        y = y1 * fraction_1 + y2 * (1-fraction_1)
        if scale_ev is not None:
            y = y*scale_ev * scipy.constants.e
            
        return t, y
        
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
    
    
    def plot_noise_current(self, range = (1e-13, 1e-10)):
        frequencies = self.frequencies
        plt.loglog(frequencies, self.noise_current_total, label="Total", color="k", linewidth=3)
        plt.loglog(frequencies, self.noise_current_totaltfn, label="TFN", color="r")


        for key in self.noise_current:
            noise = abs(self.noise_current[key])
            if noise[0]<range[0]:
                continue
            if "TFN" not in key:
                plt.loglog(frequencies, noise, label=key)
            else:
                plt.loglog(frequencies, noise, label=key, linestyle="-.")

        plt.legend(loc=(1.01,0))
        plt.ylim(*range)
        plt.grid(which="both", alpha=0.2)
        plt.xlabel("Frequency [Hz]")
        plt.ylabel(r"Current noise [A/$\sqrt{Hz}$]")
        
        return plt.gcf(), plt.gca()
    
        
    def plot_impedance(self, content = "dvdi", fmin = None, fmax=None):
        """
        Plot the impedance, with an option to plot
          dIdV
          dVdI
          ztes: TES impedance (dVdI - Rp - iwL)
        """
        
        model = self
        if content == "didv":
            dvdi = model.get_dIdV()
        elif content == "dvdi":
            didv = model.get_dIdV()
            dvdi = 1/didv
        elif content == "ztes":
            dvdi = model.get_impedance()

        # Frequency limit
        mask = None
        if fmin is not None:
            mask = model.frequencies > fmin
        if fmax is not None:
            mask = model.frequencies < fmax if mask is None else mask & (model.frequencies < fmax)            

        fig, axs = plt.subplots(1,2, figsize=(12,4))

        plt.sca(axs[0])
        plt.plot(model.frequencies[mask], np.abs(dvdi[mask]))
        plt.xscale("log")
        plt.grid(which="both", alpha=0.2)
        plt.xlabel("Frequency [Hz]")
        plt.ylabel(r"|$Z_{circ}$| [$\Omega$]")
        ax0_twin = plt.gca().twinx()
        ax0_twin.plot(model.frequencies[mask], np.angle(dvdi[mask])/np.pi*180, color='C1', linestyle="-.")
        ax0_twin.tick_params(axis='y', colors='C1')
        ax0_twin.yaxis.label.set_color('C1')
        ax0_twin.spines['right'].set_color('C1') 
        ax0_twin.set_ylabel(r"$\angle (Z_{circ})$ [$^o$]")


    
        plt.sca(axs[1])
        if mask is None:
            plt.plot(dvdi.real, dvdi.imag)
        else:
            plt.plot(dvdi.real[mask], dvdi.imag[mask])
        plt.grid(alpha=0.2)
        plt.axhline(0,color="grey")
        plt.axvline(0,color="grey")
        plt.gca().set_aspect('equal', adjustable='box')
        plt.xlabel(r"Real($Z_{circ}$) [$\Omega$]")
        plt.ylabel(r"Imag($Z_{circ}$) [$\Omega$]")

        plt.tight_layout()
        
        return fig, axs
    
    
    
    def check_contributions(self, k: int):
        """ Diagnosis, checking the contribution of each source to the total response
        k: the index of the response to check
        """
        w, V = np.linalg.eig(self.model["A"])
        W = np.linalg.inv(V)
        p = V[:, k] * W[k, :]

        for name, val in sorted(zip(self.model["stateVars"], p), key=lambda x: abs(x[1]),
        reverse=True):
            print(name, val, abs(val))    



def _write_override_file(base_override_file, params, run_dir):
    """Create a run-local OpenModelica override file.

    Args:
        base_override_file: Optional source override file.
        params: Parameter values to replace or append.
        run_dir: Destination directory for the generated override file.

    Returns:
        Path to the generated override file.
    """
    run_dir = Path(run_dir)
    base_override_file_basename = Path(base_override_file).stem
    output = run_dir / f"{base_override_file_basename}_mcmc_override.txt"
    params = {} if params is None else dict(params)
    seen = set()
    lines = []

    if base_override_file is not None and Path(base_override_file).exists():
        for line in Path(base_override_file).read_text().splitlines():
            match = re.match(r"^(\s*)([A-Za-z_]\w*)\s*=", line)
            if match and match.group(2) in params:
                name = match.group(2)
                lines.append(f"{name}={params[name]:.17g}")
                seen.add(name)
            else:
                lines.append(line)

    for name, value in params.items():
        if name not in seen:
            lines.append(f"{name}={value:.17g}")

    output.write_text("\n".join(lines) + "\n")
    return output


def run_model(
    model_exe,
    build_dir,
    copy_exe=False,
    override_file=None,
    params=None,
    equilibrium_time=20.0,
    fine_stop_time=0.1,
    coarse_step_size=2e-4,
    fine_step_size=1e-6,
    tolerance=1e-8,
    solver="dassl",
    linearized_model_file="linearized_model.py",
    init_result_file=None,
    pulse_result_file=None,
    keep_runs=False,
    extra_coarse_args=None,
    extra_fine_args=None,
    verbose=True,
):
    """Run an OpenModelica equilibrium and fine pulse simulation.

    Args:
        model_exe: Compiled OpenModelica executable, absolute or relative to
            ``build_dir``.
        build_dir: Directory containing the executable and generated runtime
            support files.
        copy_exe: Run from an isolated temporary copy of the executable and
            runtime support files.
        override_file: Optional base OpenModelica override file.
        params: Optional dictionary of parameter values that replace or append
            entries in ``override_file``.
        equilibrium_time: Coarse equilibrium and linearization stop time.
        fine_stop_time: Fine pulse simulation stop time.
        coarse_step_size: Coarse simulation step size in seconds.
        fine_step_size: Fine simulation step size in seconds.
        tolerance: OpenModelica solver tolerance.
        solver: OpenModelica solver name.
        linearized_model_file: Generated linearized-model filename.
        init_result_file: Equilibrium result filename. Defaults to the model
            executable name plus ``_res_init.mat``.
        pulse_result_file: Fine result filename. Defaults to the model
            executable name plus ``_res_final.mat``.
        keep_runs: Keep the temporary run directory after completion or error.
        extra_coarse_args: Additional coarse simulation arguments.
        extra_fine_args: Additional fine simulation arguments.
        verbose: Print coarse/fine simulation progress messages.

    Returns:
        A dictionary containing the run directory, override file, result
        paths, linearized-model path, subprocess logs, and parameter values.

    Raises:
        subprocess.CalledProcessError: If either OpenModelica simulation fails.
        OSError: If required files cannot be copied or written.
    """
    build_dir = Path(build_dir).resolve()
    model_exe = Path(model_exe)
    if not model_exe.is_absolute():
        model_exe = build_dir / model_exe
    model_name = model_exe.name
    base_override_file = (
        None if override_file is None else Path(override_file).resolve()
    )
    init_result_file = init_result_file or f"{model_name}_res_init.mat"
    pulse_result_file = pulse_result_file or f"{model_name}_res_final.mat"
    if copy_exe:
        run_dir = Path(tempfile.mkdtemp(prefix="tes_model_", dir=build_dir))
    else:
        run_dir = build_dir

    required = [
        model_exe,
        build_dir / f"{model_name}_init.xml",
        build_dir / f"{model_name}_info.json",
        build_dir / f"{model_name}_JacA.bin",
    ]
    for source in required:
        if source.exists() and copy_exe:
            shutil.copy2(source, run_dir / source.name)

    try:
        generated_override_file = _write_override_file(
            base_override_file, params, run_dir
        )
        executable = f"./{model_name}"
        coarse_args = [
            executable,
            f"-overrideFile={generated_override_file.name}",
            "-startTime=0",
            f"-stopTime={equilibrium_time}",
            f"-stepSize={coarse_step_size}",
            f"-tolerance={tolerance}",
            f"-s={solver}",
            "-w",
            "-outputFormat=mat",
            f"-r={init_result_file}",
            f"-l={equilibrium_time}",
        ] + list(extra_coarse_args or [])
        fine_args = [
            executable,
            f"-r={pulse_result_file}",
            f"-overrideFile={generated_override_file.name}",
            f"-s={solver}",
            "-w",
            "-startTime=0",
            f"-stopTime={fine_stop_time}",
            f"-stepSize={fine_step_size}",
            f"-maxStepSize={fine_step_size*3}",
            f"-tolerance={tolerance}",
            f"-iif={init_result_file}",
            f"-iit={equilibrium_time}",
            "-lv=-LOG_STDOUT",
        ] + list(extra_fine_args or [])

        logs = {}
        if equilibrium_time > 0:
            if verbose:
                print("Running coarse simulation")
            logs["coarse"] = subprocess.run(
                coarse_args,
                cwd=run_dir,
                check=True,
                capture_output=True,
                text=True,
            )
            generated_linearized_model = run_dir / "linearized_model.py"
            requested_linearized_model = run_dir / linearized_model_file
            if not generated_linearized_model.exists():
                raise FileNotFoundError(
                    "OpenModelica did not generate linearized_model.py"
                )
            if generated_linearized_model != requested_linearized_model:
                generated_linearized_model.replace(requested_linearized_model)
            if verbose:
                print(
                    "Linearized model available at "
                    f"{requested_linearized_model}"
                )
        if fine_stop_time > 0:
            if verbose:
                print("Running fine simulation")
            logs["fine"] = subprocess.run(
                fine_args,
                cwd=run_dir,
                check=True,
                capture_output=True,
                text=True,
            )
            
            
        return {
            "run_dir": run_dir,
            "override_file": generated_override_file,
            "init_result": run_dir / init_result_file,
            "pulse_result": run_dir / pulse_result_file,
            "linearized_model": run_dir / linearized_model_file,
            "logs": logs,
            "params": {} if params is None else dict(params),
        }
    except Exception:
        if copy_exe and not keep_runs:
            shutil.rmtree(run_dir, ignore_errors=True)
        raise


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
        verbose=False,
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
        self.verbose = bool(verbose)

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
        """Run the configured coarse equilibrium and fine pulse simulations.

        Args:
            params: Parameter values to write into the run-local override file.

        Returns:
            The standalone ``run_model`` result dictionary, or ``None`` when
            execution fails. The exception is stored in ``last_error``.
        """
        try:
            result = run_model(
                model_exe=self.model_exe,
                build_dir=self.build_dir,
                copy_exe=True,
                override_file=self.base_override_file,
                params=params,
                equilibrium_time=self.equilibrium_time,
                fine_stop_time=self.fine_stop_time,
                coarse_step_size=self.coarse_step_size,
                fine_step_size=self.fine_step_size,
                tolerance=self.tolerance,
                solver=self.solver,
                linearized_model_file=self.linearized_model_file,
                init_result_file=self.init_result_file,
                pulse_result_file=self.pulse_result_file,
                keep_runs=self.keep_runs,
                extra_coarse_args=self.extra_coarse_args,
                extra_fine_args=self.extra_fine_args,
                verbose=self.verbose,
            )
            self.last_result = result
            self.last_error = None
            return result

        except Exception as exc:
            self.last_error = exc
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
            run_dir = Path(result["run_dir"]).resolve()
            if not self.keep_runs and run_dir != self.build_dir:
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


def read_config(filename):
    result = {}

    with open(filename, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()

            # Skip empty lines and comments
            if not line or line.startswith("#"):
                continue

            key, value = line.split("=", 1)
            result[key.strip()] = float(value.strip())

    return result


def write_config(filename, data):
    with open(filename, "w", encoding="utf-8") as f:
        for key, value in data.items():
            f.write(f"{key}={value}\n")

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


# Modify SVGs with simulation results.


def _svg_result_value(data, keys, sample_index):
    """Return one finite scalar from the first available result key.

    Args:
        data: Mapping of simulation result names to scalar or array-like values.
        keys: Result names to try in priority order.
        sample_index: Index used when a result is array-like.

    Returns:
        The selected value as a float, or ``None`` when none of the candidates
        contains a finite scalar at the requested sample.
    """
    for key in keys:
        if key not in data:
            continue

        values = np.asarray(data[key])
        try:
            value = values.item() if values.ndim == 0 else values[sample_index]
            value = float(value)
        except (IndexError, TypeError, ValueError):
            continue
        if np.isfinite(value):
            return value
    return None


def _replace_svg_text(text, data, sample_index, replacements, missing_labels):
    """Annotate a single SVG text node while retaining its outer whitespace.

    Args:
        text: Raw text stored in an SVG ``text`` element.
        data: Mapping of simulation result names to values.
        sample_index: Simulation sample to display.
        replacements: Exact custom label replacements supplied by the caller.
        missing_labels: Set populated with recognized labels lacking data.

    Returns:
        The annotated text, including the original leading and trailing
        whitespace.
    """
    label = text.strip()
    if not label:
        return text

    leading = text[: len(text) - len(text.lstrip())]
    trailing = text[len(text.rstrip()) :]

    if label in replacements:
        replacement = replacements[label]
        if not isinstance(replacement, str):
            raise TypeError("SVG replacement values must be strings")
        return f"{leading}{replacement}{trailing}"

    value = None
    replacement = None
    match = re.fullmatch(r"K=K(\d+)", label)
    if match:
        index = match.group(1)
        value = _svg_result_value(data, (f"g{index}.G", f"G{index}"), sample_index)
        if value is not None:
            replacement = f"G={value:.3g}"

    match = re.fullmatch(r"m=m(\d+)", label)
    if match:
        index = match.group(1)
        value = _svg_result_value(data, (f"c{index}.C", f"C{index}"), sample_index)
        if value is not None:
            replacement = f"C={value:.3g}"

    match = re.fullmatch(r"c(\d+)", label)
    if match:
        index = match.group(1)
        value = _svg_result_value(data, (f"c{index}.T", f"T{index}"), sample_index)
        if value is not None:
            replacement = f"c{index} {value * 1e3:.3g}mK"

    if label == "m=TES_m":
        value = _svg_result_value(data, ("c1.C", "C1"), sample_index)
        if value is not None:
            replacement = f"C={value:.3g}"
    elif "TES_Tc" in label:
        value = _svg_result_value(data, ("c1.T", "T1"), sample_index)
        if value is not None:
            replacement = label.replace("TES_Tc", f"{value:.3g}")
    elif "=Tb" in label:
        value = _svg_result_value(data, ("fixedTemperature.T",), sample_index)
        if value is not None:
            replacement = label.replace("=Tb", f"={value * 1e3:.3g} mK")
    elif label in ("R=Bias_R", "R=Bias_Rp"):
        key = label.removeprefix("R=")
        value = _svg_result_value(data, (key,), sample_index)
        if value is not None:
            replacement = f"R={value * 1e3:.3g} mOhm"

    if replacement is not None:
        return f"{leading}{replacement}{trailing}"
    if value is None and (
        re.fullmatch(r"(?:K=K|m=m|c)\d+", label)
        or label == "m=TES_m"
        or "TES_Tc" in label
        or "=Tb" in label
        or label in ("R=Bias_R", "R=Bias_Rp")
    ):
        missing_labels.add(label)
    return text


def mod_svg(
    filename,
    output_filename,
    data,
    system_name="System_LMO",
    width=900,
    display=True,
    *,
    sample_index=-1,
    replacements=None,
):
    """Write an SVG diagram annotated with simulation values.

    The default rules recognize TES thermal-network labels independently of a
    particular system name. Labels ``K=KN``, ``m=mN``, and ``cN`` use the
    corresponding conductance, heat capacity, and temperature results. Custom
    replacements are matched against stripped SVG text and take precedence.

    Args:
        filename: Source SVG path.
        output_filename: Destination SVG path.
        data: Mapping of simulation result names to scalar or array-like values.
        system_name: Retained for compatibility with older callers. Annotation
            is now inferred from SVG labels, so this value does not gate rules.
        width: Display width in pixels for returned notebook HTML.
        display: Whether to return an ``IPython.display.HTML`` image tag.
        sample_index: Index selected from array-like simulation results.
        replacements: Optional mapping of exact stripped SVG labels to their
            replacement text.

    Returns:
        An ``IPython.display.HTML`` object when ``display`` is true; otherwise
        ``None``.

    Raises:
        TypeError: If a custom replacement value is not a string.
        xml.etree.ElementTree.ParseError: If the source is not valid XML.
    """
    del system_name
    replacements = {} if replacements is None else replacements

    # Preserve the SVG's default namespace rather than emitting ``ns0`` tags.
    namespaces = dict(
        namespace for _, namespace in ET.iterparse(filename, events=("start-ns",))
    )
    for prefix, uri in namespaces.items():
        if not prefix.startswith("ns"):
            ET.register_namespace(prefix, uri)

    tree = ET.parse(filename)
    missing_labels = set()
    for element in tree.getroot().iter():
        if element.tag.rsplit("}", 1)[-1] != "text" or element.text is None:
            continue
        element.text = _replace_svg_text(
            element.text,
            data,
            sample_index,
            replacements,
            missing_labels,
        )

    tree.write(output_filename, encoding="utf-8", xml_declaration=True)
    if missing_labels:
        warnings.warn(
            "SVG labels left unchanged because matching simulation values were "
            f"missing or invalid: {', '.join(sorted(missing_labels))}",
            UserWarning,
            stacklevel=2,
        )

    if display:
        from IPython.display import HTML
        import time

        return HTML(
            f'<img src="{output_filename}?t={time.time()}" '
            f'width="{width}" '
            'style="background-color: #ffffff; padding: 16px; border-radius: 8px;">'
        )
    return None
