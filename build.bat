@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: Load Visual Studio 2022 developer environment
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
) else (
    echo [ERROR] Visual Studio 2022 not found.
    exit /b 1
)

:: Add cargo to PATH
set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"

:: Static CRT linking + suppress non-critical warnings
set "RUSTFLAGS=-C target-feature=+crt-static -A dead_code -A unused_imports -A unused_variables -A unused_mut -A deprecated"

:: Build
echo [BUILD] Building server (release)...
cargo build --release
if !errorlevel! neq 0 (
    echo [ERROR] Build failed.
    exit /b !errorlevel!
)

:: Sign output binaries (hbbs.exe, hbbr.exe, rustdesk-utils.exe)
echo [SIGN] Signing release binaries...
for %%F in (target\release\hbbs.exe target\release\hbbr.exe target\release\rustdesk-utils.exe) do (
    if exist "%%F" (
        signtool sign /s my /tr http://timestamp.digicert.com /fd sha256 /td sha256 /a "%%F" && echo [SIGN] %%F
    )
)

echo [DONE] Build completed successfully.
echo   hbbs:           target\release\hbbs.exe
echo   hbbr:           target\release\hbbr.exe
echo   rustdesk-utils: target\release\rustdesk-utils.exe
endlocal
