# Rework Linear Collection Efficiency Around Precomputed Responses

## Summary

Replace the internal impulse solve with a required, precomputed physical response. Fix the tiny result caused by the notebook's mismatched default input and correct the TES-voltage calculation for parasitic resistance and inductance.

## Key Changes

- Change the public interface to `get_linear_phonon_energy_collection_efficiency(time, impulse_response, deposited_energy, voltage_key="c1.v", current_key="c1.i")`.
- Require an energy-scaled state response with shape `(len(time), nparams)` and remove the old input selector and integration-endpoint arguments.
- Integrate the supplied response and reconstruct the TES-voltage integral from the load-capacitor voltage, parasitic resistance, inductor, and TES current endpoints.
- Preserve the existing result dictionary and positive collection convention, and add validation for malformed or non-finite inputs.
- Update both analysis notebooks and the README for the new interface and corrected calculation.

## Test Plan

- Add regression tests covering the Joule-energy formula, parasitic resistance, inductive endpoint correction, absent parasitic resistance, and invalid inputs.
- Verify that no impulse solver is called.
- Check the saved two-block example and run Python compilation plus the unit tests.

## Assumptions

- Supplied responses are physical perturbations already scaled to `deposited_energy`.
- The first two normalized states remain `CL_v` and `L_i`.
- Collection efficiency is the negative integrated TES Joule-power perturbation divided by deposited energy.
- Existing unrelated working-tree changes are preserved.
