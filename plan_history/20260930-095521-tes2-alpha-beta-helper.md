# Add TES2 Alpha/Beta Evaluation Helper

## Summary

Add `TESModel.get_alpha_beta(T=None, I=None)` in `python/pymodelica.py`. It
calculates the local logarithmic resistance derivatives of `libTES.TES2`:

\[
\alpha=\frac{T}{R}\frac{\partial R}{\partial T},\qquad
\beta=\frac{I}{R}\frac{\partial R}{\partial I}
\]

The method returns `(alpha, beta)` and defaults omitted `T` or `I`
independently to the final `c1.T` or `c1.i` simulation-result value.

## Implementation Changes

- Read `Tc`, `I0`, `alpha0`, `beta0`, and `p0` from the final `c1.*`
  simulation-result values.
- Reproduce the exact TES2 resistance argument, including its `abs(I)`
  dependence and denominator `p0 + alpha0 + beta0`.
- Compute analytical logarithmic derivatives using the transition factor
  `1 - tanh(x)`, avoiding numerical differentiation.
- Accept scalar or NumPy-compatible `T`/`I` inputs with normal broadcasting;
  return matching scalar/array values in the tuple.
- Add a Google-style docstring and validation for missing/non-finite values
  and singular parameter combinations.
- Do not modify the Modelica equation or existing noise/impedance callers.

Before implementation, archive this complete plan as
`plan_history/20260930-095521-tes2-alpha-beta-helper.md` and add its dated
entry to `plan_history/README.md`.

## Test Plan

- Run `python -m py_compile python/pymodelica.py`.
- Test explicit `T`/`I` values against independent finite-difference
  derivatives of the TES2 resistance equation.
- Verify omitted `T`, omitted `I`, and both omitted use the final
  simulation-result samples.
- Verify negative-current symmetry and array/broadcasting behavior.
- Verify invalid parameter combinations raise clear `ValueError`s.
- Run `git diff --check`, preserving unrelated existing worktree changes.

## Assumptions

- The TES2 instance represented by `TESModel` is `c1`, consistent with
  existing `TESModel` methods.
- Beta uses \(I\,\partial R/\partial I\,/R\), which remains well-defined for
  the model's `abs(I)` dependence away from singular points.
- The helper is additive; existing `get_noise()` behavior will continue
  using its current inputs until explicitly changed.
