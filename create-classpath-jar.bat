@echo off
REM Script to create a classpath JAR with absolute paths in the manifest,
REM simulating what Gradle does on Windows with long classpaths.

setlocal enabledelayedexpansion

echo Creating classpath JAR with absolute paths in manifest...
echo.

REM Find Maven local repository
set MAVEN_REPO=%USERPROFILE%\.m2\repository
if not exist "%MAVEN_REPO%" (
    echo ERROR: Maven local repository not found at %MAVEN_REPO%
    echo Please run: mvn dependency:resolve first
    exit /b 1
)

echo Maven repository: %MAVEN_REPO%
echo.

REM Find Spring JARs
set SPRING_JARS=
set JAR_COUNT=0

REM Look for spring-core
for /f "delims=" %%i in ('dir /s /b "%MAVEN_REPO%\org\springframework\spring-core\spring-core-*.jar" 2^>nul') do (
    set SPRING_CORE=%%i
    goto :found_core
)
:found_core
if defined SPRING_CORE (
    set SPRING_JARS=!SPRING_JARS! !SPRING_CORE!
    set /a JAR_COUNT+=1
    echo Found: !SPRING_CORE!
)

REM Look for spring-jcl
for /f "delims=" %%i in ('dir /s /b "%MAVEN_REPO%\org\springframework\spring-jcl\spring-jcl-*.jar" 2^>nul') do (
    set SPRING_JCL=%%i
    goto :found_jcl
)
:found_jcl
if defined SPRING_JCL (
    set SPRING_JARS=!SPRING_JARS! !SPRING_JCL!
    set /a JAR_COUNT+=1
    echo Found: !SPRING_JCL!
)

REM Look for spring-beans
for /f "delims=" %%i in ('dir /s /b "%MAVEN_REPO%\org\springframework\spring-beans\spring-beans-*.jar" 2^>nul') do (
    set SPRING_BEANS=%%i
    goto :found_beans
)
:found_beans
if defined SPRING_BEANS (
    set SPRING_JARS=!SPRING_JARS! !SPRING_BEANS!
    set /a JAR_COUNT+=1
    echo Found: !SPRING_BEANS!
)

REM Look for spring-context
for /f "delims=" %%i in ('dir /s /b "%MAVEN_REPO%\org\springframework\spring-context\spring-context-*.jar" 2^>nul') do (
    set SPRING_CONTEXT=%%i
    goto :found_context
)
:found_context
if defined SPRING_CONTEXT (
    set SPRING_JARS=!SPRING_JARS! !SPRING_CONTEXT!
    set /a JAR_COUNT+=1
    echo Found: !SPRING_CONTEXT!
)

if %JAR_COUNT%==0 (
    echo.
    echo ERROR: No Spring JARs found in %MAVEN_REPO%
    echo Please install dependencies first:
    echo   mvn dependency:resolve
    exit /b 1
)

echo.
echo Found %JAR_COUNT% Spring JARs
echo.

REM Create manifest directory
if exist manifest-tmp rmdir /s /q manifest-tmp
mkdir manifest-tmp\META-INF

REM Create manifest with ABSOLUTE paths
(
    echo Manifest-Version: 1.0
    echo|set /p="Class-Path:"
) > manifest-tmp\META-INF\MANIFEST.MF

REM Add each JAR with its ABSOLUTE path (using forward slashes like Gradle does)
for %%j in (%SPRING_JARS%) do (
    set "jar_path=%%j"
    REM Convert backslashes to forward slashes
    set "jar_path=!jar_path:\=/!"
    echo  !jar_path!>> manifest-tmp\META-INF\MANIFEST.MF
)

echo.>> manifest-tmp\META-INF\MANIFEST.MF

echo Generated manifest:
echo ====================
type manifest-tmp\META-INF\MANIFEST.MF
echo ====================
echo.

REM Create the classpath JAR
jar cfm classpath.jar manifest-tmp\META-INF\MANIFEST.MF

REM Cleanup
rmdir /s /q manifest-tmp

echo Created classpath.jar with absolute paths in manifest
echo.
echo To verify the manifest, run:
echo   jar xf classpath.jar META-INF/MANIFEST.MF ^&^& type META-INF\MANIFEST.MF
echo.

endlocal
