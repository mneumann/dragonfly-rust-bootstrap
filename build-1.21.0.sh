#!/bin/sh

RUSTC_BOOTSTRAP_VERSION=1.20.0
CARGO_BOOTSTRAP_VERSION=0.21.0
RUST_VERSION=1.21.0
TARGET=x86_64-unknown-dragonfly

BASE=`pwd`
DEST=$1
DEST_INSTALL=$DEST/install
COMPONENTS="cargo-${CARGO_BOOTSTRAP_VERSION} rust-std-${RUSTC_BOOTSTRAP_VERSION} rustc-${RUSTC_BOOTSTRAP_VERSION}"

RELEASE_CHANNEL=$2

if [ "$DEST" = "" ]; then
	echo "Usage: $0 target-dir [release-channel=stable|dev]"
	exit 1
fi

if [ "$RELEASE_CHANNEL" = "" ]; then
	RELEASE_CHANNEL=stable
fi

echo Base: $BASE
echo Release-Channel: $RELEASE_CHANNEL
echo Dest: $DEST

# we need these to avoid patching the sources for sha256sum
export PATH=$BASE/bin:$PATH

BOOTSTRAP_COMPILER_BASE=`realpath $DEST/bootstrap`
export LD_LIBRARY_PATH="${BOOTSTRAP_COMPILER_BASE}/lib:$LD_LIBRARY_PATH"


# for static cargo?
#export LIBSSH2_NO_PKG_CONFIG=1
#export LIBCURL_NO_PKG_CONFIG=1
#export LIBZ_NO_PKG_CONFIG=1 
#export PROFILE=release
#export LIBZ_SYS_STATIC=1
#export ac_cv_func_SSLv2_client_method=no
#export OPENSSL_LIB_DIR=/usr/local/lib
#export OPENSSL_INCLUDE_DIR=/usr/local/include/openssl
#export OPENSSL_NO_PKG_CONFIG=1

lll() {
	echo "-------------------------------------------"
	echo $1
	echo "-------------------------------------------"
}

extract() {
	lll "EXTRACT"
	rm -rf $DEST
	mkdir -p $DEST $DEST/tmp $DEST/bootstrap
	cd $DEST

	for component in ${COMPONENTS}; do
		echo "INSTALL COMPONENT: ${component}"
		tar xvzf $BASE/bootstrap/rust-${RUSTC_BOOTSTRAP_VERSION}/$component-${TARGET}.tar.xz -C $DEST/tmp
		$DEST/tmp/$component-${TARGET}/install.sh --prefix=$DEST/bootstrap
	done


	if [ ! -f $BASE/dist/rustc-$RUST_VERSION-src.tar.gz ]; then
		fetch -o $BASE/dist/rustc-$RUST_VERSION-src.tar.gz https://static.rust-lang.org/dist/rustc-$RUST_VERSION-src.tar.gz 
	fi

	tar xvzf $BASE/dist/rustc-$RUST_VERSION-src.tar.gz 2>&1 | wc -l
}

prepatch() {
	lll "PREPATCH"
	cd $DEST/rustc-$RUST_VERSION-src
	for patch in $BASE/patches/${RUST_VERSION}/patch-*; do
		echo $patch
		patch < $patch
	done
}


config() {
	lll "CONFIG"
	cd $DEST/rustc-$RUST_VERSION-src
	./configure \
		--release-channel=${RELEASE_CHANNEL} \
		--disable-docs --enable-full-bootstrap \
		--enable-locked-deps --disable-dist-src \
		--enable-cargo-openssl-static --enable-extended \
		--disable-jemalloc --enable-clang \
		--enable-local-rust --local-rust-root=${BOOTSTRAP_COMPILER_BASE} \
		--sysconfdir=${DEST_INSTALL}/etc \
		--prefix=${DEST_INSTALL}
}

postpatch() {
	lll "POSTPATCH"
	cd $DEST/rustc-$RUST_VERSION-src
	for patch in $BASE/patches/${RUST_VERSION}/after-configure/patch-*; do
		echo $patch
		patch < $patch
	done
}


run() {
	lll $1
	cd $DEST/rustc-$RUST_VERSION-src
	gmake VERBOSE=YES JOBS=1 $2
}

build() {
	run BUILD all
}

dist() {
	run DIST dist
}

inst() {
	run INSTALL install
}

all() {
	extract && prepatch && config && postpatch && build && dist && inst
}

all 2>&1 | tee -a out.log
