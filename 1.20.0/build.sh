#!/bin/sh
RUSTC_BOOTSTRAP_VERSION=1.19.0
CARGO_BOOTSTRAP_VERSION=0.20.0
RUST_VERSION=1.20.0

BASE=`pwd`
DEST=$1
LLVM_ROOT=""
ADDITIONAL_CONFIGURE_FLAGS=--enable-local-rust

. ../checksums.sh
. ../common.sh

fixup-vendor() {
	fixup-vendor-patch curl-sys build.rs || exit 1
}

RUN info clean extract prepatch fixup-vendor config build dist inst 2>&1
