# cython: embedsignature=True
#
# pyliblo3 - Python bindings for the lublo OSC library, based on pyliblo
#
# Original copyright:
#
# pyliblo - Python bindings for the liblo OSC library
#
# Copyright (C) 2007-2015  Dominic Sacré  <dominic.sacre@gmx.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#

__version__ = '0.16.1'


from cpython cimport PY_VERSION_HEX
cdef extern from 'Python.h':
    void PyEval_InitThreads()

from libc.stdlib cimport malloc, free
from libc.math cimport modf
from libc.stdint cimport int32_t, int64_t

from _liblo cimport *

import inspect as _inspect
import weakref as _weakref


def _protostr_to_int(str proto):
    if proto == 'UDP':
        return LO_UDP
    elif proto == 'TCP':
        return LO_TCP
    elif proto == 'UNIX':
        return LO_UNIX
    else:
        raise ValueError(f"Proto {proto} not understood, expected one of 'UDP', 'TCP' or 'UNIX'")


class _weakref_method:
    """
    Weak reference to a function, including support for bound methods.
    """
    __slots__ = ('_func', 'obj')

    def __init__(self, f):
        if _inspect.ismethod(f):
            self._func = f.__func__
            self.obj = _weakref.ref(f.__self__)
        else:
            self._func = f
            self.obj = None

    @property
    def func(self):
        if self.obj:
            return self._func.__get__(self.obj(), self.obj().__class__)
        else:
            return self._func

    def __call__(self, *args, **kwargs):
        return self.func(*args, **kwargs)


class struct:
    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)


cdef class Callback:
    """
    Used internally to wrap a python function as a callback

    Args:
        func: the function to call
        user_data: any python object, will be passed to the callback as the last argument
    """
    cdef object func
    cdef object user_data
    cdef int numargs
    cdef int has_varargs

    def __init__(self, func, user_data):
        self.func = _weakref_method(func)
        self.user_data = user_data,
        spec = _inspect.getfullargspec(func)
        numargs = len(spec.args)
        if _inspect.ismethod(func):
            numargs -= 1
        self.numargs = numargs
        self.has_varargs = 1 if spec.varargs is not None else 0
        

cdef inline str _decode(s):
    # convert to standard string type, depending on python version
    if PY_VERSION_HEX >= 0x03000000 and isinstance(s, bytes):
        return s.decode()
    else:
        return s

cdef bytes _encode(s):
    # convert unicode to bytestring
    if isinstance(s, unicode):
        return s.encode()
    else:
        return s


# forward declarations
cdef class _ServerBase
cdef class Address
cdef class Message
cdef class Bundle


# liblo protocol constants
UDP  = LO_UDP
TCP  = LO_TCP
UNIX = LO_UNIX


################################################################################
#  timetag
################################################################################

cdef lo_timetag _double_to_timetag(double f):
    cdef lo_timetag tt
    cdef double intr, frac
    frac = modf(f, &intr)
    tt.sec = <uint32_t>intr
    tt.frac = <uint32_t>(frac * 4294967296.0)
    return tt

cdef double _timetag_to_double(lo_timetag tt):
    return <double>tt.sec + (<double>(tt.frac) / 4294967296.0)

def time():
    """
    Return the current time as a floating point number (seconds since January 1, 1900).

    Returns:
        (float) The liblo timetag as a float, representing seconds since 1900
    """
    cdef lo_timetag tt
    lo_timetag_now(&tt)
    return _timetag_to_double(tt)


################################################################################
#  send
################################################################################

cdef _send(target, _ServerBase src, args):
    cdef lo_server from_server
    cdef Address target_address
    cdef int r

    # convert target to Address object, if necessary
    if isinstance(target, Address):
        target_address = target
    elif isinstance(target, tuple):
        # unpack tuple
        target_address = Address(*target)
    else:
        target_address = Address(target)

    # 'from' parameter is NULL if no server was specified
    from_server = src._server if src else NULL

    if isinstance(args[0], (Message, Bundle)):
        # args is already a list of Messages/Bundles
        packets = args
    else:
        # make a single Message from all arguments
        packets = [Message(*args)]

    # send all packets
    for p in packets:
        if isinstance(p, Message):
            message = <Message> p
            r = lo_send_message_from(target_address._address,
                                     from_server,
                                     message._path,
                                     message._message)
        else:
            bundle = <Bundle> p
            r = lo_send_bundle_from(target_address._address,
                                    from_server,
                                    bundle._bundle)

        if r == -1:
            raise IOError("sending failed: %s" %
                          <char*>lo_address_errstr(target_address._address))


