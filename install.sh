#!/bin/sh

BUILD_MODE=release # Change to release for a release build
PROGRAM=permitter

BUILD_DIR="$PWD/.build/$BUILD_MODE"
EXEC_PATH="$BUILD_DIR/$PROGRAM"
BIN_DIR="$HOME/.local/bin"
INSTALL_PATH="$BIN_DIR/$PROGRAM"

if [ ! -d "$BUILD_DIR" ]; then
    echo "Executable not found."
    exit 1
fi

if [ ! -d "$BIN_DIR" ]; then
    echo "Creating local bin directory."
    mkdir -p "$BIN_DIR"
fi

install -m 755 $EXEC_PATH $INSTALL_PATH
