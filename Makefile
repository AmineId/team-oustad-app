# Team Fitness App - Makefile
# Usage: make <command>

.PHONY: help install run run-android run-windows emulators launch devices clean build-apk build-appbundle analyze format test upgrade doctor

help:
	@echo "Available commands:"
	@echo "  make install       - Install all dependencies"
	@echo "  make run           - Run app on connected device/emulator"
	@echo "  make run-android   - Run app on Android emulator"
	@echo "  make run-windows   - Run app on Windows"
	@echo "  make emulators     - List available emulators"
	@echo "  make launch        - Launch Pixel 9 Pro emulator"
	@echo "  make devices       - Show connected devices"
	@echo "  make clean         - Clean build files"
	@echo "  make build-apk     - Build APK for release"
	@echo "  make build-appbundle - Build App Bundle for Play Store"
	@echo "  make analyze       - Analyze code for issues"
	@echo "  make format        - Format all Dart files"
	@echo "  make test          - Run all tests"
	@echo "  make upgrade       - Upgrade all dependencies"
	@echo "  make doctor        - Check Flutter installation"

install:
	flutter pub get

run:
	flutter run

run-android:
	flutter run -d emulator-5554

run-windows:
	flutter run -d windows

emulators:
	flutter emulators

launch:
	flutter emulators --launch Pixel_9_Pro

devices:
	flutter devices

clean:
	flutter clean

build-apk:
	flutter build apk --release

build-appbundle:
	flutter build appbundle --release

analyze:
	flutter analyze

format:
	dart format .

test:
	flutter test

upgrade:
	flutter pub upgrade

doctor:
	flutter doctor -v