def send(target, *args):
    """
    Send a message without requiring a server

    The function has two forms:

    * `send(target, *messages)`
    * `send(target, path, *args)`

    Send messages to the the given target, without requiring a server.
    Arguments may be one or more `Message` or `Bundle` objects,
    or a single message given by its path and optional arguments.

    Args:
        target (Address | tuple[str, int] | int | str): the address to send the message to;
            an `Address` object, a port number, a `(hostname, port)` tuple, or a URL.
        path (str): the path of the message to be sent
        args (Any): the information to send. These are used to construct a message
        messages (Message | Bundle): one or more objects of type `Message` or `Bundle`.

    Raises:
        AddressError: if the given target is invalid
        IOError: if the message couldn't be sent.
    """
    _send(target, None, args)


################################################################################
#  Server
################################################################################

class ServerError(Exception):
    """
    Raised when creating a liblo OSC server fails.
    """
    def __init__(self, num, msg, where):
        self.num = num
        self.msg = msg
        self.where = where

    def __str__(self):
        s = "server error %d" % self.num
        if self.where: s += " in %s" % self.where
        s += ": %s" % self.msg
        return s


cdef int _msg_callback(const_char *path, const_char *types, lo_arg **argv,
                       int argc, lo_message msg, void *cb_data) noexcept with gil:
    cdef int i
    cdef char t
    cdef unsigned char *ptr
    cdef uint32_t size, j

    args = []

    for i from 0 <= i < argc:
        t = types[i]
        if   t == 'i': v = argv[i].i
        elif t == 'h': v = argv[i].h
        elif t == 'f': v = argv[i].f
        elif t == 'd': v = argv[i].d
        elif t == 'c': v = chr(argv[i].c)
        elif t == 's': v = _decode(&argv[i].s)
        elif t == 'S': v = _decode(&argv[i].s)
        elif t == 'T': v = True
        elif t == 'F': v = False
        elif t == 'N': v = None
        elif t == 'I': v = float('inf')
        elif t == 'm': v = (argv[i].m[0], argv[i].m[1], argv[i].m[2], argv[i].m[3])
        elif t == 't': v = _timetag_to_double(argv[i].t)
        elif t == 'b':
            v = bytes(<unsigned char*>lo_blob_dataptr(<lo_blob>argv[i]))
        else:
            v = None  # unhandled data type

        args.append(v)

    cdef char *url = lo_address_get_url(lo_message_get_source(msg))
    src = Address(url)
    free(url)

    cb = <Callback>cb_data
    
    func_args = (_decode(<char*>path),
                 args,
                 _decode(<char*>types),
                 src,
                 cb.user_data)

    # call function
    # spec = _inspect.getfullargspec(func)
    if cb.has_varargs == 1:
        r = cb.func(*func_args)
    else:
        r = cb.func(*func_args[0:cb.numargs])
    
    return r if r is not None else 0


cdef int _bundle_start_callback(lo_timetag t, void *cb_data) noexcept with gil:
    cb = <object>cb_data
    r = cb.start_func(_timetag_to_double(t), cb.user_data)
    return r if r is not None else 0


cdef int _bundle_end_callback(void *cb_data) noexcept with gil:
    cb = <object>cb_data
    r = cb.end_func(cb.user_data)
    return r if r is not None else 0


cdef void _err_handler(int num, const_char *msg, const_char *where) noexcept with gil:
    # can't raise exception in cdef callback function, so use a global variable
    # instead
    global __exception
    __exception = ServerError(num, <char*>msg, None)
    if where: __exception.where = <char*>where


# decorator to register callbacks

