#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from setuptools import setup, Extension
import platform 
import glob
import os

VERSION = '0.13.0'

platform = platform.system()

include_dirs, library_dirs = [], []
compile_args = []

if platform == 'Darwin':
    include_dirs.append("/usr/local/include/")
    include_dirs.append("/opt/local/include/")
        
    library_dirs.append("/usr/local/lib")
    library_dirs.append("/opt/local/lib")
        
    compile_args += [
        '-fno-strict-aliasing',
        '-Werror-implicit-function-declaration',
        '-Wfatal-errors'
    ]
elif platform == 'Linux':
    include_dirs.extend(['usr/include', '/usr/local/include'])
    library_dirs.append("/usr/local/lib")
    compile_args += [
        '-fno-strict-aliasing',
        '-Werror-implicit-function-declaration',
        '-Wfatal-errors'
    ]
else:
    pass

# read the contents of your README file
thisdir = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(thisdir, 'README.md')) as f:
    long_description = f.read()

setup(
    name='pyliblo3',
    python_requires='>=3.8',
    version=VERSION,
    scripts=glob.glob("scripts/*.py"),
    ext_modules=[
        Extension(
            'liblo', 
            sources = ['src/liblo.pyx', 'src/liblo.pxd'],
            extra_compile_args=compile_args,
            libraries=['lo'],
            library_dirs=library_dirs,
            include_dirs=include_dirs)
    ],
    setup_requires=['setuptools>=18', 'cython'],
    install_requires=['cython'],
    author='Dominic Sacre',
    author_email='dominic.sacre@gmx.de',
    maintainer='Eduardo Moguillansky',
    maintainer_email='eduardo.moguillansky@gmail.com',
    url='https://github.com/gesellkammer/pyliblo3',
    description='Python bindings for the liblo OSC library',
    long_description=long_description,
    long_description_content_type='text/markdown',
    license='LGPL',
)
