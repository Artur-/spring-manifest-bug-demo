@echo off
REM Script to compile and run the test application demonstrating the
REM PathMatchingResourcePatternResolver bug with absolute paths in manifests.

setlocal

echo ===================================================================
echo Spring Framework PathMatchingResourcePatternResolver Bug Demo
echo ===================================================================
echo.

REM Check if classpath.jar exists
if not exist classpath.jar (
    echo ERROR: classpath.jar not found!
    echo Please run create-classpath-jar.bat first
    exit /b 1
)

echo Step 1: Compiling TestApp.java...
echo.

REM Find spring-core JAR for compilation
set MAVEN_REPO=%USERPROFILE%\.m2\repository
for /f "delims=" %%i in ('dir /s /b "%MAVEN_REPO%\org\springframework\spring-core\spring-core-*.jar" 2^>nul') do (
    set SPRING_CORE=%%i
    goto :found_spring_core
)
:found_spring_core

if not defined SPRING_CORE (
    echo ERROR: spring-core JAR not found for compilation
    echo Please run: mvn dependency:resolve
    exit /b 1
)

REM Compile
javac -cp "%SPRING_CORE%" TestApp.java

if not exist TestApp.class (
    echo ERROR: Compilation failed
    exit /b 1
)

echo Compilation successful
echo.

echo Step 2: Creating TestApp.jar with Main-Class and Class-Path manifest...
echo.

REM Create a manifest that references classpath.jar
if exist manifest-tmp rmdir /s /q manifest-tmp
mkdir manifest-tmp\META-INF
(
    echo Manifest-Version: 1.0
    echo Main-Class: TestApp
    echo Class-Path: classpath.jar
    echo.
) > manifest-tmp\META-INF\MANIFEST.MF

REM Create TestApp.jar
jar cfm TestApp.jar manifest-tmp\META-INF\MANIFEST.MF TestApp.class
rmdir /s /q manifest-tmp

echo Created TestApp.jar
echo.

echo Step 3: Running test using java -jar ^(simulates Gradle bootRun^)...
echo Command: java -jar TestApp.jar
echo.
echo This simulates how Gradle runs apps on Windows with long classpaths:
echo - Gradle creates a classpath JAR with absolute paths in manifest
echo - Gradle creates an app JAR that references the classpath JAR
echo - Java processes the manifest chain and loads all dependencies
echo.
echo -------------------------------------------------------------------

REM Run the test using -jar so Java will process the Class-Path manifest
java -jar TestApp.jar

set EXIT_CODE=%ERRORLEVEL%

echo -------------------------------------------------------------------
echo.

if %EXIT_CODE%==1 (
    echo BUG SUCCESSFULLY DEMONSTRATED!
    echo.
    echo The test confirmed that PathMatchingResourcePatternResolver
    echo rejects absolute paths in JAR manifest Class-Path entries.
) else if %EXIT_CODE%==0 (
    echo Bug not reproduced in this environment
    echo.
    echo This might mean:
    echo   - The classpath JAR doesn't have absolute paths
    echo   - The Spring version has the bug fixed
    echo   - Something else is different from the Windows/Gradle scenario
) else (
    echo Test failed with unexpected exit code: %EXIT_CODE%
)

echo.

endlocal
