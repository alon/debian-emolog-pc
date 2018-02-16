#!/bin/bash
# Requirements:
# debootstrap buster in /
# user with same UID (1000) as current user, called builder
ROOT=$HOME/machines/debian-buster

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

# build package if not already there
VERSION=$(dpkg-parsechangelog | grep Version | sed -e 's/Version: //' | sed -e 's/-.*//')
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
sudo systemd-nspawn -D $ROOT --bind=$PKG:/home/builder/debian-emolog -u builder --chdir /home/builder/debian-emolog ./build.sh

DEB=${NAME}_${VERSION}-1_all.deb

if [ ! -e $DEB ]; then
    echo "missing $DEB"
    exit -1
fi

reprepro -b $REPO includedeb $REPO_DIST $DEB
(
    cd $REPO/..
    rsync -avr debian REPO_REMOTE_TARGET
)
