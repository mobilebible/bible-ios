#! /bin/sh
set -e
xctool project Raamattu.xcodeproj -scheme "Raamattu" build -sdk iphonesimulator7.0 -arch i386 ONLY_ACTIVE_ARCH=NO
