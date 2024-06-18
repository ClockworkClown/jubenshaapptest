#!/usr/bin/env bash

# Clone Flutter repository
FLUTTER_DIR=flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $FLUTTER_DIR

# Add Flutter to PATH
export PATH="$PATH:$PWD/$FLUTTER_DIR/bin"

# Run Flutter doctor
$PWD/$FLUTTER_DIR/bin/flutter doctor
