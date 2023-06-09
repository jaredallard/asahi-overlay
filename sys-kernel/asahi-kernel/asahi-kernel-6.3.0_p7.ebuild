# Copyright 2020-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# shellcheck shell=bash

# Inspired by:
# https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-kernel/gentoo-kernel/gentoo-kernel-6.3.3.ebuild
# https://github.com/Leo3418/leo3418-ebuild-repo/blob/2e063a35efb385b3f2831db875d4ee959615554a/sys-kernel/asahi-kernel/asahi-kernel-6.2_rc2_p1-r1.ebuild
# https://github.com/chadmed/asahi-overlay/blob/main/sys-kernel/asahi-sources/asahi-sources-6.2.0_p12.ebuild

EAPI=8

inherit kernel-build toolchain-funcs

if [[ ${PV} != "${PV/_rc/}" ]]; then
  # $PV is expected to be of following form: 6.0_rc5_p1
  MY_TAG="$(ver_cut 6)"
  MY_P="asahi-$(ver_rs 2 - "$(ver_cut 1-4)")-${MY_TAG}"
else
  # $PV is expected to be of following form: 5.19.0_p1
  MY_TAG="$(ver_cut 5)"
  MY_P="asahi-$(ver_cut 1-2)-${MY_TAG}"
fi

# PKGBUILD_COMMIT_SHA is the SHA used for fetching the kernel config files from
# the asahi linux PKGBUILDs repo.
# See: https://github.com/AsahiLinux/PKGBUILDs
PKGBUILD_COMMIT_SHA="dd6100bdba8e48d440d868cad89cd3b6ea7fa714"

DESCRIPTION="Asahi Linux Kernel for M1/2 Macs"
HOMEPAGE="https://github.com/AsahiLinux/linux"
SRC_URI+="
	https://github.com/AsahiLinux/linux/archive/refs/tags/${MY_P}.tar.gz -> ${PN}-${PV}.tar.gz
  https://raw.githubusercontent.com/AsahiLinux/PKGBUILDs/${PKGBUILD_COMMIT_SHA}/linux-asahi/config.edge -> asahi-edge.config
  https://raw.githubusercontent.com/AsahiLinux/PKGBUILDs/${PKGBUILD_COMMIT_SHA}/linux-asahi/config -> asahi.config
"
S="${WORKDIR}/linux-${MY_P}"

LICENSE="GPL-2"
KEYWORDS="arm64"
IUSE="+edge debug"

RDEPEND=""
BDEPEND="
  edge? (
    >=dev-lang/rust-1.69.0[rustfmt,rust-src]
    >=dev-util/bindgen-0.65.1
    >=media-libs/mesa-23.2.0_pre20230603
  )
  debug? ( dev-util/pahole )
"
PDEPEND="
	>=virtual/dist-kernel-${PV}
"

QA_FLAGS_IGNORED="
	usr/src/linux-.*/scripts/gcc-plugins/.*.so
	usr/src/linux-.*/vmlinux
	usr/src/linux-.*/arch/powerpc/kernel/vdso.*/vdso.*.so.dbg
"

src_prepare() {
  local PATCHES=(
    "${FILESDIR}"/*.patch
  )
  default

  # Use the asahi config as the default
  cp "${DISTDIR}"/asahi.config .config || die

  # Avoid "Kernel release mismatch" error from kernel-install_pkg_preinst
  # by adding required version components to a localversion* file, so users
  # can still set their own CONFIG_LOCALVERSION value in savedconfig or
  # /etc/kernel/config.d/*.config without getting the same error again
  if [[ ${PV} == *_p* ]]; then
    local localversion=""
    if [[ ${PV} == *_rc* ]]; then
      localversion+="_"
    else
      localversion+="-"
    fi
    localversion+="p${PV##*_p}"
    echo "${localversion}" >localversion.00-gentoo ||
      die "Failed to write local version preset"
  fi

  # Generate a config to override the localversion
  local myversion="-dist"
  echo "CONFIG_LOCALVERSION=\"${myversion}\"" >"${T}"/version.config || die

  local merge_configs=()

  # If we are building an edge kernel, merge in the edge config
  use edge && merge_configs+=("${DISTDIR}"/asahi-edge.config)

  merge_configs+=("${T}"/version.config)

  kernel-build_merge_configs "${merge_configs[@]}"
}

src_install() {
  # Override DTBs installation path for sys-apps/asahi-scripts::asahi
  export INSTALL_DTBS_PATH="${ED}/usr/src/linux-${PV}${KV_LOCALVERSION}/arch/$(tc-arch-kernel)/boot/dts"
  kernel-build_src_install
}

pkg_pretend() {
  # NOOP: We don't care about linux-firmware, so we override this to prevent
  # kernel-install_pkg_pretend from warning about it.
  return
}

pkg_postinst() {
  einfo "For more information about Asahi Linux please visit ${HOMEPAGE},"
  einfo "or consult the Wiki at https://github.com/AsahiLinux/docs/wiki."
  einfo
  ewarn "Please run update-m1n1 after every kernel update/install otherwise"
  ewarn "your system may not be bootable."
  kernel-build_pkg_postinst
}
