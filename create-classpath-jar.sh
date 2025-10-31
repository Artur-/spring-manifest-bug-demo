#!/bin/bash

# Script to create a classpath JAR with absolute paths in the manifest,
# simulating what Gradle does on Windows with long classpaths.

set -e

echo "Creating classpath JAR with absolute paths in manifest..."
echo

# Find Maven local repository
if [ -d "$HOME/.m2/repository" ]; then
    MAVEN_REPO="$HOME/.m2/repository"
elif [ -d "$HOME/.m2/repo" ]; then
    MAVEN_REPO="$HOME/.m2/repo"
else
    echo "ERROR: Maven local repository not found at $HOME/.m2/repository"
    echo "Please run: mvn dependency:resolve first"
    exit 1
fi

echo "Maven repository: $MAVEN_REPO"
echo

# Find Spring JARs (we need spring-core and spring-jcl at minimum)
SPRING_JARS=()

# Look for spring-core
SPRING_CORE=$(find "$MAVEN_REPO/org/springframework/spring-core" -name "spring-core-*.jar" 2>/dev/null | head -1)
if [ -n "$SPRING_CORE" ]; then
    SPRING_JARS+=("$SPRING_CORE")
    echo "Found: $SPRING_CORE"
fi

# Look for spring-jcl (required dependency of spring-core)
SPRING_JCL=$(find "$MAVEN_REPO/org/springframework/spring-jcl" -name "spring-jcl-*.jar" 2>/dev/null | head -1)
if [ -n "$SPRING_JCL" ]; then
    SPRING_JARS+=("$SPRING_JCL")
    echo "Found: $SPRING_JCL"
fi

# Look for spring-beans
SPRING_BEANS=$(find "$MAVEN_REPO/org/springframework/spring-beans" -name "spring-beans-*.jar" 2>/dev/null | head -1)
if [ -n "$SPRING_BEANS" ]; then
    SPRING_JARS+=("$SPRING_BEANS")
    echo "Found: $SPRING_BEANS"
fi

# Look for spring-context
SPRING_CONTEXT=$(find "$MAVEN_REPO/org/springframework/spring-context" -name "spring-context-*.jar" 2>/dev/null | head -1)
if [ -n "$SPRING_CONTEXT" ]; then
    SPRING_JARS+=("$SPRING_CONTEXT")
    echo "Found: $SPRING_CONTEXT"
fi

if [ ${#SPRING_JARS[@]} -eq 0 ]; then
    echo
    echo "ERROR: No Spring JARs found in $MAVEN_REPO"
    echo "Please install dependencies first:"
    echo "  mvn dependency:resolve"
    exit 1
fi

echo
echo "Found ${#SPRING_JARS[@]} Spring JARs"
echo

# Create manifest with ABSOLUTE paths (this is the key to reproducing the bug!)
MANIFEST_DIR="manifest-tmp"
mkdir -p "$MANIFEST_DIR/META-INF"

# Build the Class-Path value with all JARs space-separated
CLASS_PATH_VALUE=""
for jar in "${SPRING_JARS[@]}"; do
    # Get absolute path
    ABS_PATH=$(cd "$(dirname "$jar")" && pwd)/$(basename "$jar")
    # Convert to use forward slashes (for cross-platform consistency)
    ABS_PATH_NORMALIZED=$(echo "$ABS_PATH" | sed 's|\\|/|g')
    if [ -z "$CLASS_PATH_VALUE" ]; then
        CLASS_PATH_VALUE="$ABS_PATH_NORMALIZED"
    else
        CLASS_PATH_VALUE="$CLASS_PATH_VALUE $ABS_PATH_NORMALIZED"
    fi
done

# Write manifest - the jar tool will handle line wrapping automatically
echo "Manifest-Version: 1.0" > "$MANIFEST_DIR/META-INF/MANIFEST.MF"
echo "Class-Path: $CLASS_PATH_VALUE" >> "$MANIFEST_DIR/META-INF/MANIFEST.MF"

echo "Generated manifest:"
echo "===================="
cat "$MANIFEST_DIR/META-INF/MANIFEST.MF"
echo "===================="
echo

# Create the classpath JAR
jar cfm classpath.jar "$MANIFEST_DIR/META-INF/MANIFEST.MF"

# Cleanup
rm -rf "$MANIFEST_DIR"

echo "✓ Created classpath.jar with absolute paths in manifest"
echo
echo "To verify the manifest, run:"
echo "  jar xf classpath.jar META-INF/MANIFEST.MF && cat META-INF/MANIFEST.MF"
echo