class make_method:
    """
    A decorator that serves as a more convenient alternative to [Server.add_method](#add_method).

    Args:
        path (str | None): the message path to be handled by the registered method.
            `None` may be used as a wildcard to match any OSC message.
        types (str): the argument types to be handled by the registered method.
            `None` may be used as a wildcard to match any OSC message.
        user_data: An arbitrary object that will be passed on to the decorated
            method every time a matching message is received.

    """
    # counter to keep track of the order in which the callback functions where
    # defined
    _counter = 0

    def __init__(self, path, types, user_data=None):
        self.spec = struct(counter=make_method._counter,
                           path=path,
                           types=types,
                           user_data=user_data)
        make_method._counter += 1

    def __call__(self, f):
        # we can't access the Server object here, because at the time the
        # decorator is run it doesn't even exist yet, so we store the
        # path/typespec in the function object instead...
        if not hasattr(f, '_method_spec'):
            f._method_spec = []
        f._method_spec.append(self.spec)
        return f


# common base class for both Server and ServerThread

cdef class _ServerBase:
    cdef lo_server _server
    cdef list _keep_refs

    def __init__(self, reg_methods=True):
        self._keep_refs = []

        if reg_methods:
            self.register_methods()

    cdef _check(self):
        if self._server == NULL:
            raise RuntimeError("Server method called after free()")

    def register_methods(self, obj=None):
        """
        Called internally during init if reg_methods is True

        Args:
            obj: The object that implements the OSC callbacks to be registered.
                By default this is the server object itself.

        This function is usually called automatically by the server's
        constructor, unless its *reg_methods* parameter was set to `False`.
        """
        if obj == None:
            obj = self
        # find and register methods that were defined using decorators
        methods = []
        for m in _inspect.getmembers(obj):
            if hasattr(m[1], '_method_spec'):
                for spec in m[1]._method_spec:
                    methods.append(struct(spec=spec, name=m[1]))
        # sort by counter
        methods.sort(key=lambda x: x.spec.counter)
        for e in methods:
            self.add_method(e.spec.path, e.spec.types, e.name, e.spec.user_data)

    def get_url(self):
        """
        Returns the url of the server

        Returns:
            (str) url of the server
        """
        self._check()
        cdef char *tmp = lo_server_get_url(self._server)
        cdef object r = tmp
        free(tmp)
        return _decode(r)

    def get_port(self):
        """
        Returns the port number of this server

        Returns:
            (int) port number
        """
        self._check()
        return lo_server_get_port(self._server)

    def get_protocol(self):
        """
        Returns the protocol of this server, as an int

        This will be one of `LO_TCP`, `LO_TCP` or `LO_UNIX`

        Returns:
            (int) the protocol as an int
        """
        self._check()
        return lo_server_get_protocol(self._server)

    def fileno(self):
        """
        Return the file descriptor of the server socket

        Returns:
            (int) the file descriptor, or -1 if not supported by the underlying server protocol
        """
        self._check()
        return lo_server_get_socket_fd(self._server)

    def add_method(self, str path, str typespec, func, user_data=None):
        """
        Register a callback for OSC messages with matching path and argument types.

        Args:
            path (str): the message path to be handled by the registered method.
                `None` may be used as a wildcard to match any OSC message.
            typespec (str): the argument types to be handled by the registered method.
                `None` may be used as a wildcard to match any OSC message.
            func: the callback function.  This may be a global function, a class
                method, or any other callable object, pyliblo will know what
                to do either way.
            user_data: An arbitrary object that will be passed on to *func* every time
                a matching message is received.
        """
        cdef char *p
        cdef char *t

        if isinstance(path, (bytes, unicode)):
            s = _encode(path)
            p = s
        elif path is None:
            p = NULL
        else:
            raise TypeError("path must be a string or None")

        if isinstance(typespec, (bytes, unicode)):
            s2 = _encode(typespec)
            t = s2
        elif typespec is None:
            t = NULL
        else:
            raise TypeError("typespec must be a string or None")

        self._check()

        # use a weak reference if func is a method, to avoid circular
        # references in cases where func is a method of an object that also
        # has a reference to the server (e.g. when deriving from the Server
        # class)
        # cb = struct(func=_weakref_method(func), user_data=user_data)
        cb = Callback(func, user_data)
        # keep a reference to the callback data around
        self._keep_refs.append(cb)

        lo_server_add_method(self._server, p, t, _msg_callback, <void*>cb)

    def del_method(self, path, typespec=None):
        """
        Delete a callback function

        Delete a callback function.  For both *path* and *typespec*, `None`
        may be used as a wildcard.

        Args:
            path (str | None): the method to delete
            typespec (str | None): the typespec to match, or None to delete any
                method matching the given path
        """
        cdef char *p
        cdef char *t

        if isinstance(path, (bytes, unicode)):
            s = _encode(path)
            p = s
        elif path == None:
            p = NULL
        else:
            raise TypeError("path must be a string or None")

        if isinstance(typespec, (bytes, unicode)):
            s2 = _encode(typespec)
            t = s2
        elif typespec == None:
            t = NULL
        else:
            raise TypeError("typespec must be a string or None")

        self._check()
        lo_server_del_method(self._server, p, t)

    def add_bundle_handlers(self, start_handler, end_handler, user_data=None):
        """
        Add bundle notification handlers.

        Args:
            start_handler: a callback which fires when at the start of a bundle. This is
                called with the bundle's timestamp and user_data.
            end_handler: a callback which fires when at the end of a bundle. This is called
                with user_data.
            user_data: data to pass to the handlers.

        """
        cb_data = struct(start_func=_weakref_method(start_handler),
                         end_func=_weakref_method(end_handler),
                         user_data=user_data)
        self._keep_refs.append(cb_data)

        lo_server_add_bundle_handlers(self._server, _bundle_start_callback,
                                      _bundle_end_callback, <void*>cb_data)

    def send(self, target, *args):
        """
        Send a message or bundle from this server to the the given target.

        * `send(target, *messages)`
        * `send(target, path, *args)`

        Send a message or bundle from this server to the the given target.
        Arguments may be one or more `Message` or `Bundle`
        objects, or a single message given by its path and optional arguments.

        Args:
            target (Address | tuple[str, int] | str): the address to send the message to;
                an `Address` object, a port number, a `(hostname, port)` tuple, or a URL.
            messages (Message | Bundle): one or more objects of type `Message` or `Bundle`.
            path (str): the path of the message to be sent.

        Raises:
            AddressError: if the given target is invalid.
            IOError: if the message couldn't be sent.
        """
        self._check()
        _send(target, self, args)

    property url:
        """
        The server's URL.
        """
        def __get__(self):
            return self.get_url()

    property port:
        """
        The server's port number (int)
        """
        def __get__(self):
            return self.get_port()

    property protocol:
        """
        The server's protocol (one of the constants `LO_UDP`, `LO_TCP` or `LO_UNIX`).
        """
        def __get__(self):
            return self.get_protocol()


