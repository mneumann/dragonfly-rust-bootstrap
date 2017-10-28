#!/bin/sh

RUSTC_BOOTSTRAP_VERSION=1.18.0
CARGO_BOOTSTRAP_VERSION=0.19.0
RUST_VERSION=1.19.0
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

echo $RELEASE_CHANNEL
echo $DEST


# we need these to avoid patching the sources for sha256sum
export PATH=$BASE/bin:$PATH

BOOTSTRAP_COMPILER_BASE=`realpath $DEST/bootstrap`
export LD_LIBRARY_PATH="${BOOTSTRAP_COMPILER_BASE}/lib:$LD_LIBRARY_PATH"

extract() {
	rm -rf $DEST
	mkdir -p $DEST $DEST/tmp $DEST/bootstrap
	cd $DEST

	for component in $COMPONENTS; do
		tar xvzf $BASE/bootstrap/$component-${TARGET}.tar.gz -C $DEST/tmp
		$DEST/tmp/$component-${TARGET}/install.sh --prefix=$DEST/bootstrap
	done


	if [ ! -f $BASE/dist/rustc-$RUST_VERSION-src.tar.gz ]; then
		fetch -o $BASE/dist/rustc-$RUST_VERSION-src.tar.gz https://static.rust-lang.org/dist/rustc-$RUST_VERSION-src.tar.gz 
	fi

	tar xvzf $BASE/dist/rustc-$RUST_VERSION-src.tar.gz
}

patch1() {
	cd $DEST/rustc-$RUST_VERSION-src

	for patch in $BASE/patches/${RUST_VERSION}/patch-*; do
		echo $patch
		patch < $patch
	done
}


config() {
	cd $DEST/rustc-$RUST_VERSION-src
	./configure \
		--release-channel=${RELEASE_CHANNEL} \
		--enable-cargo-openssl-static --enable-extended \
		--disable-jemalloc --enable-clang \
		--enable-local-rust --local-rust-root=${BOOTSTRAP_COMPILER_BASE} \
		--prefix=$DEST_INSTALL
}

patch2() {
	cd $DEST/rustc-$RUST_VERSION-src
	for patch in $BASE/patches/${RUST_VERSION}/after-configure/patch-*; do
		echo $patch
		patch < $patch
	done
}

build() {
	cd $DEST/rustc-$RUST_VERSION-src
	gmake VERBOSE=YES JOBS=1 all dist install 2>&1 | tee out.log
}

extract && patch1 && config && patch2 && build

cd $DEST/rustc-$RUST_VERSION-src
gmake VERBOSE=YES JOBS=1 install


#config sysconfdir

#mkdir -p $DEST/rustc-$RUST_VERSION-src/build/x86_64-unknown-dragonfly/stage0
#cpdup -vv $BOOTSTRAP_COMPILER_BASE $DEST/rustc-$RUST_VERSION-src/build/x86_64-unknown-dragonfly/stage0

# we need overrides for libz-sys to build cargo
#mkdir -p $DEST/.cargorustc-1.19.0-src/src/vendor/clap/src/app/mod.rs:
#echo "paths = [\"$BASE/patches/libz-sys\"]" >> $DEST/.cargo/config

#gmake VERBOSE=YES JOBS=1 all dist install 2>&1 | tee out.log
