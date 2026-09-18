# TES Thermal Model

Modelica models for thermal and electrothermal simulations of Transition Edge Sensor (TES) detectors. The repository contains a reusable component library plus system-level examples for TES biasing, Joule heating, nonlinear thermal links, temperature-dependent heat capacities, and detector response to pulsed energy input.

## 1. Repository Contents

- `libTES.mo` - local Modelica package containing reusable TES thermal-model components.
- `System_1block.mo` - one-block TES system using `libTES.TES2` and nonlinear thermal conductance.
- `System_1block_linearG.mo` - one-block TES system using `libTES.TES` and Modelica's linear `ThermalConductor`.
- `System_LMO.mo` - larger LMO detector thermal network with multiple heat-capacity nodes and conductance links.
- `/parameters` - reference parameter set.
- `/python` - python scripts and notebooks for running simulations and analyzing results
- `/script` - `omc` scripts to run and build models

All Modelica source files currently live at the repository root. The reusable components are organized inside `libTES.mo`; the system models instantiate them with qualified names such as `libTES.TES2` and `libTES.ThermlConductanceN`.

The Modelica models give you a time-domain simulation of the full non-linear model (including all nonlinearities in resistance, heat capacitance and conductance).
As for noise and complex impedance analysis, you need to generate a linearized model around the equilibrium point.


### 1.1 Requirements

Use OpenModelica/OMEdit with the Modelica Standard Library. Follow the installation guide on https://openmodelica.org/. If OpenModelica reports that the Modelica package is missing, install Modelica 4.1.0 from OMEdit's package manager or through an OpenModelica script.

## 2. Running In OMEdit (GUI)

Load the local library before loading any system model:

1. Open OMEdit.
2. Select **File > Open Model/Library File(s)** and open `libTES.mo` and the system model you want to run, for example `System_1block.mo`, `System_1block_linearG.mo`, or `System_LMO.mo`.
5. Click **Check Model** and fix any reported errors before simulating.
6. Click **Simulate** to run with the experiment settings stored in the model annotation.
7. Open the plotting view and inspect variables such as TES temperature, current, Joule power, heat-capacity values, or conductance outputs.

The model annotations store simulation settings so they travel with the files.

### OMEdit Troubleshooting

- If you see `Class libTES\cdots not found`, load `libTES.mo` first, then reload the system model.
- If you see missing `Modelica.Thermal`, `Modelica.Electrical`, or other standard-library classes, install or load Modelica 4.1.0.
- If OMEdit reports a parser error around `addClassAnnotation`, restart OMEdit or clear the scripting input/session, then reload `libTES.mo` and the target system model.
- If a parameter is reported as having neither a value nor a start value, check the parameter declarations in the system model and any parameter file you are using.

## 3. Running From Command Line

Because the system models depend on the local `libTES` package, load `libTES.mo` before checking or simulating a system model. A direct command such as `omc System_LMO.mo` may fail with `Class libTES\cdots not found` if the library is not already loaded.

The most reliable command-line workflow is to create a small `.mos` script for the model you want to run. Two example `.mos` scripts are given. `run_System_LMO_init.mos` will run the System_LMO model interactively, while `compile_System_LMO_init.mos` only build an executable.

Run the `.mos` script with 

```bash
omc SCRIPT_NAME
```

Once the executable is generated, you can directly run the executable file from the command line or python. Here's an example of running it in python through subprocess:

```python

MODEL_NAME = "System_LMO_exe"
EQUILIBRIUM_TIME = 20.0
PARAMS = "../parameters/params_lmo_v1_mod_tes.txt"

# A run with coarse step just to find the equilibrium
subprocess.run(
    [
        f"./{MODEL_NAME}",
        # "-lv=-LOG_STDOUT",
        f"-overrideFile={PARAMS}",
        "-startTime=0",
        f"-stopTime={EQUILIBRIUM_TIME}",
        "-stepSize=1e-4",
        "-tolerance=1e-8",
        "-s=dassl",
        "-w", # Show all warnings
        "-outputFormat=mat",
        f"-r={MODEL_NAME}_res_init.mat", # Result filename
        f"-l={EQUILIBRIUM_TIME}", ## Perform linearization
    ],
    cwd="build",
    check=True
)
```


### Generated Files

Simulation from `omc` may create generated C files, object files, an executable, logs, XML/JSON metadata, and result files such as `System_LMO_res.mat` in the working directory. These are build and simulation artifacts; rerun the simulation to regenerate them when needed. The two provided mos scripts will make a build folder and save all the generated file inside. The result file is in matlab format. A python loader using scipy is included in `pymodelica.py`.

### Python Analysis Helpers

`python/pymodelica.py` contains helper functions for reading OpenModelica output and analyzing linearized TES models:

- `load(filename)` reads an OpenModelica MATLAB `.mat` result file and returns `(time, variables)`, where `variables` maps Modelica result names such as `c1.T`, `RL.R`, and `g1.G` to NumPy arrays.
- `load_linearized_model(linearized_model)` normalizes a Python linearization dump produced with `--linearizationDumpLanguage=python`. It returns NumPy arrays for `x0`, `u0`, `A`, `B`, `C`, and `D`, and reorders states to `CL_v`, `L_i`, then `c1_T`, `c2_T`, \cdots by numeric heat-capacity index.
- `parse_thermal_conductance_connections(modelica_file)` reads the full Modelica source and maps each nonlinear conductance `g*` to the heat-capacity endpoints connected to `port_a` and `port_b`. A fixed-temperature bath endpoint is reported as `0`.
- `TESModel` combines the linearized model, full Modelica source, and steady-state simulation results to compute frequency-domain transfer functions, complex impedance, phonon/Johnson/readout noise contributions, and equivalent input noise.
- `mod_svg(\cdots)` writes a copy of `System_LMO.svg` with selected simulated values substituted into the diagram labels.

