#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from setuptools import setup, Extension
import platform as _platform
import glob

platform = _platform.system()

include_dirs, library_dirs = [], []

if platform == 'Darwin':
    include_dirs.append("/usr/local/include/")
    library_dirs.append("/usr/local/lib")
elif platform == 'Linux':
    include_dirs.append("/usr/local/include/")
    library_dirs.append("/usr/local/lib")


setup(
    name = 'pyliblo3',
    python_requires='>=3.6',
    version = '0.9.2',
    scripts = glob.glob("scripts/*.py"),
    ext_modules = [
        Extension(
            'liblo',
            ['src/liblo.pyx'],
            extra_compile_args = [
                '-fno-strict-aliasing',
                '-Werror-implicit-function-declaration',
                '-Wfatal-errors',
            ],
            libraries = ['lo'],
            library_dirs=library_dirs,
            include_dirs=include_dirs    
        )
    ],
    setup_requires=['setuptools>=18', 'cython'],

    author = 'Dominic Sacre',
    author_email = 'dominic.sacre@gmx.de',
    maintainer = 'Eduardo Moguillansky',
    maintainer_email = 'eduardo.moguillansky@gmail.com',
    url = 'https://github.com/gesellkammer/pyliblo3', 
    description = 'Python bindings for the liblo OSC library',
    license = 'LGPL',
    
)
