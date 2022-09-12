@echo off
cls
rem ffmpeg -list_devices true -f dshow -i dummy

echo This program uses FFMPEG to record your screen on  Windows system.
echo Make sure that you have screen-capture-recorder installed
echo.
echo. Note the output above to determine what your inpout / out put spkr and mic are, then adjust the ffmpeg line accordingy
echo.
echo When ready press Enter to start recording. Press Q to save the recording and exit
echo.
pause
echo.
set /P fname=Please enter a file name:
echo.
ffmpeg -y -rtbufsize 100M -f dshow -framerate 30 -i video="screen-capture-recorder":audio="Microphone (Realtek High Definition Audio)" -c:v libx264 -r 30 -preset ultrafast -tune zerolatency -crf 28 -pix_fmt yuv420p -c:a aac -strict -2 -ac 2 -b:a 128k %fname%.mkv
echo.
echo File %fname%.mkv has been created
echo.
pause