Example workflow:

```python
import pymodelica

time, simulation_results = pymodelica.load("build/System_LMO_res_init.mat")

model = pymodelica.TESModel(
    "build/System_LMO_init_linearized.py",
    "System_LMO.mo",
    simulation_results,
    config={"L": simulation_results["L.L"][-1], "RL": simulation_results["RL.R"][-1]},
    f_min=1,
    f_max=100e3,
    points=1000,
)

z_tes = model.get_impedance()
dIdP = model.get_dIdP(index_cinput=-1)
noise_current, frequencies = model.get_noise(RL_temperature=0.2)
```

The Python helpers rely on the naming conventions in Section 4.2. In particular, the linearized state names must include `CL_v` and `L_i`, and heat-capacity temperatures must be named `cN_T` so they can be sorted numerically instead of lexicographically.

## 4. Modeling Notes

### 4.1 Component Library

`libTES.mo` defines the reusable models used by the system examples:

- `libTES.TES` - TES component with electrical pins, one thermal port, tanh transition resistance, Joule heating, and constant heat capacity.
    - $R = \frac{R_n}{2} (1+ \tanh(\frac{T - T_c}{T_c} \alpha + \frac{I - I_0}{I_0} \beta))$
    - $C \dot{T} = P_{Joule} + Q_{flow}$
- `libTES.TES2` - Almost the same as `TES` but with temperature dependent heat capacity.
    - $c_p = a_1 T + a_3 T^3$
    - $m c_p \dot{T} = P_{Joule} + Q_{flow}$

- `libTES.ThermlConductanceN` - nonlinear thermal conductance between two heat ports:
    - $Q_{flow} = K (T_a^n - T_b^n)$
- `libTES.HeatCapacitorPoly` - thermal mass with polynomial specific heat capacity:
    - $c_p = a_0 + a_1 T + a_3 T^3 + a_5 T^5$

### 4.2 Convention

**The conventions must be followed for the analysis code to work**
1. Top level model should use names `c*` and `g*` for heat capacities and thermal conductances. Use 1-based indexing for the variables rather than names. **Always name TES c1.** It is optional to give the target the largest index.
2. For TES bias circuit, always use a current bias with a shunt resistor named `RL`, a loop capacitance named `CL`, and a loop inductance named `L`. 



## 5. Analyzing Linearized Model

A linearized model could be generated after reaching equilibrium. The model need to be compiled with `--linearizationDumpLanguage=python` option, see the example in `scripts/compile_System_LMO_init.mos`. The generated modle is in python format. The complex impedance and noise could be evaluated from the linearized model.

For our thermal models, the generated equations are given in the format of standard **state-space equations** for a dynamic system:

$$
\dot{x} = Ax + Bu
$$

$$
y = Cx + Du
$$

Here:

* **$x$** = **state vector** — the internal variables that describe the system's current state.
* **$u$** = **input vector** — the external inputs or controls applied to the system.
* **$y$** = **output vector** — the quantities you observe or want to calculate from the system.
* **$A$** = state/system matrix.
* **$B$** = input matrix, describing how \(u\) affects the states.
* **$C$** = output matrix, describing how the states \(x\) contribute to \(y\).
* **$D$** = feedthrough matrix, describing any **direct** effect of \(u\) on \(y\).
specifically:

$$
\boxed{u=\text{system input}}
\qquad
\boxed{y=\text{system output}}
$$

For TES current equation, $u$ is the **applied voltage**, $x$ is **TES current**, and there is no equation for $y$ (C=D=0).

The name of variables are given as stateVars, e.g., for our LMO system model 

    stateVars  = ['CL_v','L_i','c1_T','c10_T','c2_T','c3_T','c4_T','c5_T','c6_T','c7_T','c8_T','c9_T']

The first term $V_{C_L}$ is the voltage across the parasitic capacitance of the bias circuit, which is almost identical to the voltage across TES. The second term is the current through the inductor, which is equal to the TES current $I_{TES}$. Let's assume we followed the convention and TES is HeatCapacitance c1. A complete set of equations will be like:

```math
\frac{d}{dt} 
\begin{pmatrix}
\Delta V_{C_L} \\ \Delta I_{TES} \\ \Delta T_{1} \\ \Delta T_2 \\ \vdots \\ \Delta T_n
\end{pmatrix}

=
\begin{pmatrix}
 -1/R_LC_L &  -1/C_L  & 0 & 0 & \cdots & 0 \\
1/L & -R_L(1+\beta)/L &  -\alpha V_{bias}/T_cL & 0 & \cdots & 0 \\
0 & (2+\beta)V_{bias}/C_{1} & G_{1,1}/C_1 & G_{1,2}/C_1 & \cdots & G_{1,n}/C_1 \\
0  & 0  & G_{2,1}/C_2 & G_{2,2}/C_2 & \cdots & G_{2,n}/C_1  \\
\vdots  & \vdots  & \vdots  & \vdots  & \vdots \\
0 & 0  & G_{n,1}/C_n & G_{n,2}/C_n & \cdots & G_{n,n}/C_1
\end{pmatrix}

\begin{pmatrix}
\Delta V_{C_L} \\ \Delta I_{TES} \\ \Delta T_1  \\ \Delta T_2 \\ \vdots \\ \Delta T_n
\end{pmatrix}
+ 
\begin{pmatrix}
\delta V_{ext}/R_LC_L \\ \delta V_{int}/L \\ (\delta P_{1} - I_{TES}\delta V_{int} )/C_1 \\ \delta P_2/C_2 \\ \vdots \\ \delta P_n/C_n
\end{pmatrix}
```


