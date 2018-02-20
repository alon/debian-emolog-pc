#!/bin/bash
# Build package for arm64
#
# Requirements:
# debootstraped machine in ROOT
# user with same UID (1000) as current user, called builder
# (those requirements can be automated away)
#
# NOTE: architecture is determined by the machine itself
# it runs using binfmts and the appropriate qemu-user-<arch>
# tested with arm64 (aarch64)
# this file is
ROOT=$HOME/machines/debian-arm64
GIT=../emolog/emolog_pc
ARCH=arm64

if [ "x$REPO" = "x" ]; then
    echo "export REPO=path/to/reprepro repository"
    exit -1
fi

if [ "x$REPO_DIST" = "x" ]; then
    echo export REPO_DIST=distribution
    exit -1
fi

if [ "x$REPO_REMOTE_TARGET" = "x" ]; then
    echo export REPO_REMOTE_TARGET=server:path
    exit -1
fi

if [ ! -e debian ]; then
    echo run from $(basename $0) directory
    exit -1
fi

GIT_VERSION=$(cd $GIT; python3 -c "import emolog; print('.'.join(map(str, emolog.VERSION)))")
VERSION=$(dpkg-parsechangelog | grep Version | sed -e 's/Version: //' | sed -e 's/-.*//')

if [ "$GIT_VERSION" != "$VERSION" ]; then
    echo "please update debian/changelog to $GIT_VERSION"
    exit -1
fi

# build package if not already there
NAME=emolog
SRC=$NAME-$VERSION.tar.gz
if [ ! -e $SRC ]; then
    if [ -e ../emolog/.git ]; then
        if [ ! -e ../emolog/emolog_pc/dist/$SRC ]; then
            (cd ../emolog/emolog_pc; python3 setup.py sdist)
        fi
        cp ../emolog/emolog_pc/dist/$SRC .
    fi
fi

if [ ! -e $SRC ]; then
    echo bailing out, missing $SRC
    exit -1
fi

PKG=$(pwd)
NSPAWN_ARM64_ARGS="--bind /usr/bin/qemu-aarch64 --bind /lib64"
sudo systemd-nspawn ${NSPAWN_ARM64_ARGS} -D $ROOT --bind $PKG:/home/builder/debian-build -u builder --chdir /home/builder/debian-build ./build.sh

VERSION_EPOCH=$(dpkg-parsechangelog | grep Version | sed -e 's/Version: //')
DEB=${NAME}_${VERSION_EPOCH}_all.deb # TODO: why does this not say ${ARCH}? it includes c compiled architecture specific shared objects

if [ ! -e $DEB ]; then
    echo "missing $DEB"
    exit -1
fi

reprepro -b $REPO includedeb $REPO_DIST $DEB
(
    cd $REPO/..
    rsync -avr debian $REPO_REMOTE_TARGET
)
