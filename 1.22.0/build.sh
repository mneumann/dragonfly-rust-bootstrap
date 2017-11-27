#!/bin/sh

RUSTC_BOOTSTRAP_VERSION=1.21.0
CARGO_BOOTSTRAP_VERSION=0.22.0
RUST_VERSION=1.22.0

BASE=`pwd`
DEST=$1
RELEASE_CHANNEL=stable
LLVM_ROOT=""
RUST_DIST_SERVER=https://dev-static.rust-lang.org

. ../common.sh

RUN info clean extract libressl-2.5.5 curlsys-0.3.14 prepatch config postpatch build dist inst 2>&1
