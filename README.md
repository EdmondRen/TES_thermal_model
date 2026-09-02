# TES Thermal Model

Modelica models for thermal and electrothermal simulations of Transition Edge Sensor (TES) detectors. The repository contains a reusable component library plus system-level examples for TES biasing, Joule heating, nonlinear thermal links, temperature-dependent heat capacities, and detector response to pulsed energy input.

## Repository Contents

- `libTES.mo` - local Modelica package containing reusable TES thermal-model components.
- `System_1block.mo` - one-block TES system using `libTES.TES2` and nonlinear thermal conductance.
- `System_1block_linearG.mo` - one-block TES system using `libTES.TES` and Modelica's linear `ThermalConductor`.
- `System_LMO.mo` - larger LMO detector thermal network with multiple heat-capacity nodes and conductance links.
- `/parameters` - reference parameter set.
- `/python` - python scripts and notebooks for running simulations and analyzing results
- `/script` - `omc` scripts to run and build models

All Modelica source files currently live at the repository root. The reusable components are organized inside `libTES.mo`; the system models instantiate them with qualified names such as `libTES.TES2` and `libTES.ThermlConductanceN`.


## Requirements

Use OpenModelica/OMEdit with the Modelica Standard Library. Follow the installation guide on https://openmodelica.org/. If OpenModelica reports that the Modelica package is missing, install Modelica 4.1.0 from OMEdit's package manager or through an OpenModelica script.

## Running In OMEdit (GUI)

Load the local library before loading any system model:

1. Open OMEdit.
2. Select **File > Open Model/Library File(s)** and open `libTES.mo` and the system model you want to run, for example `System_1block.mo`, `System_1block_linearG.mo`, or `System_LMO.mo`.
5. Click **Check Model** and fix any reported errors before simulating.
6. Click **Simulate** to run with the experiment settings stored in the model annotation.
7. Open the plotting view and inspect variables such as TES temperature, current, Joule power, heat-capacity values, or conductance outputs.

The model annotations store simulation settings so they travel with the files.

### OMEdit Troubleshooting

- If you see `Class libTES... not found`, load `libTES.mo` first, then reload the system model.
- If you see missing `Modelica.Thermal`, `Modelica.Electrical`, or other standard-library classes, install or load Modelica 4.1.0.
- If OMEdit reports a parser error around `addClassAnnotation`, restart OMEdit or clear the scripting input/session, then reload `libTES.mo` and the target system model.
- If a parameter is reported as having neither a value nor a start value, check the parameter declarations in the system model and any parameter file you are using.

## Running From Command Line

Because the system models depend on the local `libTES` package, load `libTES.mo` before checking or simulating a system model. A direct command such as `omc System_LMO.mo` may fail with `Class libTES... not found` if the library is not already loaded.

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

## Modeling Notes


`libTES.mo` defines the reusable models used by the system examples:

- `libTES.TES` - TES component with electrical pins, one thermal port, tanh transition resistance, Joule heating, and constant heat capacity.
- `libTES.TES2` - Almost the same as `TES` but with temperature dependent heat capacity.


```modelica
R = Rn/2 * (1. + tanh((T - Tc) * alpha0/Tc));
```

The resulting Joule power is coupled into the thermal balance. For constant heat capacity:

```modelica
C * der(T) = P_Joule + heatPort.Q_flow;
```

For temperature-dependent heat capacity in `libTES.TES2`:

```modelica
cp = a1*T + a3*T^3;
m * cp * der(T) = P_Joule + heatPort.Q_flow;
```

- `libTES.ThermlConductanceN` - nonlinear thermal conductance between two heat ports:

```modelica
Q_flow = K * (port_a.T^n - port_b.T^n);
```

- `libTES.HeatCapacitorPoly` - thermal mass with polynomial specific heat capacity:

```modelica
cp = a0 + a1*T + a3*T^3 + a5*T^5;
```


`System_LMO.mo` exposes summary result variables named `A_C*`, `A_T*`, and `A_G*` for selected heat capacities, temperatures, and thermal conductances.

## Modeled Systems

### LMO

<img src="System_LMO.svg" width="700" alt="LMO system thermal model" style="background-color: #ffffff; padding: 16px; border-radius: 8px;">

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
|                 | |       | |   value specifies lvl for a warm start in ipopt: 1,2,3,...
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