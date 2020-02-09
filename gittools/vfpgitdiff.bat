@Echo Off

for /f %%i in ('wsl wslpath -a "%1"') do set FILENAME=%%i
"c:\Program Files\Git\bin\bash.exe" vfpgitdiff %FILENAME:~4% %2 %3
