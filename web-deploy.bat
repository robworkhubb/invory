@echo off
color 0E

echo ================================
echo     BUILD WEB VERSIONE
echo ================================
flutter build web --release
if errorlevel 1 goto PAUSE_AND_EXIT 1

color 0A
echo ================================
echo     COPIA DELLA CARTELLA build\web
echo ================================
xcopy /E /I /Y build\web ..\webapp
if errorlevel 1 goto PAUSE_AND_EXIT 1
echo.

cd ..\webapp
if errorlevel 1 goto PAUSE_AND_EXIT 1
echo.

color 0E
echo ================================
echo      ESECUZIONE GIT COMMIT
echo ================================

git add .
rem prova a committare, se non ci sono cambiamenti esce senza errore
git diff-index --quiet HEAD --
if errorlevel 1 (
    git commit -m "Aggiornamento Sito Web"
    if errorlevel 1 goto PAUSE_AND_EXIT 1
    git push origin web-deploy --quiet
    if errorlevel 1 goto PAUSE_AND_EXIT 1
) else (
    echo Nessuna modifica da committare.
)

color 0A
echo.
echo ====================================
echo     OPERAZIONE COMPLETATA CON SUCCESSO!
echo ====================================
goto PAUSE_AND_EXIT 0

:PAUSE_AND_EXIT
echo.
pause
exit /b %1
