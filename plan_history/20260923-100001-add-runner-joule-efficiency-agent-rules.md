# Add Standalone Simulation, Joule-Efficiency Analysis, and Agent Governance

## Summary

Implement three coordinated changes:

- Add a module-level `run_model()` in `python/pymodelica.py`, refactoring `TESMCMCFit.run_model()` to reuse it.
- Add a `TESModel` helper for Joule-heating correction and phonon energy collection efficiency for both linear and nonlinear simulations.
- Update `AGENTS.md` with Google-style documentation and plan-history requirements, creating timestamped plan archives plus a cumulative brief index.

## Implementation Changes

- Add standalone `run_model()` with keyword arguments covering the existing runner settings, including executable/build paths, override file, parameter overrides, simulation settings, result filenames, extra arguments, and run-directory retention.
- Merge dictionary overrides into the copied override file, replacing matching entries and appending new ones. Return the existing result structure; standalone failures raise, while the MCMC wrapper preserves its current best-effort behavior.
- Add Google-style docstrings to new or modified Python APIs.
- Add a `TESModel` efficiency helper returning deposited energy, integrated perturbative Joule energy, collected energy, and collection efficiency.
- Define efficiency as `(deposited energy + integrated Joule-energy perturbation) / deposited energy`.
- Use first-order `delta P_Joule = V0 * delta I + I0 * delta V` and an analytic state-transition integral for linear models.
- Use complete nonlinear `c1.v`/`c1.i` waveforms, baseline subtraction, and numerical integration for nonlinear models.
- Update `AGENTS.md` with Google-style documentation and plan-history rules. Maintain timestamped full plans and `plan_history/README.md` as the cumulative brief index.

## Test Plan

- Test override merging, standalone runner argument construction, result paths, retention, and failure handling.
- Verify `TESMCMCFit.run_model()` compatibility.
- Test linear efficiency against an analytically solvable state-space model.
- Test nonlinear efficiency against synthetic waveforms and validation failures.
- Run Python syntax/import checks and available OpenModelica checks.

## Assumptions

- `AGENTS.md` is the repository instruction file to update.
- Existing unrelated user changes are preserved.
- Nonlinear defaults are `c1.v` and `c1.i`; baseline defaults to the first sample.
- Linear efficiency uses first-order perturbations; nonlinear efficiency uses the full `v*i` waveform.
