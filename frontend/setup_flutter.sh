#!/usr/bin/env bash
# Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable
export PATH="$PATH:[PATH_TO_FLUTTER_GIT_DIRECTORY]/flutter/bin"
flutter doctor
