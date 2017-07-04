#!/bin/sh

BOOTSTRAP_VERSION=1.16.0
RUST_VERSION=1.17.0

BASE=`pwd`
BOOTSTRAP_COMPILER_BASE=`realpath $BASE/bootstrap/rust-$BOOTSTRAP_VERSION-dev`
DEST=$1
DEST_INSTALL=$DEST/install
ARG=$2

if [ "$ARG" = "CONT" ]; then
	cd $DEST
	cd rustc-$RUST_VERSION-src
else
	rm -rf $DEST
	mkdir $DEST
	cd $DEST
	#fetch https://static.rust-lang.org/dist/rustc-1.17.0-src.tar.gz
	tar xvzf $BASE/dist/rustc-$RUST_VERSION-src.tar.gz
	cd rustc-$RUST_VERSION-src
fi

export LD_LIBRARY_PATH="${BOOTSTRAP_COMPILER_BASE}/lib:$LD_LIBRARY_PATH"
export RUST_BACKTRACE=1

if [ "$ARG" = "CONT" ]; then
	echo nothing to do
else
	for patch in $BASE/patches/patch-*; do
		echo $patch
		patch < $patch
	done

	./configure \
		--enable-local-rust --local-rust-root=${BOOTSTRAP_COMPILER_BASE} \
		--prefix=$DEST_INSTALL
fi

gmake VERBOSE=YES all dist install 2>&1 | tee out.log
