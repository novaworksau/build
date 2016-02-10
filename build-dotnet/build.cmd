@ECHO off
SETLOCAL

IF "%KOREBUILD_FOLDER%"=="" (
	ECHO Error: KOREBUILD_FOLDER is not set.
	EXIT /B 1
)
IF "%NUGET_PATH%"=="" (
	ECHO Error: NUGET_PATH is not set.
	EXIT /B 1
)
IF "%KOREBUILD_DOTNET_CHANNEL%"=="" (
    SET KOREBUILD_DOTNET_CHANNEL=dev
)

IF "%KOREBUILD_DOTNET_VERSION%"=="" (
    SET KOREBUILD_DOTNET_VERSION=1.0.0.000973
)

IF NOT EXIST Sake  (
    "%NUGET_PATH%" install Sake -ExcludeVersion -Source https://api.nuget.org/v3/index.json -o %~dp0
)

IF NOT EXIST xunit.runner.console  (
    "%NUGET_PATH%" install xunit.runner.console -ExcludeVersion -Source https://api.nuget.org/v3/index.json -o %~dp0
)

IF NOT EXIST xunit.core  (
    "%NUGET_PATH%" install xunit.core -ExcludeVersion -Source https://api.nuget.org/v3/index.json -o %~dp0
)

IF "%KOREBUILD_SKIP_RUNTIME_INSTALL%"=="1" (
    ECHO Skipping runtime installation because KOREBUILD_SKIP_RUNTIME_INSTALL = 1
    GOTO :SKIP_RUNTIME_INSTALL
)

SET DOTNET_LOCAL_INSTALL_FOLDER=%LOCALAPPDATA%\Microsoft\dotnet\cli
SET DOTNET_LOCAL_INSTALL_FOLDER_BIN=%DOTNET_LOCAL_INSTALL_FOLDER%\bin

CALL %~dp0dotnet-install.cmd -Channel %KOREBUILD_DOTNET_CHANNEL% -Version %KOREBUILD_DOTNET_VERSION%

ECHO Adding %DOTNET_LOCAL_INSTALL_FOLDER_BIN% to PATH
SET PATH=%DOTNET_LOCAL_INSTALL_FOLDER_BIN%;%PATH%
ECHO Setting DOTNET_HOME to %DOTNET_LOCAL_INSTALL_FOLDER%
SET DOTNET_HOME=%DOTNET_LOCAL_INSTALL_FOLDER%

REM ==== Temporary ====
IF "%BUILDCMD_DNX_VERSION%"=="" (
    SET BUILDCMD_DNX_VERSION=latest
)
IF "%SKIP_DNX_INSTALL%"=="" (
    CALL %KOREBUILD_FOLDER%\build\dnvm install %BUILDCMD_DNX_VERSION% -runtime CLR -arch x64 -alias default
    CALL %KOREBUILD_FOLDER%\build\dnvm install default -runtime CLR -arch x64 -alias default
) ELSE (
    CALL %KOREBUILD_FOLDER%\build\dnvm use default -runtime CLR -arch x64
)
REM ============================

:SKIP_RUNTIME_INSTALL

SET MAKEFILE_PATH=makefile.shade
IF NOT EXIST %MAKEFILE_PATH% (
	SET MAKEFILE_PATH=%KOREBUILD_FOLDER%\makefile.shade
)
ECHO Using makefile: %MAKEFILE_PATH%

REM Don't use full paths. Sake doesn't support them!
"%~dp0Sake\tools\Sake.exe" -I %KOREBUILD_FOLDER% -f %MAKEFILE_PATH% %*
