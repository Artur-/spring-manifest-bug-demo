#!/bin/bash

# Script to compile and run the test application demonstrating the
# PathMatchingResourcePatternResolver bug with absolute paths in manifests.

set -e

echo "==================================================================="
echo "Spring Framework PathMatchingResourcePatternResolver Bug Demo"
echo "==================================================================="
echo

# Check if classpath.jar exists
if [ ! -f "classpath.jar" ]; then
    echo "ERROR: classpath.jar not found!"
    echo "Please run ./create-classpath-jar.sh first"
    exit 1
fi

echo "Step 1: Compiling TestApp.java..."
echo

# Find spring-core JAR for compilation
MAVEN_REPO="$HOME/.m2/repository"
SPRING_CORE=$(find "$MAVEN_REPO/org/springframework/spring-core" -name "spring-core-*.jar" 2>/dev/null | head -1)

if [ -z "$SPRING_CORE" ]; then
    echo "ERROR: spring-core JAR not found for compilation"
    echo "Please run: mvn dependency:resolve"
    exit 1
fi

# Compile
javac -cp "$SPRING_CORE" TestApp.java

if [ ! -f "TestApp.class" ]; then
    echo "ERROR: Compilation failed"
    exit 1
fi

echo "✓ Compilation successful"
echo

echo "Step 2: Creating TestApp.jar with Main-Class and Class-Path manifest..."
echo

# Create a manifest that references classpath.jar
mkdir -p manifest-tmp/META-INF
cat > manifest-tmp/META-INF/MANIFEST.MF << 'EOF'
Manifest-Version: 1.0
Main-Class: TestApp
Class-Path: classpath.jar

EOF

# Create TestApp.jar
jar cfm TestApp.jar manifest-tmp/META-INF/MANIFEST.MF TestApp.class
rm -rf manifest-tmp

echo "✓ Created TestApp.jar"
echo

echo "Step 3: Running test using java -jar (simulates Gradle bootRun)..."
echo "Command: java -jar TestApp.jar"
echo
echo "This simulates how Gradle runs apps on Windows with long classpaths:"
echo "- Gradle creates a classpath JAR with absolute paths in manifest"
echo "- Gradle creates an app JAR that references the classpath JAR"
echo "- Java processes the manifest chain and loads all dependencies"
echo
echo "-------------------------------------------------------------------"

# Run the test using -jar so Java will process the Class-Path manifest
java -jar TestApp.jar

EXIT_CODE=$?

echo "-------------------------------------------------------------------"
echo

if [ $EXIT_CODE -eq 1 ]; then
    echo "✓ BUG SUCCESSFULLY DEMONSTRATED!"
    echo
    echo "The test confirmed that PathMatchingResourcePatternResolver"
    echo "rejects absolute paths in JAR manifest Class-Path entries."
elif [ $EXIT_CODE -eq 0 ]; then
    echo "⚠ Bug not reproduced in this environment"
    echo
    echo "This might mean:"
    echo "  - The classpath JAR doesn't have absolute paths"
    echo "  - The Spring version has the bug fixed"
    echo "  - Something else is different from the Windows/Gradle scenario"
else
    echo "✗ Test failed with unexpected exit code: $EXIT_CODE"
fi

echo
