#!/bin/sh

BOOTSTRAP_VERSION=1.17.0
RUST_VERSION=1.18.0

BASE=`pwd`
BOOTSTRAP_COMPILER_BASE=`realpath $BASE/bootstrap/rust-$BOOTSTRAP_VERSION-dev`
DEST=$1
DEST_INSTALL=$DEST/install
ARG=$2

export LD_LIBRARY_PATH="${BOOTSTRAP_COMPILER_BASE}/lib:$LD_LIBRARY_PATH"
#export RUST_LOG=debug
export RUST_BACKTRACE=1

# we need these to avoid patching the sources for sha256sum
export PATH=$BASE/bin:$PATH

if [ "$ARG" = "CONT" ]; then
	cd $DEST
	cd rustc-$RUST_VERSION-src
else
	rm -rf $DEST
	mkdir $DEST
	cd $DEST
	#fetch https://static.rust-lang.org/dist/rustc-$RUST_VERSION-src.tar.gz
	tar xvzf $BASE/dist/rustc-$RUST_VERSION-src.tar.gz
	cd rustc-$RUST_VERSION-src

	for patch in $BASE/patches/patch-*; do
		echo $patch
		patch < $patch
	done

	./configure \
		--enable-cargo-openssl-static --enable-extended \
		--enable-local-rust --local-rust-root=${BOOTSTRAP_COMPILER_BASE} \
		--llvm-root=/usr/local/llvm40 --prefix=$DEST_INSTALL

	mkdir -p $DEST/rustc-$RUST_VERSION-src/build/x86_64-unknown-dragonfly/stage0
	cpdup -vv $BOOTSTRAP_COMPILER_BASE $DEST/rustc-$RUST_VERSION-src/build/x86_64-unknown-dragonfly/stage0

	# we need overrides for libz-sys to build cargo
	mkdir -p $DEST/.cargo
	echo "paths = [\"$BASE/patches/libz-sys\"]" >> $DEST/.cargo/config
fi

gmake VERBOSE=YES all dist install 2>&1 | tee out.log
