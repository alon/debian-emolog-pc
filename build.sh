#WIP building of debian package for emolog.

#So far:
#in emolog:
#python setup.py sdist

#Then here:
EMOLOG=../emolog/emolog_pc
SRC=$EMOLOG/dist/emolog-0.1.tar.gz
if [ ! -e $SRC ]; then
    echo "cd _emolog_; python setup.py sdist"
    echo "set EMOLOG or SRC in this file to _emolog_ or the tarball"
    exit -1
fi
tar xvzf $SRC
cd emolog-0.1
ln -sf ../debian .
dpkg-buildpackage -sa
