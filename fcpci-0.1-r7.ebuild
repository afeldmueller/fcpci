# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit eutils rpm linux-mod

DESCRIPTION="AVM Fritz!Card PCI modules"
HOMEPAGE="https://raw.githubusercontent.com/afeldmueller/fcpci/"
SRC_URI="https://raw.githubusercontent.com/afeldmueller/fcpci/master/files/${P}-0.src.rpm"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="!net-dialup/fritzcapi"
RDEPEND="${DEPEND} net-dialup/capi4k-utils"

RESTRICT="primaryuri"

S="${WORKDIR}/fritz"

pkg_setup() {
	linux-mod_pkg_setup

	if ! kernel_is ge 2 6 ; then
		die "This package works only with 2.6/3.0+ kernel!"
	fi

	BUILD_TARGETS="all"
	BUILD_PARAMS="KDIR=${KV_DIR} LIBDIR=${S}/src"
	MODULE_NAMES="${PN}(net:${S}/src)"
}

src_unpack() {
	local BIT="" PAT="012345"
	if use amd64; then
		BIT="64bit-" PAT="1234"
	fi

	if kernel_is ge 2 6 31 ; then
		PAT="${PAT}67"
	fi

	rpm_src_unpack ${A} || die "failed to unpack ${A} file"
	DISTDIR="${WORKDIR}" unpack ${PN}-suse[0-9][0-9]-${BIT}[0-9].[0-9]*-[0-9]*.tar.gz

	cd "${S}"
	epatch $(sed -n "s|^Patch[${PAT}]:\s*\(.*\)|../\1|p" ../${PN}.spec)

	if kernel_is ge 2 6 34 ; then
		epatch "${FILESDIR}"/fcpci-kernel-2.6.34.patch
	fi

	if kernel_is ge 2 6 39 ; then
		if use amd64; then
			epatch "${FILESDIR}"/fcpci-kernel-2.6.39-amd64.patch
		else
			epatch "${FILESDIR}"/fcpci-kernel-2.6.39.patch
		fi
	fi

	if kernel_is ge 3 2 0 ; then
		epatch "${FILESDIR}"/fcpci-kernel-3.2.0.patch
	fi

	convert_to_m src/Makefile

	for i in lib/*-lib.o; do
		einfo "Localize symbols in ${i##*/} ..."
		objcopy -L memcmp -L memcpy -L memmove -L memset -L strcat \
			-L strcmp -L strcpy -L strlen -L strncmp -L strncpy "${i}"
	done
}

src_install() {
	linux-mod_src_install
	dodoc CAPI*.txt
	dohtml *.html
}
