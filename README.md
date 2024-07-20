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

```python
from pyliblo3 import *
import time


class MyServer(ServerThread):
    def __init__(self, port=1234):
        ServerThread.__init__(self, port)

    @make_method('/foo', 'ifs')
    def foo_callback(self, path, args):
        i, f, s = args
        print(f"Received message '{path}' with arguments: {i=}, {f=}, {s=}")

    @make_method(None, None)
    def fallback(self, path, args):
        print(f"received unknown message '{path}' with {args=}")


server = MyServer()
server.start()
print(f"Server started in its own thread, send messages to {server.port}. Use CTRL-C to stop")

while True:
    send(("127.0.0.0", server.port), "/foo", 10, 1.5, "bar")
    send(("127.0.0.0", server.port), "/unknown", (3, 4))
    time.sleep(1)
    
```

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
mkdir macosbuild && cd macosbuild
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
cmake -A x64 -DCMAKE_GENERATOR_PLATFORM=x64 -DWITH_TESTS=OFF -DWITH_CPP_TESTS=OFF -DWITH_EXAMPLES=OFF -DWITH_TOOLS=OFF ../cmake
cmake --build . --config Release
cmake --install .
```

```bash
git clone https://github.com/gesellkammer/pyliblo3
cd pyliblo3
pip install .
```


