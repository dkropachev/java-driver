#!/bin/bash
set -euo pipefail

# Install dependencies
mvn install -DskipTests -Dmaven.javadoc.skip=true -T 1C

# Define output folder
OUTPUT_DIR="docs/_build/dirhtml/api"
if [[ "${SPHINX_MULTIVERSION_OUTPUTDIR:-}" != "" ]]; then
    OUTPUT_DIR="$SPHINX_MULTIVERSION_OUTPUTDIR/api"
    echo "HTML_OUTPUT = $OUTPUT_DIR" >> doxyfile
fi

# Generate javadoc
mvn javadoc:javadoc -T 1C
if [[ -d "$OUTPUT_DIR" ]]; then
    rm -r "$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"
mv -f core/target/site/apidocs/* "$OUTPUT_DIR"