in which $\delta V_{ext}$ is the voltage of the external TES bias (can be replaced with $ R_L \delta I_{ext}$ in a Thévenin equivalent current bias), $\delta V_{int}$ is the internal TES voltage, which is zero except for the TES Johnson noise. The big matrix is matrix A in the linearized python model, B = identity matrix, and C = D = 0.


We can solve these equations in Fourier space easily. After Fourier transform, d/dt becomes $i\omega$, and the coefficient matrix becomes $H(\omega) = A - diag(i\omega, \cdots , i\omega)$


```math
0=
\begin{pmatrix}
 -1/R_LC_L -i\omega  &  -1/C_L  & 0 &0 & \cdots & 0 \\
1/L & -R_L(1+\beta)/L -i\omega &  -\alpha V_{bias}/T_cL & \cdots & 0 \\
0 & (2+\beta)V_{bias}/C_{1} & G_{1,1}/C_1 -i\omega & G_{1,2}/C_1 & \cdots & G_{1,n}/C_1 \\
0  & 0  & G_{2,1}/C_2 & G_{2,2}/C_2 -i\omega& \cdots & G_{2,n}/C_2  \\
\vdots  & \vdots  & \vdots  & \vdots  & \vdots \\
0 & 0  & G_{n,1}/C_n & G_{n,2}/C_n & \cdots & G_{n,n}/C_n -i\omega
\end{pmatrix}

\begin{pmatrix}
\Delta V_{C_L} \\ \Delta I_{TES} \\ \Delta T_1  \\ \Delta T_2 \\ \vdots \\ \Delta T_n
\end{pmatrix}
+ 
\begin{pmatrix}
\delta V_{ext}/R_LC_L \\ \delta V_{int}/L \\ (\delta P_{1} - I_{TES}\delta V_{int} )/C_1 \\ \delta P_2/C_2 \\ \vdots \\ \delta P_n/C_n
\end{pmatrix}
```




### 5.1 Complex impedance

We set all excitations to zero except for $\delta V_{bias} = 1$ and solve for $\Delta I_{TES}$. The solution can be obtained by directly inverting the H matrix, multiply by the excitation vector and take the second component. Since the excitation is model-independent, the same code can be used to calculate complex impedance when model changes. 

```math
dIdV(\omega) = \left[ H(\omega)^{-1}\begin{pmatrix}
1/R_L C_L \\ 0 \\ 0 \\ 0 \\ \vdots \\ 0
\end{pmatrix}
\right]_2
```


### 5.2 Noise

The same concept applies to noise, you just need to set the appropriate excitation of each noise source. We will go through each of the noise sources. Note that we use **one-sided** frequency for all noise terms.

#### 5.2.1 Johnson noise

There load resistor and TES resistance both produces Johnson noise with a **one-sided** power spectral density of $\overline{V_n^2} = 4k_B T R \Delta f$. But they correspond to 
different external input. Load resistor noise is $\delta V_{ext}$, while TES noise is $\delta V_{int}$.


#### 5.2.2 Thermal fluctuation noise (TFN)

For all cases where the temperature difference between two adjoining heat capacity blocks is a step function (ballistic phonons, e-p interaction, Kapitza resistance), the **one-sided** TFN power spectral density is well approximated $\overline{P_n^2} = 2 k_B (G_1 T_1^2 + G_2 T_2^2) \Delta f$. (BOYLE, WS, and KF RODGERS. "Performance characteristics of a new low-temperature bolometer." SPIE milestone series 179 (2004): 290-291.). It reduces to $4 k_B G T^2$ for a single body in thermal equilibrium, and can be derived from $\langle\Delta E^2\rangle=k_BT^2C$.

Away from equilibrium, the simple formula is only approximate. https://pubmed.ncbi.nlm.nih.gov/20389816/

For each thermal link in the system, the contribution can be calculated by setting $P_i, P_j$ to the TFN of this link and solve for the equation.

#### 5.2.3 Readout noise

Readout noise directly adds on top of the current noise. Thus, it does not involves solving the equation. 

#### 5.2.4 Noise Equivalent Power (NEP)



### 5.3 MCMC fit

The system could be complicated, and there are many parameters that may not be well constrained by the data. In this case, we can use the MCMC method to fit the parameters with three measurements:

* **bias power** sets the DC equilibrium.
* **complex impedance** probes electrical response;
* **pulse response** probes the detector's thermal/electrical transfer function;


We can construct a log-likelihood function 

```math
\boxed{
\ln\mathcal L
=
-\frac12\chi_P^2
-\frac12\chi_Z^2
-\frac12\chi_{\rm pulse}^2
}
```

with

```math
\chi_P^2
=
\frac{
[P_{\rm obs}-P_{model}]^2
}{
\sigma_P^2
},
```

```math
\chi_Z^2
=
\sum_i
\left[
\frac{\mathrm{Re}(Z_i^{\rm obs}-Z_i^{\rm model})}
{\sigma_{\mathrm{Re},i}}
\right]^2
+
\left[
\frac{\mathrm{Im}(Z_i^{\rm obs}-Z_i^{\rm model})}
{\sigma_{\mathrm{Im},i}}
\right]^2.
```

and

```math
\chi_I^2=
\sum_j
\frac{
[I_j^{\rm obs}-I_j^{\rm model}]^2
}{
\sigma_{I,j}^2
}.
```

We choose to ignore the correlation and treat all measurements as statistically independent. This is largely true when the impulse response is averaged from many measurements. 


Since our model is mostly a black-box (not differentiable), the best choice for a python MCMC package is emcee, which doesn't need to know the internal structure of the model. 


