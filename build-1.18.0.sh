#!/bin/sh

RUSTC_BOOTSTRAP_VERSION=1.17.0
CARGO_BOOTSTRAP_VERSION=0.18.0
RUST_VERSION=1.18.0
TARGET=x86_64-unknown-dragonfly

BASE=`pwd`
DEST=$1
DEST_INSTALL=$DEST/install
COMPONENTS="cargo-${CARGO_BOOTSTRAP_VERSION} rust-std-${RUSTC_BOOTSTRAP_VERSION} rustc-${RUSTC_BOOTSTRAP_VERSION}"


# we need these to avoid patching the sources for sha256sum
export PATH=$BASE/bin:$PATH

rm -rf $DEST
mkdir -p $DEST $DEST/tmp $DEST/bootstrap

BOOTSTRAP_COMPILER_BASE=`realpath $DEST/bootstrap`
export LD_LIBRARY_PATH="${BOOTSTRAP_COMPILER_BASE}/lib:$LD_LIBRARY_PATH"

for component in $COMPONENTS; do
	tar xvzf $BASE/bootstrap/$component-${TARGET}.tar.gz -C $DEST/tmp
	$DEST/tmp/$component-${TARGET}/install.sh --prefix=$DEST/bootstrap
done

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
	--prefix=$DEST_INSTALL

mkdir -p $DEST/rustc-$RUST_VERSION-src/build/x86_64-unknown-dragonfly/stage0
cpdup -vv $BOOTSTRAP_COMPILER_BASE $DEST/rustc-$RUST_VERSION-src/build/x86_64-unknown-dragonfly/stage0

# we need overrides for libz-sys to build cargo
mkdir -p $DEST/.cargo
echo "paths = [\"$BASE/patches/libz-sys\"]" >> $DEST/.cargo/config

gmake VERBOSE=YES all dist install 2>&1 | tee out.log