cdef class Server(_ServerBase):
    """
    A server that can receive OSC messages, blocking

    Use [ServerThread](#ServerThread) for an OSC server that runs in its own thread
    and never blocks.

    Args:
        port (int | None): a decimal port number or a UNIX socket path.  If omitted, an
            arbitrary free UDP port will be used.
        proto (int | str): one of LO_UDP, LO_TCP, LO_UNIX or LO_DEFAULT, or one of the
            strings 'UDP', 'TCP', 'UNIX'
        reg_methods (bool): if True, register any methods decorated with the [make_method](#make_method)
            decorator

        Raises:
            ServerError: if an error occurs created the underlying liblo server

    """
    def __init__(self, port=None, proto=LO_DEFAULT, reg_methods=True):
        cdef char *cs

        if port != None:
            p = _encode(str(port));
            cs = p
        else:
            cs = NULL

        if isinstance(proto, str):
            proto = _protostr_to_int(proto)

        global __exception
        __exception = None
        self._server = lo_server_new_with_proto(cs, proto, _err_handler)
        if __exception:
            raise __exception

        _ServerBase.__init__(self, reg_methods=reg_methods)

    def __dealloc__(self):
        self.free()

    def free(self):
        """
        Free the underlying server object and close its port.

        Note that this will also happen automatically when the server is deallocated.
        """
        if self._server:
            lo_server_free(self._server)
            self._server = NULL

    def recv(self, timeout=None):
        """
        Receive and dispatch one OSC message.

        Blocking by default, unless *timeout* is specified.

        Args:
            timeout (int, float): Time in milliseconds after which the function returns if no
                messages have been received. May be 0, in which case the function always returns
                immediately, whether messages have been received or not.

        Returns:
            (bool) `True` if a message was received, otherwise `False`.
        """
        cdef int t, r
        self._check()
        if timeout != None:
            t = timeout
            with nogil:
                r = lo_server_recv_noblock(self._server, t)
            return r and True or False
        else:
            with nogil:
                lo_server_recv(self._server)
            return True


