@echo off
cd /d C:\Projects\SmartRide\smartride
C:\flutter\bin\flutter clean
C:\flutter\bin\flutter pub get
C:\flutter\bin\flutter build apk --release
pause
