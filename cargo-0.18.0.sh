 #!/bin/sh

BASE=`pwd`
CARGO_V=0.18.0
BOOTSTRAP_VERSION=1.17.0
BOOTSTRAP_COMPILER_BASE=`realpath $BASE/bootstrap/rust-$BOOTSTRAP_VERSION-dev`
DEST=$1

export LD_LIBRARY_PATH="${BOOTSTRAP_COMPILER_BASE}/lib:$LD_LIBRARY_PATH"
export PATH="${BOOTSTRAP_COMPILER_BASE}/bin:$PATH"

export VERBOSE=1
export LIBSSH2_NO_PKG_CONFIG=1
export LIBCURL_NO_PKG_CONFIG=1
export LIBZ_NO_PKG_CONFIG=1 

export PROFILE=release
export LIBZ_SYS_STATIC=1

rm -rf $DEST
mkdir $DEST
cd $DEST
#fetch https://github.com/rust-lang/cargo/archive/${CARGO_V}.tar.gz
tar xvzf $BASE/dist/cargo/$CARGO_V.tar.gz

# fetch https://github.com/rust-lang/rust-installer/archive/4f994850808a572e2cc8d43f968893c8e942e9bf.tar.gz
tar xvzf $BASE/dist/rust-installer/4f994850808a572e2cc8d43f968893c8e942e9bf.tar.gz

cpdup -v rust-installer-4f994850808a572e2cc8d43f968893c8e942e9bf cargo-$CARGO_V/src/rust-installer

# we need overrides for libc to fix a pthread issue with cargo
git clone https://github.com/mneumann/libc.git
cd libc
git checkout 9fe906c72ec90282f98ebfde500d5f19a03df478
cd ..

mkdir -p $DEST/.cargo
echo "paths = [\"$DEST/libc\"]" >> $DEST/.cargo/config

cd cargo-$CARGO_V
patch -p1 < $BASE/patches-cargo/$CARGO_V.patch

./configure --enable-build-openssl --local-rust-root=${BOOTSTRAP_COMPILER_BASE}
gmake
gmake dist

echo "$DEST/cargo-$CARGO_V/target/x86_64-unknown-dragonfly/release/dist"