cdef class ServerThread(_ServerBase):
    """
    Server running in a thread

    Unlike `Server`, `ServerThread` uses its own thread which
    runs in the background to dispatch messages. `ServerThread`
    has the same methods as `Server`, with the
    exception of `.recv`. Instead, it defines two additional
    methods `.start` and `.stop`.

    Args:
        port (int | str): a decimal port number or a UNIX socket path. If omitted, an
            arbitrary free UDP port will be used.
        proto (int | str): one of the constants `LO_UDP`, `LO_TCP` or `LO_UNIX` or
            a corresponding string 'UDP', 'TCP', 'UNIX'
        reg_methods: if True, register any method decorated with the [make_method](#make_method)
            decorator

    Raises:
        ServerError: if creating the server fails, e.g. because the given port could not
            be opened.

    !!! note

        Because liblo creates its own thread to receive and dispatch
        messages, callback functions will not be run in the main Python
        thread!

    """
    cdef lo_server_thread _server_thread

    def __init__(self, port=None, proto=LO_DEFAULT, reg_methods=True):
        cdef char *cs

        if port != None:
            p = _encode(str(port));
            cs = p
        else:
            cs = NULL

        # make sure python can handle threading
        PyEval_InitThreads()

        global __exception
        __exception = None
        self._server_thread = lo_server_thread_new_with_proto(cs, proto, _err_handler)
        if __exception:
            raise __exception
        self._server = lo_server_thread_get_server(self._server_thread)

        _ServerBase.__init__(self, reg_methods=reg_methods)

    def __dealloc__(self):
        self.free()

    def free(self):
        """
        Free the underlying server object and close its port.

        !!! note

            This method is called automatically when the server is deallocated.
        """
        if self._server_thread:
            lo_server_thread_free(self._server_thread)
            self._server_thread = NULL
            self._server = NULL

    def start(self):
        """
        Start the server thread.

        liblo will now start to dispatch any messages it receives.
        """
        self._check()
        lo_server_thread_start(self._server_thread)

    def stop(self):
        """
        Stop the server thread.
        """
        self._check()
        lo_server_thread_stop(self._server_thread)


################################################################################
#  Address
################################################################################

class AddressError(Exception):
    """
    Raised when trying to create an invalid `Address` object.
    """
    def __init__(self, msg):
        self.msg = msg
    def __str__(self):
        return "address error: %s" % self.msg


