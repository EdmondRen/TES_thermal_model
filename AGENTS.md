# Repository Guidelines

## Project Structure & Module Organization

This repository contains standalone Modelica models for TES thermal simulations. Source files live at the repository root as `.mo` files. System-level examples include `System_1block.mo`, `System_1block_linearG.mo`, and `System_LMO.mo`. Reusable components include `TES.mo`, `TES2.mo`, `HeatCapacitorPoly.mo`, and `ThermlConductanceExp.mo`. `System_LMO.svg` is a generated diagram asset. There is no package directory or formal test tree yet; keep new files at the root unless a package structure is introduced deliberately.

## Build, Test, and Development Commands

Use OpenModelica or OMEdit for local development.

- `omc System_1block.mo` checks that the model parses and dependencies load.
- `omc +s System_1block.mo` runs a syntax-only check.
- `omc -s System_LMO.mo` is useful for catching translation issues in the larger system model.

If running from OMEdit, open the target `.mo` file and use Check Model before simulating. Record any solver settings or experiment changes in the model annotation so they travel with the file.

## Coding Style & Naming Conventions

Use Modelica conventions already present in the repo: two-space indentation inside models, `parameter` declarations before variables, then an `equation` section, then annotations. Prefer `Modelica.Units.SI` types for physical quantities. Use descriptive component names such as `HeatSource`, `TESBias`, `GoldPadTES`, and numbered conductance links like `G1`, `G2` only when they map to a documented physical topology. Keep model names and filenames aligned for new files.

## Testing Guidelines

There is no automated test suite. For every change, run an OpenModelica check on each affected model and at least one system model that uses it. For component changes, validate both parsing and simulation behavior with representative parameters. When adding a regression case, use a small system model named `System_<purpose>.mo` and document expected stop time, tolerance, and key output variables in comments or annotations.

## Commit & Pull Request Guidelines

The Git history currently contains only an initial commit, so use concise imperative commit messages, for example `Add polynomial heat capacity model` or `Fix TES resistance equation`. Pull requests should describe the physical or numerical change, list checked models and commands run, and include screenshots or exported plots when diagram layout or simulation results change.

## Agent-Specific Instructions

Do not overwrite generated diagrams or existing model annotations unless the task requires it. Preserve user calibration values, units, and solver settings when editing equations or component topology.
