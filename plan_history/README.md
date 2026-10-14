# Plan History

Brief record of implementation plans for this repository.

| Timestamp | Plan | Summary |
| --- | --- | --- |
| 2026-09-23 10:00 EDT | [Standalone simulation, Joule efficiency, and agent rules](20260923-100001-add-runner-joule-efficiency-agent-rules.md) | Add a standalone OpenModelica runner with parameter overrides, linear/nonlinear Joule-energy collection helpers, Google-style documentation rules, and timestamped plan archiving. |
| 2026-09-29 11:24 EDT | [Generic Modelica compiler](20260929-112415-generic-modelica-compiler.md) | Add a filename-driven shell wrapper that compiles models with the existing Modelica, MAT output, Python linearization, and strict tearing settings. |
| 2026-09-30 09:55 EDT | [TES2 alpha/beta helper](20260930-095521-tes2-alpha-beta-helper.md) | Add an analytical `TESModel` helper for local TES2 logarithmic resistance derivatives with simulation-result defaults. |
| 2026-10-09 10:25 EDT | [Precomputed linear collection efficiency](20261009-102532-precomputed-linear-collection-efficiency.md) | Consume an existing linear impulse response, correct TES-voltage reconstruction, and update analysis examples and validation. |
| 2026-10-09 10:51 EDT | [Nonlinear energy-template resolution](20261009-105143-nonlinear-energy-template-resolution.md) | Replace the nonlinear pulse periodogram with a correctly normalized finite-energy template and supported frequency band. |
| 2026-10-09 11:05 EDT | [Fake-data MCMC example](20261009-110515-fake-data-mcmc-example.md) | Complete a reproducible three-observable toy fit and isolate MCMC simulation runs safely. |
