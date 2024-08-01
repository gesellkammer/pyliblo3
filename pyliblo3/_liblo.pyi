
class Callback:
    def __init__(self, func: Callable, user_data: Any): ...


def time() -> float: ...


def send(target: Address | tuple[str, str] | int, str, *args) -> None: ...


class ServerError(Exception):
    def __init__(self, num: int, msg: str, where: str): ...




# decorator to register callbacks

class make_method:
    def __init__(self, path: str, types: str, user_data: Any = None): ...

    def __call__(self, f: Callable) -> Callable: ...

# common base class for both Server and ServerThread

class _ServerBase:

    def __init__(self, reg_methods: bool = True): ...

    def register_methods(self, obj: _ServerBase = None) -> None: ...

    def get_url(self) -> str: ...

    def get_port(self) -> int: ...

    def get_protocol(self) -> int: ...

    def fileno(self) -> int: ...

    def add_method(self, path: str, typespec: str, func: Callable, user_data: Any = None) -> None: ...

    def del_method(self, path: str, typespec: str | None = None) -> None: ...

    def add_bundle_handlers(self, start_handler: Callable, end_handler: Callable, user_data=None) -> None: ...

    def send(self, target: Address | tuple[str, int] | str, *args) -> None: ...

    @property
    def url(self) -> str: ...

    @property
    def port(self) -> int: ...

    @property
    def protocol(self) -> int: ...


class Server(_ServerBase):
    def __init__(self, port: int = None, proto: int | str = LO_DEFAULT, reg_methods: bool = True): ...
    def __dealloc__(self): ...
    def free(self) -> None: ...
    def recv(self, timeout: int | float | None = None) -> bool: ...

class ServerThread(_ServerBase):
    def __init__(self, port: int = None, proto: int | str = LO_DEFAULT, reg_methods: bool = True): ...
    def __dealloc__(self): ...
    def free(self) -> None: ...
    def start(self) -> None: ...
    def stop(self) -> None: ...

class AddressError(Exception):
    def __init__(self, msg: str): ...

class Address:
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

    def __init__(self, addr: str | int, addr2: int = None, proto: int | str = None): ...
    def __dealloc__(self) -> None: ...
    def get_url(self) -> str: ...

    def get_hostname(self) -> str: ...
    def get_port(self) -> int | str: ...

    def get_protocol(self) -> int: ...

    @property
    def url(self) -> str: ...

    @property
    def hostname(self) -> str: ...

    @property
    def port(self) -> int: ...

    @property
    def protocol(self) -> int: ...


class Message:
    def __init__(self, path: str, *args): ...
    def add(self, *args: tuple[str, Any] | int | float | str | bool) -> None: ...


class Bundle:
    def __init__(self, *messages): ...
    def add(self, *args) -> None: ...
