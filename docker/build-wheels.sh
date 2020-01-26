#!/bin/bash
set -e -x

git clone https://github.com/radarsat1/liblo
cd liblo
./autogen.sh
make 
make install

# Compile wheels
for PYBIN in /opt/python/cp3[7-8]*/bin; do
    "${PYBIN}/pip" wheel /io/ -w wheelhouse/
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    auditwheel repair "$whl" --plat $PLAT -w /io/wheelhouse/
done

TWINE_USERNAME=__token__
TWINE_PASSWORD="pypi-AgEIcHlwaS5vcmcCJDVmYjQ3MWVhLTJlYzUtNGQ0Ni1iNDNlLTA4ZDM5OGI5NzM5ZAACJXsicGVybWlzc2lvbnMiOiAi
dXNlciIsICJ2ZXJzaW9uIjogMX0AAAYgRZ51c6JWwr8L8fKEp03VmrbEFFpqPZDUxg8govB6b4Y"
PYTHON3=/opt/python/cp38-cp38/bin/python

if [[ $TRAVIS_TAG ]]; then
    "$PYTHON3" -m pip install twine    
    "$PYTHON3" -m twine upload --skip-existing /io/wheelhouse/*.whl
fi
