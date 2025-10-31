# Spring Framework PathMatchingResourcePatternResolver Bug Demo

Minimal reproducible example demonstrating a bug in Spring Framework's `PathMatchingResourcePatternResolver` that causes classpath scanning to fail when absolute paths are used in JAR manifest `Class-Path` entries.

This occurs when build tools (like Gradle on Windows) create classpath JARs with absolute paths to avoid exceeding command-line length limits.

## Quick Start

### Prerequisites

- Java 17 or later
- Maven 3.6 or later

### Running the Test

**On Linux/Mac:**

```bash
mvn dependency:resolve
chmod +x *.sh
./create-classpath-jar.sh
./run-test.sh
```

**On Windows:**

```cmd
mvn dependency:resolve
create-classpath-jar.bat
run-test.bat
```

## Expected Results

When the bug is present, you should see:

```
TEST 1: Scanning with empty root
Pattern: classpath*:**/*.class
----------------------------------------------------------------------
Found: 2 classes
❌ BUG DETECTED: Too few resources found!

TEST 2: Scanning with package prefix
Pattern: classpath*:org/**/*.class
----------------------------------------------------------------------
Found: 458 classes
✓ OK: Package prefix pattern works correctly

SUMMARY:
Empty root pattern: 2 resources
Package prefix pattern: 458 resources
BUG CONFIRMED!
```

The test demonstrates that:
- ❌ `classpath*:**/*.class` finds only ~2 classes (missing dependencies)
- ✅ `classpath*:org/**/*.class` finds ~450+ classes (works correctly)

This proves Spring is rejecting the absolute paths in the manifest `Class-Path` entries.

## What It Does

1. **create-classpath-jar**: Creates a JAR with `META-INF/MANIFEST.MF` containing absolute paths to Spring dependency JARs (simulates Gradle behavior)
2. **run-test**: Compiles and runs `TestApp.java` which uses Spring's `PathMatchingResourcePatternResolver` to scan the classpath
3. **Result**: Shows the scanning failure with empty root patterns vs success with package prefix patterns

## Verifying the Manifest

To see the absolute paths in the generated classpath JAR:

```bash
jar xf classpath.jar META-INF/MANIFEST.MF
cat META-INF/MANIFEST.MF
```

You should see entries like:
```
Class-Path: /Users/.../.m2/repository/.../spring-core-6.1.4.jar /Users/...
```

## Related Issue

See the Spring Framework issue for technical details about the root cause and proposed fix.
