:: Copyright Toby Davis
:: See LICENSE for details

@echo off
setlocal

REM Check if Tectonic is installed
where tectonic >nul 2>nul
if %errorlevel% neq 0 (
	echo Tectonic is not installed. Please install it to proceed.
	exit /b 1
)

REM Check if GNUplot is installed
where gnuplot >nul 2>nul
if %errorlevel% neq 0 (
	echo Warning: GNUplot is not installed.
)

REM Parse command line arguments
set draftFlag=0
for %%i in (%*) do (
	if /i "%%i"=="draft" (
		set draftFlag=1
	)
)

echo "Do not externalize" > no_externalize.flag

REM If no flags are passed, run Tectonic with my_paper.tex
if "%~1"=="" (
	REM No flags passed, so build default configuration
) else (
	REM If draft flag is passed, create draft.flag file
	if %draftFlag%==1 (
		echo Building draft version
		echo Draft mode enabled > draft.flag
	)
)

tectonic -X compile my_paper.tex

if %draftFlag%==1 (
	del draft.flag
)

del no_externalize.flag

endlocal

