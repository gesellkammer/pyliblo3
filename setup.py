#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build logic that cannot be expressed declaratively in pyproject.toml.

All package metadata lives in pyproject.toml ([project] table). This file
only defines the platform-specific C extension for liblo.
"""
from setuptools import Extension, setup

import platform
import os
import shutil
import subprocess

from Cython.Build import cythonize

platformname = platform.system().lower()

include_dirs = ["pyliblo3"]
library_dirs = []
libraries = []
compile_args = []


def append_if_exists(lst: list[str], path: str) -> None:
    if os.path.exists(path):
        if path not in lst:
            lst.append(path)
            print(f"~~~~~ Added path: {path}")
    else:
        print(f"***** Path does not exist, skipping: '{path}'")


if platformname == 'darwin':
    libraries.append('lo')
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
elif platformname == 'linux':
    libraries.append('lo')
    include_dirs.extend(['/usr/include', '/usr/local/include'])
    append_if_exists(library_dirs, "/usr/local/lib")
    append_if_exists(library_dirs, "/usr/local/lib64")

    compile_args += [
        '-fno-strict-aliasing',
        '-Werror-implicit-function-declaration',
        '-Wfatal-errors'
    ]
elif platformname == "windows":
    libraries.append('liblo')
    # Default install directory for liblo built from source
    # See also the wheel build script where we add the .../lib and .../bin
    # directories so that the wheel repair script can find the liblo dll
    # to add it to the wheel. When building from source, the user needs
    # to install liblo and add its lib and bin directories to the path
    append_if_exists(include_dirs, "C:/Program Files/liblo/include")
    append_if_exists(library_dirs, "C:/Program Files/liblo/lib")
else:
    pass

setup(
    ext_modules=cythonize(
        [
            Extension(
                'pyliblo3._liblo',
                sources=['pyliblo3/_liblo.pyx'],
                extra_compile_args=compile_args,
                libraries=libraries,
                library_dirs=library_dirs,
                include_dirs=include_dirs)
        ],
        language_level=3,
        # Lets `from _liblo cimport *` in _liblo.pyx resolve
        # pyliblo3/_liblo.pxd (previously handled implicitly via
        # Extension include_dirs by setuptools' legacy .pyx support).
        include_path=["pyliblo3"],
    ),
)
