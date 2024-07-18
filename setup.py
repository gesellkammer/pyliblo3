#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from setuptools import setup, Extension
import platform 
import glob
import os
import shutil
import subprocess

VERSION = '0.14.0'

platformname = platform.system()

include_dirs, library_dirs = [], []
compile_args = []


def append_if_exists(lst: list[str], path: str) -> None:
    if os.path.exists(path):
        lst.append(path)
        print(f"~~~~~ Added path: {path}")
    else:
        print(f"***** Path does not exists, skipping: '{path}'")

print(f"**** Platform: {platformname}")

if platformname == 'Darwin':
    brewpath = shutil.which("brew")
    if brewpath:
        brewprefix = subprocess.getoutput("brew --prefix")
        append_if_exists(include_dirs, brewprefix + "/include")
        append_if_exists(library_dirs, brewprefix + "/lib")
    include_dirs.append("/usr/local/include/")
    append_if_exists(include_dirs, "/opt/local/include/")
        
    library_dirs.append("/usr/local/lib")
    append_if_exists(library_dirs, "/opt/local/lib")
        
    compile_args += [
        '-fno-strict-aliasing',
        '-Werror-implicit-function-declaration',
        '-Wfatal-errors'
    ]
elif platformname == 'Linux':
    include_dirs.extend(['/usr/include', '/usr/local/include'])
    library_dirs.append("/usr/local/lib")
    compile_args += [
        '-fno-strict-aliasing',
        '-Werror-implicit-function-declaration',
        '-Wfatal-errors'
    ]
elif platformname == "Windows":
    # Default install directory for liblo built from source
    append_if_exists(include_dirs, "C:/Program Files/liblo/include")
    append_if_exists(library_dirs, "C:/Program Files/liblo/lib")
else:
    pass

# read the contents of your README file
thisdir = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(thisdir, 'README.md')) as f:
    long_description = f.read()

setup(
    name='pyliblo3',
    python_requires='>=3.9',
    version=VERSION,
    scripts=glob.glob("scripts/*.py"),
    ext_modules=[
        Extension(
            'liblo', 
            #sources = ['src/liblo.pyx', 'src/liblo.pxd'],
            sources = ['src/liblo.pyx'],
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