## Modeled Systems

You can generate a svg figure of the model in OMEdit GUI by selecting File->Export->Image.

### LMO

<img src="System_LMO.svg" width="700" alt="LMO system thermal model" style="background-color: #ffffff; padding: 16px; border-radius: 8px;">


### Notes on TES resistance

One drawback of the simple TES resistance model is that it is only valid near Tc. A global expression would be


```math
\boxed{
R(T,I)=
\frac{R_n}{2}
\left[
1+
\tanh
\left(
\frac{
T-T_{c0}\left[
1-
\left(\dfrac{|I|}{I_{c0}}\right)^p
\right]
}
{\Delta T}
\right)
\right]
}
```

We can parameterize the full global tanh model so that it reproduces specified $\alpha_0\$ and $\beta_0$ at an arbitrary operating point $(T_0,I_0,R_0)$, while retaining the original nonlinear form. The entire global model can be written in terms of the experimentally meaningful parameters

```math
\boxed{
R_n,\quad
T_0,\quad
I_0,\quad
r_0=\frac{R_0}{R_n},\quad
\alpha_0,\quad
\beta_0,\quad
p.
}
```


with

```math
\left\{
\begin{aligned}
\Delta T&=
\frac{2T_0(1-r_0)}{\alpha_0}\\

T_{c0}
&=
T_0
\left[
1+
\frac{\beta_0}{p\alpha_0}
-
\frac{2(1-r_0)}{\alpha_0}
\operatorname{atanh}(2r_0-1)
\right]\\

I_{c0}
&=
|I_0|
\left(
\frac{p\alpha_0T_{c0}}
{\beta_0T_0}
\right)^{1/p}.
\end{aligned}
\right.
```

This is not a local approximation: the resulting $R(T,I)$ remains the **full nonlinear tanh surface**. The role of $\alpha_0$ and $\beta_0$ is to calibrate that global surface so that its logarithmic slopes at your selected operating point are exactly the desired values.

For example, if you choose the operating point at the middle of the transition, $r_0=\frac12$,
then the expressions become especially simple:

```math
\left\{
\begin{aligned}
\Delta T &= \frac{T_0}{\alpha_0},\\[6pt]
T_{c0} &= T_0\left(1+\frac{\beta_0}{p\alpha_0}\right),\\[6pt]
I_{c0} &= |I_0|
\left(
\frac{p\alpha_0+\beta_0}{\beta_0}
\right)^{1/p}.
\end{aligned}
\right.
```


For TES simulation, this last parameterization is particularly convenient: you can specify something like $R_0/R_n=0.3$, $T_0$, $I_0$, measured $\alpha_0$, measured $\beta_0$, and an assumed $p$, and the model automatically generates a global $R(T,I)$ surface consistent with that operating point.

```math
\boxed{
R(T,I)=
\frac{R_n}{2}
\left[
1+
\tanh
\left(
\alpha
\frac{
T-T_0(1+\frac{\beta_0}{p\alpha_0})\left[
1-
\left(\dfrac{|I|}{I_{0}}\right)^p \frac{\beta_0}{p\alpha_0 + \beta_0}
\right]
}
{T_0}
\right)
\right]
}
```


## Contributing

Keep model filenames aligned with model names when adding new system models. Prefer `Modelica.Units.SI` types for physical quantities, preserve existing experiment annotations, and document parameter choices that come from detector calibration or measurement data.






### Command-line arguments of the executable