cdef class Address:
    """
    An Address represents a destination for a message

    Possible forms:

    * `Address(hostname: str, port: int, proto: [int | str] = LO_UDP`)
    * `Address(port: int)`   # Assumes localhost
    * `Address(url: str)`    # A URL of the form 'osc.udp://hostname:1234/'

    Create a new `Address` object from the given hostname/port
    or URL.

    Args:
        hostname: the target's hostname - the name or an IP of the form '127.0.0.0'.
        port: the port number of the target
        proto: one of the constants `LO_UDP`, `LO_TCP`, `LO_UNIX` or a string like 'UDP', 'TCP' or 'UNIX'
        url: a URL in liblo notation, e.g. `'osc.udp://hostname:1234/'`.

    Raises:
        AddressError: if the given parameters do not represent a valid address.

    """

    cdef lo_address _address

    def __init__(self, addr, addr2=None, proto=LO_UDP):
        if isinstance(proto, str):
            proto = _protostr_to_int(proto)

        if addr2:
            # Address(host, port[, proto])
            s = _encode(addr)
            s2 = _encode(str(addr2))
            self._address = lo_address_new_with_proto(proto, s, s2)
            if not self._address:
                raise AddressError("invalid protocol")
        elif isinstance(addr, int) or (isinstance(addr, str) and addr.isdigit()):
            # Address(port)
            s = str(addr).encode()
            self._address = lo_address_new(NULL, s)
        else:
            # Address(url)
            s = _encode(addr)
            self._address = lo_address_new_from_url(s)
            # lo_address_errno() is of no use if self._addr == NULL
            if not self._address:
                raise AddressError("invalid URL '%s'" % str(addr))

    def __dealloc__(self):
        lo_address_free(self._address)

    def get_url(self):
        """This Address as a liblo URL"""
        cdef char *tmp = lo_address_get_url(self._address)
        cdef object r = tmp
        free(tmp)
        return _decode(r)

    def get_hostname(self):
        """The hostname of this Address"""
        return _decode(lo_address_get_hostname(self._address))

    def get_port(self):
        """The port number of this Address"""
        cdef bytes s = lo_address_get_port(self._address)
        if s.isdigit():
            return int(s)
        else:
            return _decode(s)

    def get_protocol(self):
        """
        The protocol used as an int

        Example
        -------

        ```python
        from pyliblo3 import *
        address = Address('127.0.0.0', 9876)
        assert address.get_protocol() == LO_UDP
        ```

        """
        return lo_address_get_protocol(self._address)

    property url:
        """
        The address's URL.
        """
        def __get__(self):
            return self.get_url()

    property hostname:
        """
        The address's hostname.
        """
        def __get__(self):
            return self.get_hostname()

    property port:
        """
        The address's port number.
        """
        def __get__(self):
            return self.get_port()

    property protocol:
        """
        The address's protocol (one of the constants :const:`UDP`,
        :const:`TCP`, or :const:`UNIX`).
        """
        def __get__(self):
            return self.get_protocol()


################################################################################
#  Message
################################################################################

cdef class _Blob:
    cdef lo_blob _blob

    def __init__(self, arr):
        # arr can by any sequence type
        cdef unsigned char *p
        cdef uint32_t size, i
        size = len(arr)
        if size < 1:
            raise ValueError("blob is empty")
        # copy each element of arr to a C array
        p = <unsigned char*>malloc(size)
        try:
            if isinstance(arr[0], (str, unicode)):
                # use ord() if arr is a string (but not bytes)
                for i from 0 <= i < size:
                    p[i] = ord(arr[i])
            else:
                for i from 0 <= i < size:
                    p[i] = arr[i]
            # build blob
            self._blob = lo_blob_new(size, p)
        finally:
            free(p)

    def __dealloc__(self):
        lo_blob_free(self._blob)


