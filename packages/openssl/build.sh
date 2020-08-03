TERMUX_PKG_HOMEPAGE=https://www.openssl.org/
TERMUX_PKG_DESCRIPTION="Library implementing the SSL and TLS protocols as well as general purpose cryptography functions"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
_VERSION=3.0.7
TERMUX_PKG_VERSION=1:${_VERSION}
TERMUX_PKG_SRCURL=https://www.openssl.org/source/openssl-${_VERSION/\~/-}.tar.gz
TERMUX_PKG_SHA256=83049d042a260e696f62406ac5c08bf706fd84383f945cf21bd61e9ed95c396e
TERMUX_PKG_DEPENDS="ca-certificates, zlib"
TERMUX_PKG_CONFFILES="etc/tls/openssl.cnf"
TERMUX_PKG_RM_AFTER_INSTALL="bin/c_rehash etc/ssl/misc"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_CONFLICTS="libcurl (<< 7.61.0-1)"
TERMUX_PKG_BREAKS="openssl-tool (<< 1.1.1b-1), openssl-dev"
TERMUX_PKG_REPLACES="openssl-tool (<< 1.1.1b-1), openssl-dev"

termux_step_configure() {
	CFLAGS+=" -DNO_SYSLOG"

	perl -p -i -e "s@TERMUX_CFLAGS@$CFLAGS@g" Configure

	test $TERMUX_ARCH = "arm" && TERMUX_OPENSSL_PLATFORM="android-arm"
	test $TERMUX_ARCH = "aarch64" && TERMUX_OPENSSL_PLATFORM="android-arm64"
	test $TERMUX_ARCH = "i686" && TERMUX_OPENSSL_PLATFORM="android-x86"
	test $TERMUX_ARCH = "x86_64" && TERMUX_OPENSSL_PLATFORM="android-x86_64"
	./Configure $TERMUX_OPENSSL_PLATFORM \
		--prefix=$TERMUX_PREFIX \
		--openssldir=$TERMUX_PREFIX/etc/tls \
		shared \
		zlib-dynamic \
		no-ssl \
		no-hw \
		no-srp \
		no-tests
}

termux_step_post_configure() {
	make depend
}

termux_step_make_install() {
	# "install_sw" instead of "install" to not install man pages:
	make -j 1 install_sw MANDIR=$TERMUX_PREFIX/share/man MANSUFFIX=.ssl

	mkdir -p $TERMUX_PKG_MASSAGEDIR/$TERMUX_PREFIX/etc/tls/

	cp apps/openssl.cnf $TERMUX_PKG_MASSAGEDIR/$TERMUX_PREFIX/etc/tls/openssl.cnf

	sed "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" \
		$TERMUX_PKG_BUILDER_DIR/add-trusted-certificate \
		> $TERMUX_PKG_MASSAGEDIR/$TERMUX_PREFIX/bin/add-trusted-certificate
	chmod 700 $TERMUX_PKG_MASSAGEDIR/$TERMUX_PREFIX/bin/add-trusted-certificate
}
