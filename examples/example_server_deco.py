#!/usr/bin/env python

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
    
