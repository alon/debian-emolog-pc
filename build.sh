#WIP building of debian package for emolog.

#So far:
#in emolog:
#python setup.py sdist

#Then here:
VERSION=$(dpkg-parsechangelog | grep Version | sed -e 's/Version: //' | sed -e 's/-.*//')
NAME=emolog
SRC=$NAME-$VERSION.tar.gz
if [ ! -e $SRC ]; then
    echo "cd _emolog_; python setup.py sdist"
    echo "set SRC to the tarball"
    exit -1
fi
tar xvzf $SRC
cd $NAME-$VERSION
ln -sf ../debian .
dpkg-buildpackage -sa
