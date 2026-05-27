#!/bin/bash
set -euo pipefail

# sphinx-multiversion runs post-build commands from each temporary historical
# branch checkout. This wrapper is intentionally kept on the current branch so
# old scylla-* checkouts can be adapted for the Java 11 docs build without
# backporting fixes or using Java 8. All mutations below affect only the
# temporary checkout created by sphinx-multiversion.

VERSION_NAME="${SPHINX_MULTIVERSION_NAME:-unknown}"

echo "Building Javadocs for ${VERSION_NAME} with Java:"
java -version

make_legacy_checkout_java11_compatible() {
    if [[ ! -f pom.xml ]] || ! grep -q "javac-with-errorprone" pom.xml; then
        return
    fi

    echo "Adapting legacy ${VERSION_NAME} checkout for a Java 11 docs build"

    perl -0pi -e 's/\n\s*<compilerId>javac-with-errorprone<\/compilerId>//g' pom.xml
    perl -0pi -e 's/\n\s*<forceJavacCompilerUse>true<\/forceJavacCompilerUse>//g' pom.xml
    perl -0pi -e 's/\n\s*<compilerArgs[^>]*>\s*<compilerArg>-Xep:FutureReturnValueIgnored:OFF<\/compilerArg>.*?<\/compilerArgs>//sg' pom.xml
    perl -0pi -e 's/\n\s*<dependencies>\s*<dependency>\s*<groupId>org\.codehaus\.plexus<\/groupId>\s*<artifactId>plexus-compiler-javac-errorprone<\/artifactId>.*?<\/dependencies>//sg' pom.xml
    perl -0pi -e 's/<failOnWarning>true<\/failOnWarning>/<failOnWarning>false<\/failOnWarning>/g' pom.xml
}

make_legacy_javadocs_java11_compatible() {
    if [[ -f docs/_utils/javadoc.sh ]] && ! grep -q -- "-Dmaven.javadoc.skip=true" docs/_utils/javadoc.sh; then
        perl -0pi -e 's/mvn install -DskipTests( -T 1C)?/mvn install -DskipTests -Dmaven.javadoc.skip=true$1/g' \
            docs/_utils/javadoc.sh
    fi

    if [[ -f pom.xml ]] && grep -q "<name>leaks</name>" pom.xml; then
        perl -0pi -e 's/<name>leaks<\/name>/<name>leaks-private-api<\/name>/g' pom.xml
    fi

    if [[ -f pom.xml ]]; then
        perl -0pi -e 's/\n\s*<links>\s*<link>.*?<\/links>//sg' pom.xml
    fi

    if [[ -f core/src/main/java/com/datastax/oss/driver/api/core/CqlIdentifier.java ]]; then
        perl -0pi -e 's/<table summary="examples">/<table>\n *   <caption>Examples<\/caption>/g' \
            core/src/main/java/com/datastax/oss/driver/api/core/CqlIdentifier.java
    fi
}

clean_javadoc_output() {
    local output_dir="docs/_build/dirhtml/api"

    if [[ -n "${SPHINX_MULTIVERSION_OUTPUTDIR:-}" ]]; then
        output_dir="${SPHINX_MULTIVERSION_OUTPUTDIR}/api"
    fi

    rm -rf "$output_dir"
}

make_legacy_checkout_java11_compatible
make_legacy_javadocs_java11_compatible
clean_javadoc_output

bash -e ./docs/_utils/javadoc.sh
