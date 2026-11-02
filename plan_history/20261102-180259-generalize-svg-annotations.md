# Generalize SVG Simulation Annotations

## Summary

Fix `mod_svg()` so `analysis_LMO_v1.ipynb` annotates its diagram correctly. The current failure has two causes:

- Replacements run only when `system_name == "System_LMO"`.
- Raw replacements depend on whitespace present in the original SVG but absent from `System_LMO_v1.svg`.

## Implementation Changes

- Parse SVG text nodes structurally instead of matching serialized XML whitespace.
- Automatically recognize arbitrary numbered components:
  - `K=KN` → effective conductance from `gN.G`, falling back to `GN`.
  - `m=mN` → heat capacity from `cN.C`, falling back to `CN`.
  - `cN` → append temperature from `cN.T`, falling back to `TN`.
  - Preserve existing TES, bath, and bias-resistance annotations and scaling.
- Extend the public API with:
  - `sample_index=-1` for selecting the simulation sample.
  - `replacements=None`, an exact-text mapping for caller overrides and nonstandard diagrams.
  - Continued acceptance of `system_name` for backward compatibility, without using it to gate annotation.
- Support both scalar and array-like result values. Consolidate missing or invalid recognized variables into one warning while preserving their original SVG labels.
- Keep the existing return behavior: notebook HTML when `display=True`, otherwise `None`.
- Update the v1 notebook annotation cell to use automatic mode and document the generalized behavior. Preserve unrelated notebook content, outputs, calibration values, and model annotations.
- Add Google-style documentation and focused explanatory comments.

## Test Plan

- Add temporary SVG fixtures covering legacy labels with trailing spaces and v1 labels without them.
- Verify automatic annotation of multi-digit components such as `c12`, `c13`, `g17`, and `g18`.
- Test direct-name and alias fallbacks, scalar values, non-final `sample_index`, custom replacement precedence, and HTML/non-display behavior.
- Confirm missing data emits one warning and leaves unmatched labels unchanged.
- Run the Python unit suite.
- Load the existing `System_LMO_v1` equilibrium MAT result, annotate its real SVG, and verify recognized placeholders are replaced without rerunning the full simulation.

## Assumptions

- The built-in convention remains focused on TES diagrams using `cN`, `gN`, `mN`, and `KN` naming.
- Numeric formatting remains at three significant digits with the existing temperature and resistance scaling.
- Custom replacements are applied before built-in rules, allowing callers to override automatic annotations.
