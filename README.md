# pyliblo3 

This is a fork of the original bindings for liblo, making it pip installable.

As of version 0.16 the provided wheels include the ``liblo`` library
and don't have any further dependencies.


## Example

### Simple blocking server

```python

import pyliblo3 as liblo
server = liblo.Server(8080)

def test_handler(path, args, types, src):
    print(args)
    
server.add_method("/test", None, test_handler)

while True:
    server.recv(100)
```

### Threaded server

TODO

----------------------


## Installation


```bash

pip install pyliblo3

```

## Installation from source

When installing from source, ``liblo`` needs to be installed.

#### Linux

```bash
sudo apt install liblo-dev

git clone https://github.com/gesellkammer/pyliblo3
cd pyliblo3
pip install .
```

#### MacOS

First install liblo

```bash
brew install liblo

```

Or, without using brew:

```bash
git clone https://github.com/radarsat1/liblo
cd liblo
mkdir macosbuild
cd macosbuild
cmake -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" ../cmake
cmake --build . --config Release
sudo cmake --install .
```

Then install pyliblo3

```bash
git clone https://github.com/gesellkammer/pyliblo3
cd pyliblo3
pip install .
```

#### Windows

```bash
git clone https://github.com/radarsat1/liblo
cd liblo
New-Item -ItemType Directory -Force -Path "windowsbuild"
cd windowsbuild
cmake -A x64 -DCMAKE_GENERATOR_PLATFORM=x64 -DCMAKE_BUILD_TYPE=Release -DWITH_TESTS=OFF -DWITH_CPP_TESTS=OFF -DWITH_EXAMPLES=OFF -DWITH_TOOLS=OFF ../cmake
cmake --build . --config Release
Get-ChildItem -Recurse
cmake --install .
```

```bash
git clone https://github.com/gesellkammer/pyliblo3
cd pyliblo3
pip install .
```


