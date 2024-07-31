# liblo


---------


| Class  | Description  |
| :----  | :----------- |
|  [Address](#address) | Address(addr, addr2=None, proto=LO_UDP) |
|  [AddressError](#addresserror) | Raised when trying to create an invalid `Address` object. |
|  [Bundle](#bundle) | Bundle(*messages) |
|  [Callback](#callback) | Callback(func, user_data) |
|  [Message](#message) | Message(path, *args) |
|  [Server](#server) | Server(port=None, proto=LO_DEFAULT, reg_methods=True) |
|  [ServerError](#servererror) | Raised when creating a liblo OSC server fails. |
|  [ServerThread](#serverthread) | ServerThread(port=None, proto=LO_DEFAULT, reg_methods=True) |
|  [make_method](#make_method) | A decorator that serves as a more convenient alternative to [Server.add_method](#add_method). |
|  [struct](#struct) |  |

| Function  | Description  |
| :-------  | :----------- |
| `send` | Send a message without requiring a server |
| `time` | Return the current time as a floating point number (seconds since January 1, 1900). |



---------


## Address
### 


```python

Address(addr, addr2=None, proto=LO_UDP)

```


An Address represents a destination for a message


Possible forms:

* `Address(hostname: str, port: int, proto: [int | str] = LO_UDP`)
* `Address(port: int)`   # Assumes localhost
* `Address(url: str)`    # A URL of the form 'osc.udp://hostname:1234/'

Create a new `Address` object from the given hostname/port
or URL.

Raises:
    AddressError: if the given parameters do not represent a valid address.



**Args**

* **hostname**: the target's hostname - the name or an IP of the form
    '127.0.0.0'.
* **port**: the port number of the target
* **proto**: one of the constants `LO_UDP`, `LO_TCP`, `LO_UNIX` or a string like
    'UDP', 'TCP' or 'UNIX'
* **url**: a URL in liblo notation, e.g. `'osc.udp://hostname:1234/'`.


---------


**Summary**



| Property  | Description  |
| :-------- | :----------- |
| hostname | The address's hostname. |
| port | The address's port number. |
| protocol | The address's protocol (one of the constants :const:`UDP`,
        :const:`TCP`, or :const:`UNIX`). |
| url | The address's URL. |


| Method  | Description  |
| :------ | :----------- |
| [get_hostname](#get_hostname) | The hostname of this Address |
| [get_port](#get_port) | The port number of this Address |
| [get_protocol](#get_protocol) | The protocol used as an int |
| [get_url](#get_url) | This Address as a liblo URL |


---------


**Attributes**

* **hostname**: The address's hostname.
* **port**: The address's port number.
* **protocol**: The address's protocol (one of the constants :const:`UDP`,
  :const:`TCP`, or :const:`UNIX`).
* **url**: The address's URL.


---------


**Methods**

### get\_hostname


```python

Address.get_hostname(self)

```


The hostname of this Address

----------

### get\_port


```python

Address.get_port(self)

```


The port number of this Address

----------

### get\_protocol


```python

Address.get_protocol(self)

```


The protocol used as an int


#### Example

```python
from pyliblo3 import *
address = Address('127.0.0.0', 9876)
assert address.get_protocol() == LO_UDP
```

----------

### get\_url


```python

Address.get_url(self)

```


This Address as a liblo URL



---------


## Bundle
### 


```python

Bundle(*messages)

```


A bundle of one or more messages to be sent and dispatched together.


Possible forms:

* `Bundle(*messages)`
* `Bundle(timetag: float, *messages)`

Create a new `Bundle` object. You can optionally specify a
time at which the messages should be dispatched (as an OSC timetag
float), and any number of messages to be included in the bundle.



**Args**

* **timetag** (`float`): optional, speficies the time at which the message
    should be dispatched
* **messages**: any number of `Message`s to include in this `Bundle`


---------


**Summary**



| Method  | Description  |
| :------ | :----------- |
| [add](#add) | Add one or more messages to this bundle |


---------


---------


**Methods**

### add


```python

Bundle.add(self, *args)

```


Add one or more messages to this bundle


Possible forms:

* `add(*messages: Message)`
* `add(path: str, *args)`, where path is the osc path (for example, '/path1' or '/root/subpath')
    and `args` are passed directly to `Message` to create a Message to be added to this Bundle

Add one or more messages to the bundle.



**Args**

* **args**:



---------


## Callback
### 


```python

Callback(func, user_data)

```


Used internally to wrap a python function as a callback



**Args**

* **func**: the function to call
* **user_data**: any python object, will be passed to the callback as the last
    argument



---------


## Message
### 


```python

Message(path, *args)

```


An OSC message, consisting of a path and arbitrary arguments.



**Args**

* **path** (`str`): the path of the message
* **args**: any arguments passed will be added to this messag


---------


**Summary**



| Method  | Description  |
| :------ | :----------- |
| [add](#add) | Append the given arguments to this message |


---------


---------


**Methods**

### add


```python

Message.add(self, *args)

```


Append the given arguments to this message


Arguments can be single values or `(typetag, data)` tuples to specify
the actual type. This might be needed for numbers, to specify if a float
needs to be encoded as a 32-bit (typetag = 'f') or 64-bit float (typetag = 'd').
By default, float numbers are interpreted as 32-bit floats.



**Args**

* **args**: each argument can be a single value or a tuple `(typetag: str, data:
    Any)`



---------


## make\_method
### 


```python

def (path: str | None, types: str, user_data) -> None

```


A decorator that serves as a more convenient alternative to [Server.add_method](#add_method).



**Args**

* **path** (`str | None`): the message path to be handled by the registered
    method.         `None` may be used as a wildcard to match any OSC message.
* **types** (`str`): the argument types to be handled by the registered method.
    `None` may be used as a wildcard to match any OSC message.
* **user_data**: An arbitrary object that will be passed on to the decorated
    method every time a matching message is received.


---------


**Summary**



| Method  | Description  |
| :------ | :----------- |
| [__init__](#__init__) | make_method.__init__(self, path, types, user_data=None) |


---------


---------


**Methods**

### \_\_init\_\_


```python

def __init__(self, path, types, user_data=None) -> None

```


make_method.__init__(self, path, types, user_data=None)



**Args**

* **path**:
* **types**:
* **user_data**:  (*default*: `None`)



---------


## struct

---------


**Summary**



| Method  | Description  |
| :------ | :----------- |
| [__init__](#__init__) | struct.__init__(self, **kwargs) |


---------


---------


**Methods**

### \_\_init\_\_


```python

def __init__(self, kwargs) -> None

```


struct.__init__(self, **kwargs)



**Args**

* **kwargs**:



---------


## \_ServerBase
### 


```python

_ServerBase(reg_methods=True)

```


---------


**Summary**



| Property  | Description  |
| :-------- | :----------- |
| port | The server's port number (int) |
| protocol | The server's protocol (one of the constants `LO_UDP`, `LO_TCP` or `LO_UNIX`). |
| url | The server's URL. |


| Method  | Description  |
| :------ | :----------- |
| [add_bundle_handlers](#add_bundle_handlers) | Add bundle notification handlers. |
| [add_method](#add_method) | Register a callback for OSC messages with matching path and argument types. |
| [del_method](#del_method) | Delete a callback function |
| [fileno](#fileno) | Return the file descriptor of the server socket |
| [get_port](#get_port) | Returns the port number of this server |
| [get_protocol](#get_protocol) | Returns the protocol of this server, as an int |
| [get_url](#get_url) | Returns the url of the server |
| [register_methods](#register_methods) | Called internally during init if reg_methods is True |
| [send](#send) | Send a message or bundle from this server to the the given target. |


---------


**Attributes**

* **port**: The server's port number (int)
* **protocol**: The server's protocol (one of the constants `LO_UDP`, `LO_TCP`
  or `LO_UNIX`).
* **url**: The server's URL.


---------


**Methods**

### add\_bundle\_handlers


```python

_ServerBase.add_bundle_handlers(self, start_handler, end_handler, user_data=None)

```


Add bundle notification handlers.



**Args**

* **start_handler**: a callback which fires when at the start of a bundle. This
    is         called with the bundle's timestamp and user_data.
* **end_handler**: a callback which fires when at the end of a bundle. This is
    called         with user_data.
* **user_data**: data to pass to the handlers. (*default*: `None`)

----------

### add\_method


```python

_ServerBase.add_method(self, str path, str typespec, func, user_data=None)

```


Register a callback for OSC messages with matching path and argument types.



**Args**

* **path** (`str`): the message path to be handled by the registered method.
    `None` may be used as a wildcard to match any OSC message.
* **typespec** (`str`): the argument types to be handled by the registered
    method.         `None` may be used as a wildcard to match any OSC message.
* **func**: the callback function.  This may be a global function, a class
    method, or any other callable object, pyliblo will know what         to do
    either way.
* **user_data**: An arbitrary object that will be passed on to *func* every time
    a matching message is received. (*default*: `None`)

----------

### del\_method


```python

_ServerBase.del_method(self, path, typespec=None)

```


Delete a callback function


Delete a callback function.  For both *path* and *typespec*, `None`
may be used as a wildcard.



**Args**

* **path** (`str | None`): the method to delete
* **typespec** (`str | None`): the typespec to match, or None to delete any
    method matching the given path (*default*: `None`)

----------

### fileno


```python

_ServerBase.fileno(self)

```


Return the file descriptor of the server socket



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) the file descriptor, or -1 if not supported by the underlying server protocol

----------

### get\_port


```python

_ServerBase.get_port(self)

```


Returns the port number of this server



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) port number

----------

### get\_protocol


```python

_ServerBase.get_protocol(self)

```


Returns the protocol of this server, as an int


This will be one of `LO_TCP`, `LO_TCP` or `LO_UNIX`



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`int`) the protocol as an int

----------

### get\_url


```python

_ServerBase.get_url(self)

```


Returns the url of the server



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`str`) url of the server

----------

### register\_methods


```python

_ServerBase.register_methods(self, obj=None)

```


Called internally during init if reg_methods is True


This function is usually called automatically by the server's
constructor, unless its *reg_methods* parameter was set to `False`.



**Args**

* **obj**: The object that implements the OSC callbacks to be registered.
    By default this is the server object itself. (*default*: `None`)

----------

### send


```python

_ServerBase.send(self, target, *args)

```


Send a message or bundle from this server to the the given target.


* `send(target, *messages)`
* `send(target, path, *args)`

Send a message or bundle from this server to the the given target.
Arguments may be one or more `Message` or `Bundle`
objects, or a single message given by its path and optional arguments.

Raises:
    AddressError: if the given target is invalid.
    IOError: if the message couldn't be sent.



**Args**

* **target** (`Address | tuple[str, int] | str`): the address to send the
    message to;         an `Address` object, a port number, a `(hostname, port)`
    tuple, or a URL.
* **args**:



---------


## Server
 - Base Class: [_ServerBase](#_serverbase)

### 


```python

Server(port=None, proto=LO_DEFAULT, reg_methods=True)

```


A server that can receive OSC messages, blocking


Use [ServerThread](#ServerThread) for an OSC server that runs in its own thread
and never blocks.

    Raises:
        ServerError: if an error occurs created the underlying liblo server



**Args**

* **port** (`int | None`): a decimal port number or a UNIX socket path.  If
    omitted, an             arbitrary free UDP port will be used.
* **proto** (`int | str`): one of LO_UDP, LO_TCP, LO_UNIX or LO_DEFAULT, or one
    of the             strings 'UDP', 'TCP', 'UNIX'
* **reg_methods** (`bool`): if True, register any methods decorated with the
    [make_method](#make_method)             decorator


---------


**Summary**



| Method  | Description  |
| :------ | :----------- |
| [free](#free) | Free the underlying server object and close its port. |
| [recv](#recv) | Receive and dispatch one OSC message. |


---------


---------


**Methods**

### free


```python

Server.free(self)

```


Free the underlying server object and close its port.


Note that this will also happen automatically when the server is deallocated.

----------

### recv


```python

Server.recv(self, timeout=None)

```


Receive and dispatch one OSC message.


Blocking by default, unless *timeout* is specified.



**Args**

* **timeout** (`int, float`): Time in milliseconds after which the function
    returns if no         messages have been received. May be 0, in which case
    the function always returns         immediately, whether messages have been
    received or not. (*default*: `None`)

**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;`True` if a message was received, otherwise `False`.



---------


## ServerThread
 - Base Class: [_ServerBase](#_serverbase)

### 


```python

ServerThread(port=None, proto=LO_DEFAULT, reg_methods=True)

```


Server running in a thread


Unlike `Server`, `ServerThread` uses its own thread which
runs in the background to dispatch messages. `ServerThread`
has the same methods as `Server`, with the
exception of `.recv`. Instead, it defines two additional
methods `.start` and `.stop`.

Raises:
    ServerError: if creating the server fails, e.g. because the given port could not
        be opened.

!!! note

    Because liblo creates its own thread to receive and dispatch
    messages, callback functions will not be run in the main Python
    thread!



**Args**

* **port** (`int | str`): a decimal port number or a UNIX socket path. If
    omitted, an             arbitrary free UDP port will be used.
* **proto** (`int | str`): one of the constants `LO_UDP`, `LO_TCP` or `LO_UNIX`
    or             a corresponding string 'UDP', 'TCP', 'UNIX'
* **reg_methods**: if True, register any method decorated with the
    [make_method](#make_method)             decorator


---------


**Summary**



| Method  | Description  |
| :------ | :----------- |
| [free](#free) | Free the underlying server object and close its port. |
| [start](#start) | Start the server thread. |
| [stop](#stop) | Stop the server thread. |


---------


---------


**Methods**

### free


```python

ServerThread.free(self)

```


Free the underlying server object and close its port.


!!! note

    This method is called automatically when the server is deallocated.

----------

### start


```python

ServerThread.start(self)

```


Start the server thread.


liblo will now start to dispatch any messages it receives.

----------

### stop


```python

ServerThread.stop(self)

```


Stop the server thread.



---------


## send


```python

send(target, *args)

```


Send a message without requiring a server


The function has two forms:

* `send(target, *messages)`
* `send(target, path, *args)`

Send messages to the the given target, without requiring a server.
Arguments may be one or more `Message` or `Bundle` objects,
or a single message given by its path and optional arguments.

Raises:
    AddressError: if the given target is invalid
    IOError: if the message couldn't be sent.



**Args**

* **target** (`Address | tuple[str, int] | int | str`): the address to send the
    message to;         an `Address` object, a port number, a `(hostname, port)`
    tuple, or a URL.
* **args** (`Any`): the information to send. These are used to construct a
    message


---------


## time


```python

time()

```


Return the current time as a floating point number (seconds since January 1, 1900).



**Returns**

&nbsp;&nbsp;&nbsp;&nbsp;(`float`) The liblo timetag as a float, representing seconds since 1900