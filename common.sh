#
# Expected variables:
#
# * RUSTC_BOOTSTRAP_VERSION
# * CARGO_BOOTSTRAP_VERSION
# * RUST_VERSION
#
# * BASE
# * DEST
# * RELEASE_CHANNEL (defaults to "stable")
# * LLVM_ROOT (defaults to "")

if [ "$RUSTC_BOOTSTRAP_VERSION" = "" ]; then
	echo "No RUSTC_BOOTSTRAP_VERSION"
	exit 1
fi

if [ "$CARGO_BOOTSTRAP_VERSION" = "" ]; then
	echo "No CARGO_BOOTSTRAP_VERSION"
	exit 1
fi

if [ "$RUST_VERSION" = "" ]; then
	echo "No RUST_VERSION"
	exit 1
fi

if [ "$BASE" = "" ]; then
	echo "No BASE"
	exit 1
fi

if [ "$DEST" = "" ]; then
	echo "Usage: $0 target-dir"
	exit 1
fi

if [ "$RELEASE_CHANNEL" = "" ]; then
	RELEASE_CHANNEL=stable
fi

if [ "$RELEASE_CHANNEL" = "stable" ]; then
elif [ "$RELEASE_CHANNEL" = "dev" ]; then
else
	echo "Invalid RELEASE_CHANNEL: either stable or dev"
	exit 2
fi

if [ "$LLVM_ROOT" = "" ]; then
	echo "Use in-tree LLVM"
	LLVM_ROOT_OPT=""
else
	echo "Use LLVM tree: $LLVM_ROOT"
	LLVM_ROOT_OPT="--llvm-root=${LLVM_ROOT}"
fi

TARGET=x86_64-unknown-dragonfly
DEST_INSTALL=$DEST/install
COMPONENTS="cargo-${CARGO_BOOTSTRAP_VERSION} rust-std-${RUSTC_BOOTSTRAP_VERSION} rustc-${RUSTC_BOOTSTRAP_VERSION}"

# set path
export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin

# we need these to avoid patching the sources for sha256sum
export PATH=$PATH:$BASE/../bin

mkdir -p $DEST/bootstrap

BOOTSTRAP_COMPILER_BASE=`realpath $DEST/bootstrap`

if [ "x${BOOTSTRAP_COMPILER_BASE}" = "x" ]; then
	echo "No bootstrap compiler found"
	exit 1
fi

export LD_LIBRARY_PATH="${BOOTSTRAP_COMPILER_BASE}/lib:$LD_LIBRARY_PATH"

# for static cargo
export LIBSSH2_NO_PKG_CONFIG=1
export LIBCURL_NO_PKG_CONFIG=1
export LIBZ_NO_PKG_CONFIG=1 
export PROFILE=release
export LIBZ_SYS_STATIC=1
export OPENSSL_NO_PKG_CONFIG=1
export OPENSSL_LIB_DIR=$DEST/libressl/lib
export OPENSSL_INCLUDE_DIR=$DEST/libressl/include

clean() {
	rm -rf $DEST
}

libressl() {
	mkdir -p $DEST/libressl
	cd $DEST
	fetch https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-$1.tar.gz
	tar xvzf libressl-$1.tar.gz
	cd libressl-$1
	./configure --with-pic --prefix=$DEST/libressl
	make check
	make install
}

libressl-2.5.5() {
	libressl 2.5.5
}

extract() {
	mkdir -p $DEST/tmp $DEST/bootstrap
	cd $DEST

	for component in ${COMPONENTS}; do
		echo "INSTALL COMPONENT: ${component}"
		tar xvzf $BASE/bootstrap/$component-${TARGET}.tar.xz -C $DEST/tmp
		$DEST/tmp/$component-${TARGET}/install.sh --prefix=$DEST/bootstrap
	done


	fetch -o $DEST/rustc-$RUST_VERSION-src.tar.gz https://static.rust-lang.org/dist/rustc-$RUST_VERSION-src.tar.gz 
	tar xvzf $DEST/rustc-$RUST_VERSION-src.tar.gz 2>&1 | wc -l
}

prepatch() {
	cd $DEST/rustc-$RUST_VERSION-src
	if [ -d $BASE/patches ]; then
		for patch in $BASE/patches/patch-*; do
			echo $patch
			patch < $patch
		done
	fi
}

config() {
	cd $DEST/rustc-$RUST_VERSION-src
	./configure \
		--release-channel=${RELEASE_CHANNEL} \
		--enable-cargo-openssl-static --enable-extended \
		--enable-locked-deps --disable-jemalloc \
		--enable-local-rust --local-rust-root=${BOOTSTRAP_COMPILER_BASE} \
		--sysconfdir=${DEST_INSTALL}/etc \
		--prefix=${DEST_INSTALL} \
		${LLVM_ROOT_OPT}
}

postpatch() {
	cd $DEST/rustc-$RUST_VERSION-src
	if [ -d $BASE/patches/after-configure ]; then
		for patch in $BASE/patches/after-configure/patch-*; do
			echo $patch
			patch < $patch
		done
	fi
}

mk() {
	cd $DEST/rustc-$RUST_VERSION-src && gmake VERBOSE=YES $1
}

build() {
	mk all
}

dist() {
	mk dist
}

inst() {
	mk install
}

info() {
	echo Base: $BASE
	echo Release-Channel: $RELEASE_CHANNEL
	echo Dest: $DEST
	echo BOOTSTRAP_COMPILER_BASE: ${BOOTSTRAP_COMPILER_BASE}
	echo Path: $PATH
}

curlsys-0.3.14() {
	cd $DEST
	if [ ! -e curl-rust ]; then 
		git clone https://github.com/alexcrichton/curl-rust.git
	fi
	cd curl-rust
	git checkout -f curl-sys-0.3.14 || exit 5

	patch -p1 <<EOF
--- a/curl-sys/build.rs
+++ b/curl-sys/build.rs
@@ -172,7 +172,7 @@ fn main() {
     }
 
     cmd.arg("--without-librtmp");
-    cmd.arg("--without-libidn");
+    cmd.arg("--without-libidn2");
     cmd.arg("--without-libssh2");
     cmd.arg("--without-libpsl");
     cmd.arg("--disable-ldap");
@@ -224,7 +224,7 @@ fn fail(s: &str) -> ! {
 }
 
 fn make() -> Command {
-    let cmd = if cfg!(target_os = "freebsd") {"gmake"} else {"make"};
+    let cmd = if cfg!(target_os = "dragonfly") {"gmake"} else {"make"};
     let mut cmd = Command::new(cmd);
     // We're using the MSYS make which doesn't work with the mingw32-make-style
     // MAKEFLAGS, so remove that from the env if present.
EOF

	mkdir -p $DEST/.cargo
	echo "paths = [\"$DEST/curl-rust/curl-sys\"]" > $DEST/.cargo/config

	# Building curl-sys is not neccessary
	# cd curl-sys
	# PATH=${BOOTSTRAP_COMPILER_BASE}/bin:$PATH cargo build -j 1 --verbose
}

RUN() {
	for action in $*; do
		echo "-------------------------------------------"
		echo $action
		echo "-------------------------------------------"
		eval "$action || exit 1"
	done
}
