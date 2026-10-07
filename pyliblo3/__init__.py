from __future__ import absolute_import
import platform
import os
from importlib.metadata import PackageNotFoundError, version as _pkg_version

if platform.system() == "Windows":
    libspath = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, 'pyliblo3.libs'))
    if os.path.exists(libspath) and os.path.isdir(libspath):
        os.add_dll_directory(libspath)
    else:
        possible_paths = ['C:/Program Files/liblo/lib', 'C:/Program Files/liblo/bin']
        for path in possible_paths:
            if os.path.exists(path) and os.path.isdir(path):
                os.add_dll_directory(path)
del platform
del os


from ._liblo import *
from ._liblo import __all__ as _ext_all

try:
    __version__ = _pkg_version("pyliblo3")
except PackageNotFoundError:  # source checkout without install
    __version__ = "unknown"

__all__ = [*_ext_all, "__version__"]

del _ext_all, _pkg_version, PackageNotFoundError
