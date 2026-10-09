# Complete the Fake-Data MCMC Example

## Summary

Finish `analysis_mcmc.ipynb` as a reproducible example that smears synthetic bias-power, pulse-current, and complex-impedance observations, fits `TES_alpha` and `K1`, summarizes their recovery, and plots a posterior-predictive result.

## Implementation Changes

- Isolate every MCMC simulation in a copied temporary run directory, fix linearized-model placement and OpenModelica argument construction, and support quiet execution.
- Generate deterministic Gaussian fake measurements with explicit uncertainty scales and observation grids.
- Use the truth-run override file and matching simulation settings in `TESMCMCFit`.
- Run a short 8-walker, 100-step chain and add trace, posterior, summary, and best-fit observable plots.

## Test Plan

- Test isolated MCMC runner calls, generated linearized-model placement, and separate timestep/tolerance arguments.
- Run unit tests, Python compilation, notebook JSON validation, and one end-to-end truth likelihood evaluation.
- Leave the full notebook chain for interactive execution.

## Assumptions

- Fake errors are independent Gaussian values for demonstration purposes.
- Existing compiled `System_2block_exe` artifacts and `emcee` are available.
- Matplotlib is used for posterior plots because `corner` is not installed.
