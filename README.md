# Spring Framework PathMatchingResourcePatternResolver Bug Demo

This is a minimal reproducible example demonstrating a bug in Spring Framework's `PathMatchingResourcePatternResolver` that causes classpath scanning to fail when absolute paths are used in JAR manifest `Class-Path` entries.

## The Bug

**File:** `PathMatchingResourcePatternResolver.java`
**Method:** `getClassPathManifestEntriesFromJar()` (line 615)
**Issue:** The security check rejects valid absolute paths in manifest entries

### What Happens

When Gradle (or other build tools) creates a classpath JAR with **absolute paths** in its `META-INF/MANIFEST.MF`:

```
Class-Path: C:/Users/developer/.gradle/caches/.../spring-core-6.2.1.jar
            C:/Users/developer/.gradle/caches/.../spring-beans-6.2.1.jar
```

Spring's code at line 615 incorrectly rejects these entries:

```java
File candidate = new File(parent, path);
if (candidate.isFile() && candidate.getCanonicalPath().contains(parent.getCanonicalPath())) {
    manifestEntries.add(ClassPathManifestEntry.of(candidate));
}
```

The problem: When `path` is absolute, `File(parent, path)` ignores `parent` and uses only the absolute path. The security check then fails because the absolute path doesn't contain the parent directory path.

### Impact

- ❌ `classpath*:**/*.class` scanning finds only ~10 classes (application JAR only)
- ✅ `classpath*:org/**/*.class` scanning works correctly (finds 400+ classes)
- Affects Windows users with Gradle and long classpaths
- Silent failure (no exceptions, just missing resources)

## Prerequisites

- Java 17 or later
- Maven 3.6 or later
- Unix shell (bash) or Windows command prompt

## Quick Start

### On Linux/Mac

```bash
# 1. Download Spring dependencies
mvn dependency:resolve

# 2. Create classpath JAR with absolute paths (simulates Gradle behavior)
chmod +x create-classpath-jar.sh run-test.sh
./create-classpath-jar.sh

# 3. Run the test
./run-test.sh
```

### On Windows

```cmd
REM 1. Download Spring dependencies
mvn dependency:resolve

REM 2. Create classpath JAR with absolute paths (simulates Gradle behavior)
create-classpath-jar.bat

REM 3. Run the test
run-test.bat
```

## Expected Output

When the bug is present, you'll see:

```
======================================================================
Testing PathMatchingResourcePatternResolver with Manifest Classpath
======================================================================

TEST 1: Scanning with empty root
Pattern: classpath*:**/*.class
----------------------------------------------------------------------
Found: 2 classes
❌ BUG DETECTED: Too few resources found!
   This indicates that JARs from the manifest are being rejected.

Sample resources found:
  - jar:file:/.../spring-core-6.1.4.jar!/META-INF/versions/21/.../VirtualThreadDelegate.class
  - jar:file:/.../TestApp.jar!/TestApp.class

======================================================================

TEST 2: Scanning with package prefix
Pattern: classpath*:org/**/*.class
----------------------------------------------------------------------
Found: 458 classes
✓ OK: Package prefix pattern works correctly
   This confirms that the issue is specific to empty-root patterns.

Sample resources found:
  - jar:file:/.../spring-core-6.1.4.jar!/META-INF/versions/21/.../VirtualThreadDelegate.class
  - jar:file:/.../spring-jcl-6.1.4.jar!/org/apache/commons/logging/LogFactory$1.class
  - jar:file:/.../spring-jcl-6.1.4.jar!/org/apache/commons/logging/impl/NoOpLog.class
  ...

======================================================================

SUMMARY:
----------------------------------------------------------------------
Empty root pattern (classpath*:**/*.class): 2 resources
Package prefix pattern (classpath*:org/**/*.class): 458 resources

BUG CONFIRMED!
The PathMatchingResourcePatternResolver is rejecting absolute paths
in the JAR manifest Class-Path entries.

Root cause: PathMatchingResourcePatternResolver.java:615
The security check 'candidate.getCanonicalPath().contains(parent.getCanonicalPath())'
fails for absolute paths in the manifest.
```

