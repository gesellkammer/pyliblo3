#!/bin/bash
set -e -x

# Install a system package required by our library
# yum install -y
# yum install -y liblo-dev

yum install -y git
git clone https://github.com/radarsat1/liblo
cd liblo
./autogen.sh
make 
make install

# Compile wheels
for PYBIN in /opt/python/cp3[7-8]*/bin; do
    # "${PYBIN}/pip" install -r /io/dev-requirements.txt
    "${PYBIN}/pip" wheel /io/ -w wheelhouse/
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    auditwheel repair "$whl" --plat $PLAT -w /io/wheelhouse/
done

# Install packages and test
#for PYBIN in /opt/python/cp37*/bin/; do
#    "${PYBIN}/pip" install python-manylinux-demo --no-index -f /io/wheelhouse
    # (cd "$HOME"; "${PYBIN}/nosetests" pymanylinuxdemo)
#done
