@echo off
REM ─────────────────────────────────────────────────────────────────────────────
REM MUIOGO Windows Test Reset
REM
REM Removes the local MUIOGO venv, manual Windows solver fallback installs,
REM solver-related user env vars, solver PATH entries, repo .env, and demo data
REM installed by setup so setup can be tested from a clean state.
REM
REM Usage:
REM   scripts\reset_windows_test.bat
REM ─────────────────────────────────────────────────────────────────────────────
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "PROJECT_ROOT=%%~fI"

call :ensure_safe_base "USERPROFILE" "%USERPROFILE%"
if errorlevel 1 exit /b 1
call :ensure_safe_base "LOCALAPPDATA" "%LOCALAPPDATA%"
if errorlevel 1 exit /b 1

set "VENV_DIR=%USERPROFILE%\.venvs\muiogo"
set "GLPK_DIR=%LOCALAPPDATA%\glpk"
set "CBC_DIR=%LOCALAPPDATA%\cbc"

echo This will remove MUIOGO test state from this Windows account:
echo   - %VENV_DIR%
echo   - %GLPK_DIR%
echo   - %CBC_DIR%
echo   - User env vars SOLVER_GLPK_PATH and SOLVER_CBC_PATH
echo   - User PATH entries for the local GLPK/CBC fallback folders
echo   - %PROJECT_ROOT%\.env
echo   - %PROJECT_ROOT%\WebAPP\DataStorage\.demo_data_installed.json
echo   - %PROJECT_ROOT%\WebAPP\DataStorage\CLEWs Demo
echo.
choice /C YN /N /M "Continue? [Y/N]: "
if errorlevel 2 (
    echo Cancelled.
    exit /b 1
)

set "SOLVER_GLPK_PATH="
set "SOLVER_CBC_PATH="

call :remove_if_exists "%VENV_DIR%"
call :remove_if_exists "%GLPK_DIR%"
call :remove_if_exists "%CBC_DIR%"
call :remove_if_exists "%PROJECT_ROOT%\.env"
call :remove_if_exists "%PROJECT_ROOT%\WebAPP\DataStorage\.demo_data_installed.json"
call :remove_if_exists "%PROJECT_ROOT%\WebAPP\DataStorage\CLEWs Demo"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$userPath = [Environment]::GetEnvironmentVariable('Path', 'User');" ^
  "$glpkRoot = [System.IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'glpk'));" ^
  "$cbcRoot = [System.IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'cbc'));" ^
  "$parts = @();" ^
  "if ($userPath) { $parts = $userPath -split ';' | Where-Object { $raw = [Environment]::ExpandEnvironmentVariables($_.Trim()); if (-not $raw) { $false } else { $entry = [System.IO.Path]::GetFullPath($raw); ($entry -ne $glpkRoot -and -not $entry.StartsWith($glpkRoot + '\', [System.StringComparison]::OrdinalIgnoreCase) -and $entry -ne $cbcRoot -and -not $entry.StartsWith($cbcRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)) } } }" ^
  "[Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User');" ^
  "[Environment]::SetEnvironmentVariable('SOLVER_GLPK_PATH', $null, 'User');" ^
  "[Environment]::SetEnvironmentVariable('SOLVER_CBC_PATH', $null, 'User')"

if errorlevel 1 (
    echo WARNING: Could not fully update user environment variables.
) else (
    echo Cleared user solver environment variables and PATH entries.
)

echo.
echo Reset complete.
echo Open a NEW PowerShell window before running scripts\setup.bat again.
exit /b 0

:remove_if_exists
set "TARGET=%~1"
if exist "%TARGET%" (
    rmdir /s /q "%TARGET%" >nul 2>&1
    if exist "%TARGET%" del /f /q "%TARGET%" >nul 2>&1
    if exist "%TARGET%" (
        echo WARNING: Could not remove %TARGET%
    ) else (
        echo Removed %TARGET%
    )
) else (
    echo Not present: %TARGET%
)
exit /b 0

:ensure_safe_base
set "VAR_NAME=%~1"
set "VAR_VALUE=%~2"

if "%VAR_VALUE%"=="" (
    echo ERROR: %VAR_NAME% is empty. Refusing to build delete paths from it.
    exit /b 1
)
if /I "%VAR_VALUE%"=="%SystemDrive%" (
    echo ERROR: %VAR_NAME% points at the drive root: %VAR_VALUE%
    exit /b 1
)
if /I "%VAR_VALUE%"=="%SystemDrive%\" (
    echo ERROR: %VAR_NAME% points at the drive root: %VAR_VALUE%
    exit /b 1
)
exit /b 0
