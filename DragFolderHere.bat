@echo off
cd /d "%~dp0"
FileLister.exe "%1" output.txt "#folder#name - #date (#size) [#ext] #md5"