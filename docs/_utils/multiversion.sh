#! /bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$REPO_ROOT" && sphinx-multiversion docs/source docs/_build/dirhtml \
    --pre-build "bash -c \"(find . -mindepth 2 -name README.md -execdir mv '{}' index.md ';'; find . -mindepth 2 -name README.rst -execdir mv '{}' index.rst ';')\"" \
    --post-build "$REPO_ROOT/docs/_utils/multiversion-javadoc.sh"
