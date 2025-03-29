@echo off
setlocal

rem ============================================================================
rem Define the Project
rem ============================================================================

rem define the project data (change these for your specific project)
set PROJ_NAME=just_build
set PROJ_DIR=%~dp0
set PROJ_SRC_DIR=%PROJ_DIR%src
set PROJ_SRC_BUILD_FILE=%PROJ_DIR%src/build.c
set PROJ_ASSETS_DIR=%PROJ_DIR%assets
set PROJ_BUILD_DIR=%PROJ_DIR%_build
set PROJ_BUILD_ASSETS_DIR=%PROJ_BUILD_DIR%\assets

rem ============================================================================
rem Initialize the Script
rem ============================================================================

rem build mode "enum"
set BUILD_MODE_RELEASE=0
set BUILD_MODE_DEBUG=1
set BUILD_MODE_DIAGNOSTIC=2
set BUILD_MODE_CLEAN=9

rem set the build mode to the default value
set BUILD_MODE=%BUILD_MODE_RELEASE%
set BUILD_MSG=

rem parse arguments to set the build mode (or print help)
for %%a in (%*) do (
  if "%%a"=="help" ( goto help
  ) else if "%%a"=="release" ( set BUILD_MODE=%BUILD_MODE_RELEASE%
  ) else if "%%a"=="debug"   ( set BUILD_MODE=%BUILD_MODE_DEBUG%
  ) else if "%%a"=="diag"    ( set BUILD_MODE=%BUILD_MODE_DIAGNOSTIC%
  ) else if "%%a"=="clean"   ( set BUILD_MODE=%BUILD_MODE_CLEAN%
  )
)

rem update built script settings based on the chosen build mode
if "%BUILD_MODE%"=="%BUILD_MODE_RELEASE%" (
  set BUILD_MSG=building release
) else if "%BUILD_MODE%"=="%BUILD_MODE_DEBUG%" (
  set BUILD_MSG=building debug
) else if "%BUILD_MODE%"=="%BUILD_MODE_DIAGNOSTIC%" (
  set BUILD_MSG=building diagnostic
) else if "%BUILD_MODE%"=="%BUILD_MODE_CLEAN%" (
  set BUILD_MSG=cleaning
) else (
  echo INTERNAL ERROR: invalid build setting
  goto exit_error
)

rem print the build message
echo %BUILD_MSG%

rem ============================================================================
rem Manage the Build Directory
rem ============================================================================

rem handle build cleaning
if %BUILD_MODE%==%BUILD_MODE_CLEAN% (
  if exist "%PROJ_BUILD_DIR%" (
    rd /s /q "%PROJ_BUILD_DIR%"
    if %ERRORLEVEL% neq 0 (
      echo ERROR: failed to delete build directory
      goto exit_error
    )
  )
  goto exit_success
)

rem create the build directory if it does not already exist
if not exist "%PROJ_BUILD_DIR%" (
  call mkdir "%PROJ_BUILD_DIR%"
  if %ERRORLEVEL% neq 0 (
    echo ERROR: failed to create build directory
    goto exit_error
  )
)

rem enter the build directory using pushd to save the prior directory
call pushd "%PROJ_BUILD_DIR%"
if %ERRORLEVEL% neq 0 (
  echo ERROR: failed to enter build directory
  goto exit_error
)

rem ============================================================================
rem Compile the Code
rem ============================================================================

rem compiler arguments
set COMPILE_ARGS=/nologo /diagnostics:column /std:c11 /TC /MT /I "%PROJ_SRC_DIR%" "%PROJ_SRC_BUILD_FILE%"
set RELEASE_COMPILE_ARGS=/O2
set DEBUG_COMPILE_ARGS=/O2 /Zi
set DIAGNOSTIC_COMPILE_ARGS=/Od /Zi /W4 /Wall /WX /external:W3 /fsanitize=address

rem linker arguments
set LINK_ARGS=/SUBSYSTEM:console /out:%PROJ_NAME%.exe
set RELEASE_LINK_ARGS=/DEBUG:None
set DEBUG_LINK_ARGS=/DEBUG
set DIAGNOSTIC_LINK_ARGS=/DEBUG

rem update the compiler and linker arguments based on the build mode
if "%BUILD_MODE%"=="%BUILD_MODE_RELEASE%" (
  set COMPILE_ARGS=%COMPILE_ARGS% %RELEASE_COMPILE_ARGS%
  set LINK_ARGS=%LINK_ARGS% %RELEASE_LINK_ARGS%
) else if "%BUILD_MODE%"=="%BUILD_MODE_DEBUG%" (
  set COMPILE_ARGS=%COMPILE_ARGS% %DEBUG_COMPILE_ARGS%
  set LINK_ARGS=%LINK_ARGS% %DEBUG_LINK_ARGS%
) else if "%BUILD_MODE%"=="%BUILD_MODE_DIAGNOSTIC%" (
  set COMPILE_ARGS=%COMPILE_ARGS% %DIAGNOSTIC_COMPILE_ARGS%
  set LINK_ARGS=%LINK_ARGS% %DIAGNOSTIC_LINK_ARGS%
) else (
  echo INTERNAL ERROR: invalid build setting for compilation
  goto exit_error
)

rem compile the code
call cl.exe %COMPILE_ARGS% /link %LINK_ARGS% > "%PROJ_BUILD_DIR%\_build_output.txt"
if %ERRORLEVEL% neq 0 (
  call more "%PROJ_BUILD_DIR%\_build_output.txt"
  echo ERROR: failed to compile
  goto exit_error
)

rem ============================================================================
rem Junction the Assets
rem ============================================================================

rem junction the assets directory (if source and target are not empty strings)
if "%PROJ_ASSETS_DIR%" neq "" (
  if "%PROJ_BUILD_ASSETS_DIR%" neq "" (
    if not exist "%PROJ_BUILD_ASSETS_DIR%" (
      call mklink /J "%PROJ_BUILD_ASSETS_DIR%" "%PROJ_ASSETS_DIR%" > "%PROJ_BUILD_DIR%\_junction_output.txt"
      if %ERRORLEVEL% neq 0 (
        call more "%PROJ_BUILD_DIR%\_junction_output.txt"
        echo ERROR: failed to create build assets junction
        goto exit_error
      )
    )
  )
)

rem ============================================================================
rem Exit handlers
rem ============================================================================

:exit_success
rem if we're in the build directory, pop back to the prior directory
if "%CD%"=="%PROJ_BUILD_DIR%" call popd
echo succeeded
endlocal
exit /B 0

:exit_error
rem if we're in the build directory, pop back to the prior directory
if "%CD%"=="%PROJ_BUILD_DIR%" call popd
endlocal
exit /B 1

rem ============================================================================
rem Print the help message
rem ============================================================================

:help
echo usage: build [ release ^| debug ^| clean ^| help ]
echo  release  build in release mode (default) ^| debug:off ^| optimize:on  ^| warnings:min ^| asan:off
echo  debug    build in debug mode             ^| debug:on  ^| optimize:on  ^| warnings:min ^| asan:off
echo  debug    build in diagnostic mode        ^| debug:on  ^| optimize:off ^| warnings:max ^| asan:on
echo  clean    clean the build artifacts
echo  help     print this message
endlocal
exit /B 0


