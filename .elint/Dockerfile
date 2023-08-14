# This image is used as the base image for running Manifest validations.
FROM gentoo/stage3:latest

LABEL org.opencontainers.image.source https://github.com/getoutreach/overlay

# run emerge-webrsync to download the latest portage tree. This is
# required to run ebuild commands as eclasses are distributed along with
# the portage tree. We run this once to prevent hitting mirrors
# excessively.
RUN emerge-webrsync