cdef class Message:
    """
    An OSC message, consisting of a path and arbitrary arguments.

    Args:
        path (str): the path of the message
        args: any arguments passed will be added to this messag
    """
    cdef bytes _path
    cdef lo_message _message
    cdef list _keep_refs

    def __init__(self, path, *args):
        self._keep_refs = []
        # encode path to bytestring if necessary
        self._path = _encode(path)
        self._message = lo_message_new()

        self.add(*args)

    def __dealloc__(self):
        lo_message_free(self._message)

    def add(self, *args):
        """
        Append the given arguments to this message

        Arguments can be single values or `(typetag, data)` tuples to specify
        the actual type. This might be needed for numbers, to specify if a float
        needs to be encoded as a 32-bit (typetag = 'f') or 64-bit float (typetag = 'd').
        By default, float numbers are interpreted as 32-bit floats.

        Args:
            args: each argument can be a single value or a tuple `(typetag: str, data: Any)`
        """
        for arg in args:
            if (isinstance(arg, tuple) and len(arg) <= 2 and
                    isinstance(arg[0], (bytes, unicode)) and len(arg[0]) == 1):
                # type explicitly specified
                if len(arg) == 2:
                    self._add(arg[0], arg[1])
                else:
                    self._add(arg[0], None)
            else:
                # detect type automatically
                self._add_auto(arg)

    cdef _add(self, type, value):
        cdef uint8_t midi[4]

        # accept both bytes and unicode as type specifier
        cdef char t = ord(_decode(type)[0])

        if t == 'i':
            lo_message_add_int32(self._message, int(value))
        elif t == 'h':
            lo_message_add_int64(self._message, int(value))
        elif t == 'f':
            lo_message_add_float(self._message, float(value))
        elif t == 'd':
            lo_message_add_double(self._message, float(value))
        elif t == 'c':
            lo_message_add_char(self._message, ord(value))
        elif t == 's':
            s = _encode(value)
            lo_message_add_string(self._message, s)
        elif t == 'S':
            s = _encode(value)
            lo_message_add_symbol(self._message, s)
        elif t == 'T':
            lo_message_add_true(self._message)
        elif t == 'F':
            lo_message_add_false(self._message)
        elif t == 'N':
            lo_message_add_nil(self._message)
        elif t == 'I':
            lo_message_add_infinitum(self._message)
        elif t == 'm':
            for n from 0 <= n < 4:
                midi[n] = value[n]
            lo_message_add_midi(self._message, midi)
        elif t == 't':
            lo_message_add_timetag(self._message, _double_to_timetag(value))
        elif t == 'b':
            b = _Blob(value)
            # make sure the blob is not deleted as long as this message exists
            self._keep_refs.append(b)
            lo_message_add_blob(self._message, (<_Blob>b)._blob)
        else:
            raise TypeError("unknown OSC data type '%c'" % t)

    cdef _add_auto(self, value):
        # bool is a subclass of int, so check those first
        if value is True:
            lo_message_add_true(self._message)
        elif value is False:
            lo_message_add_false(self._message)
        elif isinstance(value, (int)):
            try:
                lo_message_add_int32(self._message, <int32_t>value)
            except OverflowError:
                lo_message_add_int64(self._message, <int64_t>value)
        elif isinstance(value, float):
            lo_message_add_float(self._message, float(value))
        elif isinstance(value, (bytes, unicode)):
            s = _encode(value)
            lo_message_add_string(self._message, s)
        elif value == None:
            lo_message_add_nil(self._message)
        elif value == float('inf'):
            lo_message_add_infinitum(self._message)
        else:
            # last chance: could be a blob
            try:
                iter(value)
            except TypeError:
                raise TypeError("unsupported message argument type")
            self._add('b', value)


################################################################################
#  Bundle
################################################################################

cdef class Bundle:
    """
    A bundle of one or more messages to be sent and dispatched together.

    Possible forms:

    * `Bundle(*messages)`
    * `Bundle(timetag: float, *messages)`

    Create a new `Bundle` object. You can optionally specify a
    time at which the messages should be dispatched (as an OSC timetag
    float), and any number of messages to be included in the bundle.

    Args:
        timetag (float): optional, speficies the time at which the message
            should be dispatched
        messages: any number of `Message`s to include in this `Bundle`
    """
    cdef lo_bundle _bundle
    cdef list _keep_refs

    def __init__(self, *messages):
        cdef lo_timetag tt
        tt.sec, tt.frac = 0, 0
        self._keep_refs = []

        if len(messages) and not isinstance(messages[0], Message):
            t = messages[0]
            if isinstance(t, (float, int)):
                tt = _double_to_timetag(t)
            elif isinstance(t, tuple) and len(t) == 2:
                tt.sec, tt.frac = t
            else:
                raise TypeError("invalid timetag")
            # first argument was timetag, so continue with second
            messages = messages[1:]

        self._bundle = lo_bundle_new(tt)
        if len(messages):
            self.add(*messages)

    def __dealloc__(self):
        lo_bundle_free(self._bundle)

    def add(self, *args):
        """
        Add one or more messages to this bundle

        Possible forms:

        * `add(*messages: Message)`
        * `add(path: str, *args)`, where path is the osc path (for example, '/path1' or '/root/subpath')
            and `args` are passed directly to `Message` to create a Message to be added to this Bundle

        Add one or more messages to the bundle.

        Args:
            args: either a Message or a set or arguments passed directly to `Message` to create
                a `Message` which is added to this `Bundle`
        """
        if isinstance(args[0], Message):
            # args is already a list of Messages
            messages = args
        else:
            # make a single Message from all arguments
            messages = [Message(*args)]

        # add all messages
        for m in messages:
            self._keep_refs.append(m)
            message = <Message> m
            lo_bundle_add_message(self._bundle, message._path, message._message)
