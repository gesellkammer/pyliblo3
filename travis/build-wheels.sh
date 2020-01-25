#!/bin/bash
set -e -x

# Install a system package required by our library
# yum install -y
yum install -y liblo-dev

# Compile wheels
#for PYBIN in /opt/python/*/bin; do
    # "${PYBIN}/pip" install -r /io/dev-requirements.txt
#    "${PYBIN}/pip" wheel /io/ -w wheelhouse/
#done
pip3 wheel /ui/ -w wheelhouse/

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    auditwheel repair "$whl" --plat $PLAT -w /io/wheelhouse/
done

# Install packages and test
#for PYBIN in /opt/python/*/bin/; do
#    "${PYBIN}/pip" install python-manylinux-demo --no-index -f /io/wheelhouse
#    (cd "$HOME"; "${PYBIN}/nosetests" pymanylinuxdemo)
#done
pip3 install python-manylinux-demo --no-index -f /io/wheelhoise
