# TES Thermal Model

Modelica models for thermal and electrothermal simulations of Transition Edge Sensor (TES) detectors. The repository contains reusable component models and example systems for studying TES biasing, Joule heating, thermal links, heat capacities, and detector response to pulsed energy input.

## Repository Contents

- `TES.mo` - TES model with electrical pins, a thermal port, tanh transition resistance, Joule heating, and constant heat capacity.
- `TES2.mo` - TES variant with temperature-dependent heat capacity terms.
- `HeatCapacitorPoly.mo` - thermal mass with polynomial specific heat capacity.
- `ThermlConductanceExp.mo` - nonlinear thermal conductance model `ThermlConductanceN`, using `Q_flow = K * (T_a^n - T_b^n)`.
- `System_1block.mo` - one-block TES system using nonlinear thermal conductance.
- `System_1block_linearG.mo` - one-block TES system using Modelica's linear `ThermalConductor`.
- `System_LMO.mo` - larger LMO detector thermal network with multiple heat-capacity nodes and conductance links.
- `System_LMO.svg` - exported diagram for the LMO system.

All Modelica files currently live at the repository root. There is no package wrapper or automated test directory yet.

## Requirements

Use OpenModelica/OMEdit with the Modelica Standard Library. The example systems declare:

```modelica
uses(Modelica(version = "4.1.0"))
```

Install OpenModelica if you want to check or simulate from the command line with `omc`.

## Quick Start

Open a system model in OMEdit, then run **Check Model** before simulating:

1. Start with `System_1block.mo` for the simplest nonlinear TES thermal example.
2. Use `System_1block_linearG.mo` to compare against a linear thermal conductance.
3. Use `System_LMO.mo` for the multi-node detector network.

Typical command-line checks, when `omc` is available:

```sh
omc +s System_1block.mo
omc +s System_1block_linearG.mo
omc +s System_LMO.mo
```

The system models include experiment annotations for start time, stop time, tolerance, interval, solver flags, and OpenModelica command-line options.

## Modeling Notes

`TES.mo` computes resistance as:

```modelica
R = Rn/2 * (1. + tanh((T - Tc) * alpha0/Tc));
```

The resulting Joule power is coupled into the thermal balance:

```modelica
C * der(T) = P_Joule + heatPort.Q_flow;
```

`HeatCapacitorPoly.mo` supports temperature-dependent heat capacity through a polynomial expansion around `T0`. `ThermlConductanceN` models power-law thermal transport between two heat ports.

## Current Status



## Contributing

Keep model filenames aligned with model names when adding new components. Prefer `Modelica.Units.SI` types for physical quantities, preserve existing experiment annotations, and document parameter choices that come from detector calibration or measurement data.
