#! /bin/sh
set -e
xctool project Raamattu.xcodeproj -scheme "Raamattu" build test -sdk iphonesimulator8.1 -arch i386 ONLY_ACTIVE_ARCH=NO
