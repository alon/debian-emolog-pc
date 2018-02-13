#!/bin/bash
# Requirements:
# remote build host for wanted arch
if [ "x$REMOTE_HOST" = "x" ]; then
    echo "missing REMOTE_HOST environment variable"
    exit -1
fi

if [ "x$REMOTE_USER" = "x" ]; then
    echo "missing REMOTE_USER environment variable"
    exit -1
fi

if [ "x$REMOTE_ROOT" = "x" ]; then
    echo "missing REMOTE_ROOT environment variable"
    exit -1
fi


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

DEB=${NAME}_${VERSION}-1_all.deb
REMOTE=$REMOTE_USER@$REMOTE_HOST
scp $SRC $REMOTE:$REMOTE_ROOT
git push
ssh $REMOTE "cd $REMOTE_ROOT; git pull --rebase; ./build.sh"
scp $REMOTE:$REMOTE_ROOT/$DEB .

if [ ! -e $DEB ]; then
    echo "missing $DEB"
    exit -1
fi

reprepro -b $REPO includedeb $REPO_DIST $DEB
(
    cd $REPO/..
    rsync -avr debian REPO_REMOTE_TARGET
)
