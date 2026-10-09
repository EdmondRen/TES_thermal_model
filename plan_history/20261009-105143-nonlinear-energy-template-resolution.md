# Correct Nonlinear Pulse Energy Resolution

## Summary

Replace the periodogram-based nonlinear response estimate with a reusable, correctly normalized single-pulse energy template. Restrict the energy-resolution calculation to frequencies supported by the nonlinear simulation.

## Key Changes

- Add `TESModel.get_nonlinear_energy_template()` to baseline-subtract, deduplicate, uniformly resample, and Fourier-transform a nonlinear current pulse.
- Return the one-sided frequency grid and complex `dt * rfft(delta_current) / deposited_energy` response.
- Update `analysis_mcmc.ipynb` to compare linear and nonlinear response magnitudes and integrate resolution only from the first positive FFT bin through Nyquist.
- Document that the result is a finite-energy secant template rather than a unique nonlinear transfer function.

## Test Plan

- Test transform normalization, baseline handling, duplicate/event timestamps, and invalid inputs.
- Verify the saved two-block example produces a plausible nonlinear resolution near 0.09 eV.
- Run unit tests, Python compilation, and notebook JSON validation.

## Assumptions

- Baseline noise is stationary and comes from the existing equilibrium noise model.
- The pulse record is long enough for the current to return to baseline.
- No window function is applied to the physical pulse template.
