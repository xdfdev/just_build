#!/bin/bash

set -e

# ============================================================================
# Define the Project
# ============================================================================

PROJ_NAME="just_build"
PROJ_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJ_SRC_DIR="$PROJ_DIR/src"
PROJ_SRC_BUILD_FILE="$PROJ_DIR/src/build.c"
PROJ_ASSETS_DIR="$PROJ_DIR/assets"
PROJ_BUILD_DIR="$PROJ_DIR/_build"
PROJ_BUILD_ASSETS_DIR="$PROJ_BUILD_DIR/assets"

# ============================================================================
# Initialize the Script
# ============================================================================

BUILD_MODE_RELEASE=0
BUILD_MODE_DEBUG=1
BUILD_MODE_DIAGNOSTIC=2
BUILD_MODE_CLEAN=9

# set the build mode to the default value
BUILD_MODE=$BUILD_MODE_RELEASE
BUILD_MSG=""

# parse arguments to set the build mode (or print help)
for arg in "$@"; do
  case "$arg" in
    help)    help; exit 0 ;;
    release) BUILD_MODE=$BUILD_MODE_RELEASE ;;
    debug)   BUILD_MODE=$BUILD_MODE_DEBUG ;;
    diag)    BUILD_MODE=$BUILD_MODE_DIAGNOSTIC ;;
    clean)   BUILD_MODE=$BUILD_MODE_CLEAN ;;
    *)       echo "unknown argument: $arg"; exit 1 ;;
  esac
done

# update built script settings based on the chosen build mode
case $BUILD_MODE in
  $BUILD_MODE_RELEASE)
    BUILD_MSG="building release"
    ;;
  $BUILD_MODE_DEBUG)
    BUILD_MSG="building debug"
    ;;
  $BUILD_MODE_DIAGNOSTIC)
    BUILD_MSG="building diagnostic"
    ;;
  $BUILD_MODE_CLEAN)
    BUILD_MSG="cleaning"
    ;;
  *)
    echo "INTERNAL ERROR: invalid build setting";
    exit 1
    ;;
esac

echo "$BUILD_MSG"

# ============================================================================
# Manage the Build Directory
# ============================================================================

# handle build cleaning
if [[ $BUILD_MODE -eq $BUILD_MODE_CLEAN ]]; then
  if [[ -d "$PROJ_BUILD_DIR" ]]; then
    rm -rf "$PROJ_BUILD_DIR" || { echo "ERROR: failed to delete build directory"; exit 1; }
  fi
  exit 0
fi

# create the build directory if it does not already exist
mkdir -p "$PROJ_BUILD_DIR" || { echo "ERROR: failed to create build directory"; exit 1; }

# enter the build directory using
cd "$PROJ_BUILD_DIR" || { echo "ERROR: failed to enter build directory"; exit 1; }

# ============================================================================
# Compile the Code
# ============================================================================

# compiler arguments
COMPILE_ARGS="-std=c11 -I$PROJ_SRC_DIR $PROJ_SRC_BUILD_FILE"
RELEASE_COMPILE_ARGS="-O2"
DEBUG_COMPILE_ARGS="-O2 -g"
DIAGNOSTIC_COMPILE_ARGS="-O0 -g -Wall -Wextra -Werror -fsanitize=address"

# linker arguments
LINK_ARGS="-o $PROJ_NAME"
RELEASE_LINK_ARGS=""
DEBUG_LINK_ARGS=""
DIAGNOSTIC_LINK_ARGS=""

# update the compiler and linker arguments based on the build mode
case $BUILD_MODE in
  $BUILD_MODE_RELEASE)
    COMPILE_ARGS="$COMPILE_ARGS $RELEASE_COMPILE_ARGS"
    LINK_ARGS="$LINK_ARGS $RELEASE_LINK_ARGS"
    ;;
  $BUILD_MODE_DEBUG)
    COMPILE_ARGS="$COMPILE_ARGS $DEBUG_COMPILE_ARGS"
    LINK_ARGS="$LINK_ARGS $DEBUG_LINK_ARGS"
    ;;
  $BUILD_MODE_DIAGNOSTIC)
    COMPILE_ARGS="$COMPILE_ARGS $DIAGNOSTIC_COMPILE_ARGS"
    LINK_ARGS="$LINK_ARGS $DIAGNOSTIC_LINK_ARGS"
    ;;
  *) echo "INTERNAL ERROR: invalid build setting for compilation"; exit 1 ;;
esac

# compile the code
gcc $COMPILE_ARGS -o "$PROJ_NAME" > "$PROJ_BUILD_DIR/_build_output.txt" 2>&1 || {
  cat "$PROJ_BUILD_DIR/_build_output.txt"
  echo "ERROR: failed to compile"
  exit 1
}

# ============================================================================
# Junction the Assets
# ============================================================================

if [[ -d "$PROJ_ASSETS_DIR" && ! -e "$PROJ_BUILD_ASSETS_DIR" ]]; then
  ln -s "$PROJ_ASSETS_DIR" "$PROJ_BUILD_ASSETS_DIR" || {
    echo "ERROR: failed to create build assets symlink"
    exit 1
  }
fi

# ============================================================================
# Exit handlers
# ============================================================================

echo "succeeded"
exit 0

# ============================================================================
# Print the help message
# ============================================================================

help() {
  echo "usage: build [ release | debug | clean | help ]"
  echo "  release  build in release mode (default) | debug:off | optimize:on  | warnings:min | asan:off"
  echo "  debug    build in debug mode             | debug:on  | optimize:on  | warnings:min | asan:off"
  echo "  diag     build in diagnostic mode        | debug:on  | optimize:off | warnings:max | asan:on"
  echo "  clean    clean the build artifacts"
  echo "  help     print this message"
}