## How It Works

### 1. create-classpath-jar script

This script:
- Finds Spring JARs in your Maven local repository (`~/.m2/repository`)
- Creates a `META-INF/MANIFEST.MF` with **absolute paths** to these JARs
- Packages this into `classpath.jar`

This simulates exactly what Gradle does on Windows when the classpath exceeds the command-line length limit.

### 2. TestApp.java

The test application:
- Uses `PathMatchingResourcePatternResolver` to scan for classes
- Tests two patterns:
  - `classpath*:**/*.class` (empty root - **FAILS** with absolute manifest paths)
  - `classpath*:org/**/*.class` (package prefix - **WORKS**)
- Compares results and confirms the bug

### 3. run-test script

This script:
- Compiles `TestApp.java`
- Runs it with: `java -cp classpath.jar TestApp`
- The JVM loads the manifest from `classpath.jar` and adds those JARs to the classpath
- Spring's code processes the manifest and demonstrates the bug

## Understanding the Root Cause

### The Security Check Problem

```java
// Line 600: Get parent directory of the classpath JAR
File parent = jar.getAbsoluteFile().getParentFile();

// Line 609: Read path from manifest (can be relative OR absolute)
String path = tokenizer.nextToken();

// Line 614: Create File object
File candidate = new File(parent, path);
// ⚠️ If path is absolute, Java IGNORES parent!

// Line 615: Security check FAILS for absolute paths
if (candidate.isFile() &&
    candidate.getCanonicalPath().contains(parent.getCanonicalPath())) {
    // ❌ This fails because absolute paths don't contain parent path
    manifestEntries.add(ClassPathManifestEntry.of(candidate));
}
```

### Example

```
parent = "/project/build/tmp/bootRun/"
path = "C:/Users/.../.gradle/caches/.../spring-core-6.2.1.jar"

candidate = new File(parent, path)
candidate.getCanonicalPath() = "C:/Users/.../.gradle/caches/.../spring-core-6.2.1.jar"

"C:/Users/.../.gradle/caches/.../spring-core-6.2.1.jar".contains("/project/build/tmp/bootRun/")
= false ❌

Result: Valid dependency JAR is rejected!
```

## Proposed Fix

```java
File candidate = new File(parent, path);
if (candidate.isFile()) {
    // Security check: validate relative paths only, allow absolute paths
    boolean isRelativePath = !new File(path).isAbsolute();
    if (!isRelativePath || candidate.getCanonicalPath().contains(parent.getCanonicalPath())) {
        manifestEntries.add(ClassPathManifestEntry.of(candidate));
    }
}
```

## Related Issues

- Spring Framework #18260 - PathMatchingResourcePatternResolver does not consider manifest based classpaths
- Spring Framework #28276 - Different results with classpath in JAR manifest
- Spring Framework #24480 - Issues with JAR manifest class paths
- Vaadin Flow #21051 - Development mode fails on Windows with Gradle

## Manual Verification

To manually verify the manifest content:

```bash
# Extract and view the manifest
jar xf classpath.jar META-INF/MANIFEST.MF
cat META-INF/MANIFEST.MF
```

You should see absolute paths in the `Class-Path:` attribute.

## Files in This Demo

- **TestApp.java** - Minimal test application
- **create-classpath-jar.sh** / **.bat** - Creates classpath JAR with absolute paths
- **run-test.sh** / **.bat** - Compiles and runs the test
- **pom.xml** - Maven configuration for dependency management
- **README.md** - This file

## Cleanup

To clean up generated files:

```bash
# Linux/Mac
rm -f classpath.jar TestApp.class

# Windows
del classpath.jar TestApp.class
```

## License

This demo is public domain. Use it freely to report the bug to Spring Framework.

## Contributing

If you have improvements or find issues with this demo, please submit a pull request or open an issue.

---

**Created to demonstrate**: Spring Framework PathMatchingResourcePatternResolver bug with absolute paths in JAR manifest Class-Path entries
