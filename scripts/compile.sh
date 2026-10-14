#!/usr/bin/env bash

# Compile one Modelica source file with the repository's standard settings.
#
# Args:
#   model_file: Modelica filename or path. Bare filenames are searched under
#     the repository's models/ directory.
#
# Environment:
#   Requires the OpenModelica compiler, omc, on PATH.
#
# Outputs:
#   Build artifacts are written to the repository's build/ directory using an
#   executable prefix derived from the Modelica filename.
#
# Exit status:
#   Returns omc's status, or exits with status 2 for invalid arguments/files.

set -euo pipefail

usage() {
  echo "Usage: $0 MODEL_FILE" >&2
  echo "  MODEL_FILE may be a path or a filename under models/." >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
model_arg=$1

if [[ -f "${model_arg}" ]]; then
  model_path=$(cd -- "$(dirname -- "${model_arg}")" && pwd)/$(basename -- "${model_arg}")
elif [[ -f "${repo_root}/models/${model_arg}" ]]; then
  model_path=${repo_root}/models/${model_arg}
else
  echo "Modelica file not found: ${model_arg}" >&2
  exit 2
fi

if [[ ${model_path##*.} != "mo" ]]; then
  echo "Expected a .mo Modelica file: ${model_path}" >&2
  exit 2
fi

model_class=$(basename -- "${model_path}" .mo)
if [[ ! ${model_class} =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  echo "Could not derive a valid Modelica class name from: ${model_path}" >&2
  exit 2
fi

build_dir=${repo_root}/build
mkdir -p "${build_dir}"
mos_file=$(mktemp "${TMPDIR:-/tmp}/compile_model.XXXXXX.mos")
trap 'rm -f -- "${mos_file}"' EXIT

cat >"${mos_file}" <<EOF
system("mkdir -p ${build_dir}");
cd("${build_dir}");

loadModel(Modelica, {"4.1.0"});
loadFile("${repo_root}/libTES.mo");
loadFile("${model_path}");

setCommandLineOptions("--linearizationDumpLanguage=python --tearingStrictness=veryStrict");

buildModel(
  ${model_class},
  outputFormat = "mat",
  fileNamePrefix = "${model_class}_exe"
);
EOF

omc "${mos_file}"
