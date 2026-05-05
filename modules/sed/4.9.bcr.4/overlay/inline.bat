@echo off
@REM For details see `inline.sh`

setlocal enabledelayedexpansion

set "INPUT_FILE=%~1"
set "OUTPUT_FILE=%~2"
shift
shift

:: Load insert contents and match strings
set "COUNT=0"
:load_pairs
if "%~1"=="" goto done_loading

set "INSERT_FILE_%COUNT%=%~1"
shift
set "MATCH_STRING_%COUNT%=%~1"
shift

set "INSERT_CONTENT_%COUNT%="
for /f "usebackq delims=" %%A in ("!INSERT_FILE_%COUNT%!") do (
    set "INSERT_CONTENT_%COUNT%=!INSERT_CONTENT_%COUNT%!%%A
"
)

set /a COUNT+=1
goto load_pairs
:done_loading

:: Process input file
> "%OUTPUT_FILE%" (
    for /f "usebackq delims=" %%L in ("%INPUT_FILE%") do (
        set "LINE=%%L"
        echo(%%L

        set /a I=0
        :match_loop
        if "!I!"=="%COUNT%" goto match_done

        if not "!LINE:!MATCH_STRING_!I!!=!"=="!LINE!" (
            echo(!INSERT_CONTENT_!I!!
        )

        set /a I+=1
        goto match_loop
        :match_done
    )
)

endlocal
