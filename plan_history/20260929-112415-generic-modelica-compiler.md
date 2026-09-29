# Add a Generic Modelica Compilation Wrapper

## Summary

Add `scripts/compile_model.sh` so any repository Modelica model can be compiled without editing a model-specific `.mos` file.

Usage:

```bash
scripts/compile_model.sh System_LMO.mo
scripts/compile_model.sh models/System_1block.mo
```

The Modelica class name and executable prefix will be derived from the `.mo` filename.

## Implementation Changes

- Create an executable Bash script with structured `Args`, `Environment`, and exit-status comments.
- Accept exactly one Modelica filename or path.
- Resolve files located directly under `models/` as well as explicitly provided paths.
- Derive the Modelica class name and executable prefix `<ModelClass>_exe` from the filename.
- Resolve the repository root from the script location so the command works from any working directory.
- Create/use `${repo_root}/build`.
- Generate a temporary `.mos` script containing the existing compiler settings: Modelica 4.1.0, `libTES.mo`, Python linearization, `veryStrict` tearing, MAT output, and `buildModel`.
- Clean up the temporary `.mos` file with a shell trap and propagate the `omc` exit status.
- Leave existing model-specific `.mos` files unchanged.

## Test Plan

- Run `bash -n scripts/compile_model.sh`.
- Verify invalid argument usage fails with useful messages.
- Compile `models/System_1block.mo` and `models/System_LMO.mo`.
- Verify invocation from outside the repository and generated executable prefixes.
- Run `git diff --check` and preserve existing user changes.

## Assumptions

- The top-level Modelica class name matches the `.mo` filename.
- `libTES.mo` is loaded for every compilation.
- Compilation artifacts belong in the existing repository `build/` directory.