```
LOG_STDOUT        | warning | invalid command line option: -help
LOG_STDOUT        | info    | usage: ./System_LMO_exe
|                 | |       | | <-abortSlowSimulation>
|                 | |       | |   aborts if the simulation chatters
|                 | |       | | <-alarm=value> or <-alarm value>
|                 | |       | |   aborts after the given number of seconds (0 disables)
|                 | |       | | <-clock=value> or <-clock value>
|                 | |       | |   selects the type of clock to use -clock=RT, -clock=CYC or -clock=CPU
|                 | |       | | <-cpu>
|                 | |       | |   dumps the cpu-time into the result file
|                 | |       | | <-csvOstep=value> or <-csvOstep value>
|                 | |       | |   value specifies csv-files for debug values for optimizer step
|                 | |       | | <-cvodeNonlinearSolverIteration=value> or <-cvodeNonlinearSolverIteration value>
|                 | |       | |   nonlinear solver iteration for CVODE solver
|                 | |       | | <-cvodeLinearMultistepMethod=value> or <-cvodeLinearMultistepMethod value>
|                 | |       | |   linear multistep method for CVODE solver
|                 | |       | | <-cx=value> or <-cx value>
|                 | |       | |   value specifies a csv-file with inputs as correlation coefficient matrix Cx for DataReconciliation
|                 | |       | | <-daeMode>
|                 | |       | |   flag to let the integrator use daeResiduals
|                 | |       | | <-deltaXLinearize=value> or <-deltaXLinearize value>
|                 | |       | |   value specifies the delta x value for numerical differentiation used by linearization. The default value is 1e-5.
|                 | |       | | <-deltaXSolver=value> or <-deltaXSolver value>
|                 | |       | |   value specifies the delta x value for numerical differentiation used by integrator. The default values is sqrt(DBL_EPSILON).
|                 | |       | | <-embeddedServer=value> or <-embeddedServer value>
|                 | |       | |   enables an embedded server. Valid values: none, opc-da [broken], opc-ua [experimental], or the path to a shared object.
|                 | |       | | <-embeddedServerPort=value> or <-embeddedServerPort value>
|                 | |       | |   [int (default 4841)] value specifies the port number used by the embedded server
|                 | |       | | <-mat_sync=value> or <-mat_sync value>
|                 | |       | |   [int (default 0)] syncs the mat file header after emitting every N time-points (default disabled)
|                 | |       | | <-emit_protected>
|                 | |       | |   emits protected variables to the result-file
|                 | |       | | <-eps=value> or <-eps value>
|                 | |       | |   value specifies the number of convergence iteration to be performed for DataReconciliation
|                 | |       | | <-f=value> or <-f value>
|                 | |       | |   value specifies a new setup XML file to the generated simulation code
|                 | |       | | <-help=value> or <-help value>
|                 | |       | |   get detailed information that specifies the command-line flag
|                 | |       | | <-homAdaptBend=value> or <-homAdaptBend value>
|                 | |       | |   [double (default 0.5)] maximum trajectory bending to accept the homotopy step
|                 | |       | | <-homBacktraceStrategy=value> or <-homBacktraceStrategy value>
|                 | |       | |   value specifies the backtrace strategy in the homotopy corrector step (fix (default), orthogonal)
|                 | |       | | <-homHEps=value> or <-homHEps value>
|                 | |       | |   [double (default 1e-5)] tolerance respecting residuals for the homotopy H-function
|                 | |       | | <-homMaxLambdaSteps=value> or <-homMaxLambdaSteps value>
|                 | |       | |   [int (default size dependent)] maximum lambda steps allowed to run the homotopy path
|                 | |       | | <-homMaxNewtonSteps=value> or <-homMaxNewtonSteps value>
|                 | |       | |   [int (default 20)] maximum newton steps in the homotopy corrector step
|                 | |       | | <-homMaxTries=value> or <-homMaxTries value>
|                 | |       | |   [int (default 10)] maximum number of tries for one homotopy lambda step
|                 | |       | | <-homNegStartDir>
|                 | |       | |   start to run along the homotopy path in the negative direction
|                 | |       | | <-homotopyOnFirstTry>
|                 | |       | |   directly use the homotopy method to solve the initialization problem
|                 | |       | | <-noHomotopyOnFirstTry>
|                 | |       | |   disable the use of the homotopy method to solve the initialization problem
|                 | |       | | <-homTauDecFac=value> or <-homTauDecFac value>
|                 | |       | |   [double (default 10.0)] decrease homotopy step size tau by this factor if tau is too big in the homotopy corrector step
|                 | |       | | <-homTauDecFacPredictor=value> or <-homTauDecFacPredictor value>
|                 | |       | |   [double (default 2.0)] decrease homotopy step size tau by this factor if tau is too big in the homotopy predictor step
|                 | |       | | <-homTauIncFac=value> or <-homTauIncFac value>
|                 | |       | |   [double (default 2.0)] increase homotopy step size tau by this factor if tau is too small in the homotopy corrector step
|                 | |       | | <-homTauIncThreshold=value> or <-homTauIncThreshold value>
|                 | |       | |   [double (default 10.0)] increase the homotopy step size tau if bend < homAdaptBend/homTauIncThreshold
|                 | |       | | <-homTauMax=value> or <-homTauMax value>
|                 | |       | |   [double (default 10.0)] maximum homotopy step size tau for the homotopy process
|                 | |       | | <-homTauMin=value> or <-homTauMin value>
|                 | |       | |   [double (default 1e-4)] minimum homotopy step size tau for the homotopy process
|                 | |       | | <-homTauStart=value> or <-homTauStart value>
|                 | |       | |   [double (default 0.2)] homotopy step size tau at the beginning of the homotopy process
|                 | |       | | <-idaMaxErrorTestFails=value> or <-idaMaxErrorTestFails value>
|                 | |       | |   value specifies the maximum number of error test failures in attempting one step. The default value is 7.
|                 | |       | | <-idaMaxNonLinIters=value> or <-idaMaxNonLinIters value>
|                 | |       | |   value specifies the maximum number of nonlinear solver iterations at one step. The default value is 3.
|                 | |       | | <-idaMaxConvFails=value> or <-idaMaxConvFails value>
|                 | |       | |   value specifies the maximum number of nonlinear solver convergence failures at one step. The default value is 10.
|                 | |       | | <-idaNonLinConvCoef=value> or <-idaNonLinConvCoef value>
|                 | |       | |   value specifies the safety factor in the nonlinear convergence test. The default value is 0.33.
|                 | |       | | <-idaLS=value> or <-idaLS value>
|                 | |       | |   select the linear solver used by ida
|                 | |       | | <-idaScaling>
|                 | |       | |   enable scaling of the IDA solver
|                 | |       | | <-idaSensitivity>
|                 | |       | |   flag to add sensitivity information to the result files
|                 | |       | | <-ignoreHideResult>
|                 | |       | |   ignore HideResult=true annotation
|                 | |       | | <-iif=value> or <-iif value>
|                 | |       | |   value specifies an external file for the initialization of the model relative to -inputPath
|                 | |       | | <-iim=value> or <-iim value>
|                 | |       | |   value specifies the initialization method
|                 | |       | | <-iit=value> or <-iit value>
|                 | |       | |   [double] value specifies a time for the initialization of the model
|                 | |       | | <-ils=value> or <-ils value>
|                 | |       | |   [int (default 3)] number of lambda steps for homotopy methods
|                 | |       | | <-initialStepSize=value> or <-initialStepSize value>
|                 | |       | |   value specifies an initial step size for supported solver
|                 | |       | | <-csvInput=value> or <-csvInput value>
|                 | |       | |   value specifies an csv-file with inputs for the simulation/optimization of the model
|                 | |       | | <-stateFile=value> or <-stateFile value>
|                 | |       | |   value specifies an file with states start values for the optimization of the model
|                 | |       | | <-inputPath=value> or <-inputPath value>
|                 | |       | |   value specifies a path for reading the input files i.e., model_init.xml and model_info.json
|                 | |       | | <-ipopt_hesse=value> or <-ipopt_hesse value>
|                 | |       | |   value specifies the hessian for Ipopt
|                 | |       | | <-ipopt_init=value> or <-ipopt_init value>
|                 | |       | |   value specifies the initial guess for optimization
|                 | |       | | <-ipopt_jac=value> or <-ipopt_jac value>
|                 | |       | |   value specifies the Jacobian for Ipopt
|                 | |       | | <-ipopt_max_iter=value> or <-ipopt_max_iter value>
|                 | |       | |   value specifies the max number of iteration for ipopt
|                 | |       | | <-ipopt_warm_start=value> or <-ipopt_warm_start value>
|                 | |       | |   value specifies lvl for a warm start in ipopt: 1,2,3,\cdots
|                 | |       | | <-jacobian=value> or <-jacobian value>
|                 | |       | |   select the calculation method of the Jacobian used only by ida and dassl solver.
|                 | |       | | <-jacobianThreads=value> or <-jacobianThreads value>
|                 | |       | |   [int default: 1] value specifies the number of threads for jacobian evaluation in dassl or ida.
|                 | |       | | <-l=value> or <-l value>
|                 | |       | |   value specifies a time where the linearization of the model should be performed
|                 | |       | | <-l_datarec>
|                 | |       | |   emit data recovery matrices with model linearization
|                 | |       | | <-logFormat=value> or <-logFormat value>
|                 | |       | |   value specifies the log format of the executable. -logFormat=text (default), -logFormat=xml or -logFormat=xmltcp
|                 | |       | | <-ls=value> or <-ls value>
|                 | |       | |   value specifies the linear solver method (default: lapack, totalpivot (fallback))
|                 | |       | | <-ls_ipopt=value> or <-ls_ipopt value>
|                 | |       | |   value specifies the linear solver method for ipopt
|                 | |       | | <-lss=value> or <-lss value>
|                 | |       | |   value specifies the linear sparse solver method (default: umfpack)
|                 | |       | | <-lssMaxDensity=value> or <-lssMaxDensity value>
|                 | |       | |   [double (default 0.2)] value specifies the maximum density for using a linear sparse solver
|                 | |       | | <-lssMinSize=value> or <-lssMinSize value>
|                 | |       | |   [int (default 1000)] value specifies the minimum system size for using a linear sparse solver
|                 | |       | | <-lv=value> or <-lv value>
|                 | |       | |   [string list] value specifies the logging level
|                 | |       | | <-lvMaxWarn=value> or <-lvMaxWarn value>
|                 | |       | |   [int (default 3)] maximum times repeating warnings will be displayed
|                 | |       | | <-lv_time=value> or <-lv_time value>
|                 | |       | |   [double list] specifying time interval to allow loging in
|                 | |       | | <-lv_system=value> or <-lv_system value>
|                 | |       | |   [int list] list of system indices for which solver logs are shown (by default logs for all systems are shown)
|                 | |       | | <-mbi=value> or <-mbi value>
|                 | |       | |   [int (default 0)] value specifies the maximum number of bisection iterations for state event detection or zero for default behavior
|                 | |       | | <-mei=value> or <-mei value>
|                 | |       | |   [int (default 20)] value specifies the maximum number of event iterations
|                 | |       | | <-maxIntegrationOrder=value> or <-maxIntegrationOrder value>
|                 | |       | |   value specifies maximum integration order for supported solver
|                 | |       | | <-maxStepSize=value> or <-maxStepSize value>
|                 | |       | |   value specifies maximum absolute step size for supported solver
|                 | |       | | <-measureTimePlotFormat=value> or <-measureTimePlotFormat value>
|                 | |       | |   value specifies the output format of the measure time functionality
|                 | |       | | <-moo>
|                 | |       | |   perform dynamic optimization with MOO library
|                 | |       | | <-moo_l2bn_p1_it=value> or <-moo_l2bn_p1_it value>
|                 | |       | |   [int default: 0] value specifies the number of phase I iterations (full bisections) for L2-Boundary-Norm mesh refinement in MOO
|                 | |       | | <-moo_l2bn_p2_it=value> or <-moo_l2bn_p2_it value>
|                 | |       | |   [int default: 0] value specifies the number of phase II iterations (refinement) for L2-Boundary-Norm mesh refinement in MOO
|                 | |       | | <-moo_l2bn_p2_lvl=value> or <-moo_l2bn_p2_lvl value>
|                 | |       | |   [real default: 0.0] value specifies the phase II refinement aggressiveness for L2-Boundary-Norm mesh refinement in MOO
|                 | |       | | <-newtonFTol=value> or <-newtonFTol value>
|                 | |       | |   [double (default 1e-12)] tolerance respecting residuals for updating solution vector in Newton solver
|                 | |       | | <-newtonMaxSteps=value> or <-newtonMaxSteps value>
|                 | |       | |   [int (default 20)] maximal number of Newton steps used in GBODE
|                 | |       | | <-newtonMaxStepFactor=value> or <-newtonMaxStepFactor value>
|                 | |       | |   [double (default 1e12)] maximum newton step factor mxnewtstep = maxStepFactor * norm2(xScaling). Used currently only by KINSOL.
|                 | |       | | <-newtonXTol=value> or <-newtonXTol value>
|                 | |       | |   [double (default 1e-12)] tolerance respecting newton correction (delta_x) for updating solution vector in Newton solver
|                 | |       | | <-newtonJacUpdates=value> or <-newtonJacUpdates value>
|                 | |       | |   [int list (at most 4 entries)] Number of steps before Jacobian is recomputed. Zero to skip phase.
|                 | |       | | <-newton=value> or <-newton value>
|                 | |       | |   value specifies the damping strategy for the newton solver
|                 | |       | | <-nls=value> or <-nls value>
|                 | |       | |   value specifies the nonlinear solver
|                 | |       | | <-nlsInfo>
|                 | |       | |   outputs detailed information about solving process of non-linear systems into csv files.
|                 | |       | | <-nlsLS=value> or <-nlsLS value>
|                 | |       | |   value specifies the linear solver used by the non-linear solver
|                 | |       | | <-nlssMaxDensity=value> or <-nlssMaxDensity value>
|                 | |       | |   [double (default 0.1)] value specifies the maximum density for using a non-linear sparse solver
|                 | |       | | <-nlssMinSize=value> or <-nlssMinSize value>
|                 | |       | |   [int (default 1000)] value specifies the minimum system size for using a non-linear sparse solver
|                 | |       | | <-nlsJacTestATol=value> or <-nlsJacTestATol value>
|                 | |       | |   [double] value specifies the absolute tolerance for the Jacobian derivative test.
|                 | |       | | <-nlsJacTestRTol=value> or <-nlsJacTestRTol value>
|                 | |       | |   [double] value specifies the relative tolerance for the Jacobian derivative test.
|                 | |       | | <-noemit>
|                 | |       | |   do not emit any results to the result file
|                 | |       | | <-noEquidistantTimeGrid>
|                 | |       | |   stores results not in equidistant time grid as given by stepSize or numberOfIntervals, instead the variable step size of dassl or ida integrator.
|                 | |       | | <-noEquidistantOutputFrequency=value> or <-noEquidistantOutputFrequency value>
|                 | |       | |   value controls the output frequency in noEquidistantTimeGrid mode
|                 | |       | | <-noEquidistantOutputTime=value> or <-noEquidistantOutputTime value>
|                 | |       | |   value controls the output time point in noEquidistantOutputTime mode
|                 | |       | | <-noEventEmit>
|                 | |       | |   do not emit event points to the result file
|                 | |       | | <-noRestart>
|                 | |       | |   disables the restart of the integration method after an event is performed, used by the methods: dassl, ida, gbode
|                 | |       | | <-noRootFinding>
|                 | |       | |   disables the internal root finding procedure of methods: dassl and ida.
|                 | |       | | <-noScaling>
|                 | |       | |   disables scaling for the variables and the residuals in the algebraic nonlinear solver KINSOL.
|                 | |       | | <-noSuppressAlg>
|                 | |       | |   flag to not suppress algebraic variables in the local error test of ida solver in daeMode
|                 | |       | | <-optDebugJac=value> or <-optDebugJac value>
|                 | |       | |   value specifies the number of iter from the dyn. optimization, which will be debug, creating *csv and *py file
|                 | |       | | <-optimizerNP=value> or <-optimizerNP value>
|                 | |       | |   value specifies the number of points in a subinterval
|                 | |       | | <-optimizerTimeGrid=value> or <-optimizerTimeGrid value>
|                 | |       | |   value specifies external file with time points.
|                 | |       | | <-output=value> or <-output value>
|                 | |       | |   output the variables a, b and c at the end of the simulation to the standard output
|                 | |       | | <-outputFormat=value> or <-outputFormat value>
|                 | |       | |   changes the output format (mat/csv/plt/empty)
|                 | |       | | <-outputPath=value> or <-outputPath value>
|                 | |       | |   value specifies a path for writing the output files i.e., model_res.mat, model_prof.intdata, model_prof.realdata etc.
|                 | |       | | <-override=value> or <-override value>
|                 | |       | |   override the variables in the XML setup file
|                 | |       | | <-overrideFile=value> or <-overrideFile value>
|                 | |       | |   will override the variables in the XML setup file with the values from the file
|                 | |       | | <-port=value> or <-port value>
|                 | |       | |   value specifies the port for simulation status (default disabled)
|                 | |       | | <-r=value> or <-r value>
|                 | |       | |   value specifies a new result file than the default Model_res.mat
|                 | |       | | <-reconcile>
|                 | |       | |   Run the Data Reconciliation numerical computation algorithm for constrained equations
|                 | |       | | <-reconcileBoundaryConditions>
|                 | |       | |   Run the Data Reconciliation numerical computation algorithm for boundary condition equations
|                 | |       | | <-reconcileState>
|                 | |       | |   Run the State Estimation numerical computation algorithm for constrained equations
|                 | |       | | <-gbm=value> or <-gbm value>
|                 | |       | |   Value specifies the chosen solver of solver gbode (single-rate, slow states integrator)
|                 | |       | | <-gbctrl=value> or <-gbctrl value>
|                 | |       | |   Step size control of solver gbode (single-rate, slow states integrator)
|                 | |       | | <-gbctrl_evnt_reinit>
|                 | |       | |   Reset step size using standard inital step size selection after an event (default false)
|                 | |       | | <-gbctrl_filter=value> or <-gbctrl_filter value>
|                 | |       | |   Applies exponential smoothing to the step size factor; gbctrl_filter = 0 yields constant step size, gbctrl_filter = 1 uses full adaptation without averaging.
|                 | |       | | <-gbctrl_fhr>
|                 | |       | |   Applies adaptive damping to the step size factor using Führer’s approach, scaling it by h_fac *= (h_n / h_n1)^gamma to penalize repeated rejections or reward successful step acceptance.
|                 | |       | | <-gberr=value> or <-gberr value>
|                 | |       | |   Error estimation method for solver gbode (single-rate, slow states integrator).
|                 | |       | | <-gbint=value> or <-gbint value>
|                 | |       | |   Interpolation method of solver gbode (single-rate, slow states integrator)
|                 | |       | | <-gbnls=value> or <-gbnls value>
|                 | |       | |   Non-linear solver method of solver gbode (single-rate, slow states integrator)
|                 | |       | | <-gbnls_internal_damping=value> or <-gbnls_internal_damping value>
|                 | |       | |   Value specifies damping applied to the estimated convergence rate in the first Newton iteration (0 <= value <= 1). Only valid for -gbnls=internal.
|                 | |       | | <-gbnls_internal_jackeep=value> or <-gbnls_internal_jackeep value>
|                 | |       | |   Value specifies how often the ODE Jacobian is recalculated (0 <= value < 1). Only valid for -gbnls=internal.
|                 | |       | | <-gbfm=value> or <-gbfm value>
|                 | |       | |   Value specifies the chosen solver of solver gbode (multi-rate, fast states integrator)
|                 | |       | | <-gbfctrl=value> or <-gbfctrl value>
|                 | |       | |   Step size control of solver gbode (multi-rate, fast states integrator)
|                 | |       | | <-gbferr=value> or <-gbferr value>
|                 | |       | |   Error estimation method for gbode solver (multi-rate, fast states integrator).
|                 | |       | | <-gbfint=value> or <-gbfint value>
|                 | |       | |   Interpolation method of solver gbode (multi-rate, fast states integrator)
|                 | |       | | <-gbfnls=value> or <-gbfnls value>
|                 | |       | |   Non-linear solver method of solver gbode (multi-rate, fast states integrator)
|                 | |       | | <-gbratio=value> or <-gbratio value>
|                 | |       | |   Define percentage of states for the fast states selection of solver gbode
|                 | |       | | <-rt=value> or <-rt value>
|                 | |       | |   value specifies the scaling factor for real-time synchronization (0 disables)
|                 | |       | | <-s=value> or <-s value>
|                 | |       | |   value specifies the integration method
|                 | |       | | <-saveInitialGuess_system=value> or <-saveInitialGuess_system value>
|                 | |       | |   [string (.mat file), uint (NLS index)] debug flag that performs standard initialization until the specified system is reached, computes only the torn part and saves the results obtained so far to a .mat file
|                 | |       | | <-single>
|                 | |       | |   output in single precision
|                 | |       | | <-steps>
|                 | |       | |   dumps the number of integration steps into the result file
|                 | |       | | <-startTime=value> or <-startTime value>
|                 | |       | |   sets startTime
|                 | |       | | <-steadyState>
|                 | |       | |   aborts if steady state is reached
|                 | |       | | <-steadyStateTol=value> or <-steadyStateTol value>
|                 | |       | |   [double (default 1e-3)] This relative tolerance is used to detect steady state.
|                 | |       | | <-stepSize=value> or <-stepSize value>
|                 | |       | |   sets stepSize
|                 | |       | | <-stopAtSystem=value> or <-stopAtSystem value>
|                 | |       | |   [uint (NLS index)] performs standard initialization until the specified system is reached, then aborts the simulation.
|                 | |       | | <-stopTime=value> or <-stopTime value>
|                 | |       | |   sets stopTime
|                 | |       | | <-svdCount=value> or <-svdCount value>
|                 | |       | |   [int (default 0)] Number of extremal singular values and vectors computed for LOG_NLS_SVD (0 disables).
|                 | |       | | <-svdSigma=value> or <-svdSigma value>
|                 | |       | |   [double (default 1e-8, > 0)] Estimated smallest singular value for the preconditioner in SVD analysis.
|                 | |       | | <-sx=value> or <-sx value>
|                 | |       | |   value specifies a csv-file with inputs as covariance matrix Sx for DataReconciliation
|                 | |       | | <-tolerance=value> or <-tolerance value>
|                 | |       | |   sets tolerance
|                 | |       | | <-keepHessian=value> or <-keepHessian value>
|                 | |       | |   value specifies the number of steps, which keep hessian matrix constant
|                 | |       | | <-variableFilter=value> or <-variableFilter value>
|                 | |       | |   sets variableFilter
|                 | |       | | <-w>
|                 | |       | |   shows all warnings even if a related log-stream is inactive
|                 | |       | | <-parmodNumThreads=value> or <-parmodNumThreads value>
|                 | |       | |   [int default: 0] value specifies the number of threads for simulation using parmodauto. If not specified (or is 0) it will use the systems max number of threads. Note that this option is ignored if the model is not compiled with--parmodauto
|                 | |       | | <-parmodScheduler=value> or <-parmodScheduler value>
|                 | |       | |   value selects the parmodauto scheduler: flow (default) or level
|                 | |       | | <-parmodClustering=value> or <-parmodClustering value>
|                 | |       | |   value selects the parmodauto clustering strategy: default, fixed_width_min_height or none
|                 | |       | | <-parmodClustersPerLevel=value> or <-parmodClustersPerLevel value>
|                 | |       | |   [int] value sets the maximum number of clusters per level for the default clustering
|                 | |       | | <-parmodDumpTaskGraph=value> or <-parmodDumpTaskGraph value>
|                 | |       | |   value specifies a json file to which the parmodauto task graph and clustering are exported
|                 | |       | | <-parmodImportClustering=value> or <-parmodImportClustering value>
|                 | |       | |   value specifies a json file from which a parmodauto clustering is imported instead of computing one
|                 | |       | | <-parmodDumpStages=value> or <-parmodDumpStages value>
|                 | |       | |   value specifies a file name prefix to which the parmodauto task graph and clustering are exported before and after each clustering optimization
```
