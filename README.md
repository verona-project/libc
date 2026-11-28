# Verona libc

A C and POSIX libc binding for Verona programs on ARM64 and x86-64 Darwin
and glibc-based Linux.
Import the module for the API you need. Names such as `clock_gettime` use
hyphens in Verona (`libc.time:clock-gettime`).

`libc.types` exports transparent aliases for the ABI types used here: `c-char`,
`c-int`, `c-long`, `size-t`, `ssize-t`, `off-t`, `pid-t`, `mode-t`, `time-t`,
`socket-length-t`, `poll-count-t`, `file-descriptor`, and `c-string`.
It models `pollfd` (`poll-descriptor`), `timespec` (`time-specification`),
`tm` (`broken-down-time`), `stat` (`file-status`), and `dirent`
(`directory-entry`). Network types include `address-info` (`addrinfo`),
`socket-address` (`sockaddr`), `socket-address-storage`
(`sockaddr_storage`), and the IPv4, IPv6, and Unix-domain address layouts.
Use `socket-address-storage` for address-output buffers of unknown family.
Pass a pointer cast to `(pointer types:socket-address)` and initialize the
length argument to the buffer's capacity in bytes. File and directory streams
are opaque handles.

`readdir` returns a borrowed `(pointer types:directory-entry)`. Read the
fields and NUL-terminated name in place before the next `readdir` on that
stream or `closedir`. `getaddrinfo` returns a linked list whose storage
belongs to libc. Read its `address-info` fields before releasing the list
with `freeaddrinfo`.

Pthread mutexes, condition variables, and their attribute types provide sized
and aligned storage. Initialize and destroy them with the corresponding
`libc.pthread` functions. Pass `nil` for default attributes.

`libc.types` and `libc.constants` use platform feature conditionals (`#+darwin` and `#+linux`) to select the
ABI-dependent aliases and values from the target triple. This includes
`mode-t`, `pthread-thread`, open flags, `AF-INET6`, and the platform-specific
`EAGAIN`/`EDEADLK` values. It provides standard file-descriptor and exit
values; seek, open, and permission flags; `WNOHANG`; the basic socket
families, socket kinds, and IP protocol values; and common POSIX errno values.
These are target definitions, not a portable replacement for every C header.

The declarations are divided by C API category. `src/libc.vrn` is the build
aggregator; clients import the category they use. The modules are
`libc.types`, `libc.constants`, `libc.errno`, `libc.memory`, `libc.string`, `libc.stdio`,
`libc.descriptor`, `libc.filesystem`, `libc.process`, `libc.time`,
`libc.math`, `libc.network`, `libc.pthread`, `libc.dynamic`, and
`libc.random`. These modules expose the C ABI directly.

`libc.errno:errno-pointer` returns borrowed storage for the calling thread's
`errno`: Darwin uses `__error`, Linux uses `__errno_location`. Do not free the
pointer or share it between threads. Read the value immediately after a failed
C call; successful calls need not clear it. Error values such as `EINTR` and
`ECHILD` are exported by `libc.constants`.

`libc.filesystem:mkstemp` requires a writable NUL-terminated template ending in
`XXXXXX`. It replaces those characters with a unique name and returns an open
file descriptor; the caller closes it and removes the file with `unlink` when
finished. `libc.stdio:ferror` reads a stream's error indicator (distinct from
end-of-file). `libc.process:waitpid` takes a PID, an out-pointer to a C integer
status, and options (including `WNOHANG`); it returns the selected child PID,
zero for a pending nonblocking wait, or -1 on error. Its status is the raw POSIX
wait status, not a process exit code.

`libc.process:exit-immediately` binds C's `_exit`. It terminates the process
without flushing stdio streams or running `atexit` handlers.

The binding uses fixed-arity declarations. Variadic APIs such as `printf`,
`snprintf`, `scanf`, `fcntl`, `openat`, and `execl*` require variadic
FFI support or a C shim. The existing fixed-arity `open` declaration cannot
pass a creation mode correctly on Apple ARM64. Use `creat` for its
create-or-truncate behavior, `mkstemp` for temporary files, and
`execv`/`execve`/`execvp` for process execution.

`qsort` and `bsearch` accept a `types:comparison-function` callback
with signature `((pointer void) (pointer void)) -> c-int`.
`pthread-create` accepts a `types:pthread-start-routine` callback
with signature `((pointer void)) -> (pointer void)`. Pass a function of
the matching type directly.

`libc.network:accept4` is available on Linux. `libc.random:arc4random-uniform`
requires glibc 2.36 or later on glibc-based systems. Linux applications that
use the math functions may need to link `libm`. With glibc before 2.34,
dynamic loading and pthread calls may also need `libdl` and `libpthread`.

## Exported functions

| Module | Functions |
| --- | --- |
| `libc.errno` | `errno-pointer` |
| `libc.memory` | `malloc`, `calloc`, `realloc`, `free`, `memcpy`, `memmove`, `memset`, `memcmp`, `memchr`, `posix-memalign` |
| `libc.string` | `strlen`, `strcmp`, `strncmp`, `strcpy`, `strncpy`, `strchr`, `strstr`, `strerror`, `strnlen`, `strdup`, `strndup`, `strrchr`, `strcat`, `strtok-r` |
| `libc.stdio` | `fopen`, `tmpfile`, `fileno`, `ferror`, `fclose`, `fread`, `fwrite`, `fgets`, `fputs`, `getchar`, `putchar`, `puts`, `perror`, `fdopen`, `fflush`, `feof`, `clearerr`, `fgetc`, `fputc`, `getline`, `fseeko`, `ftello` |
| `libc.descriptor` | `open`, `close`, `read`, `write`, `lseek`, `pipe`, `dup`, `dup2`, `pread`, `pwrite`, `fsync`, `ftruncate`, `isatty`, `poll` |
| `libc.filesystem` | `stat`, `fstat`, `lstat`, `mkdir`, `mkstemp`, `unlink`, `rename`, `opendir`, `readdir`, `closedir`, `chdir`, `creat`, `access`, `getcwd`, `realpath`, `chmod`, `rmdir`, `readlink`, `symlink` |
| `libc.process` | `getenv`, `setenv`, `unsetenv`, `getpid`, `fork`, `execv`, `execve`, `execvp`, `wait`, `waitpid`, `exit`, `exit-immediately`, `getppid`, `abort` |
| `libc.time` | `time`, `clock-gettime`, `sleep`, `nanosleep`, `clock-getres`, `gmtime-r`, `localtime-r`, `mktime`, `strftime` |
| `libc.math` | `abs`, `strtol`, `strtoul`, `qsort`, `bsearch`, `sin`, `cos`, `sqrt`, `strtof`, `strtod`, `gcvt`, `pow`, `exp`, `log`, `floor`, `ceil`, `fabs` |
| `libc.network` | `socket`, `htons`, `inet-addr`, `setsockopt`, `bind`, `listen`, `accept`, `connect`, `send`, `recv`, `getaddrinfo`, `freeaddrinfo`, `inet-pton`, `inet-ntop`, `shutdown`, `getsockopt`, `getsockname`, `getpeername`, `socketpair`, `sendto`, `recvfrom`, `getnameinfo`, `gai-strerror`, `accept4` (Linux) |
| `libc.pthread` | `pthread-create`, `pthread-join`, `pthread-mutex-init`, `pthread-mutex-destroy`, `pthread-mutex-lock`, `pthread-mutex-unlock`, `pthread-cond-init`, `pthread-cond-destroy`, `pthread-cond-wait`, `pthread-cond-signal`, `pthread-cond-broadcast`, `pthread-self`, `pthread-equal`, `pthread-detach`, `pthread-mutex-trylock`, `pthread-cond-timedwait`, `pthread-attr-init`, `pthread-attr-destroy`, `pthread-mutexattr-init`, `pthread-mutexattr-destroy`, `pthread-condattr-init`, `pthread-condattr-destroy` |
| `libc.dynamic` | `dlopen`, `dlsym`, `dlerror`, `dlclose` |
| `libc.random` | `arc4random-uniform` |

Use the source modules from another project's build file:

```lisp
(module-path "../libc/src")
```

Then import the module in Verona source:

```lisp
(import libc.types :as libc)
(import libc.descriptor :as descriptor)
```

The build target roots at `libc`, which imports every category so the full
package is compiled together. Run `make` to build the library into `dist/`:

```sh
make
```

## Tests

Place Verona Testing beside this checkout as `testing/`, alongside `base/`.
From this directory, build and run the suite:

```sh
make test
```

The suite exercises every module, including platform-specific ABI layouts,
typed callbacks, thread synchronization, and local sockets. It uses temporary
files and loopback networking. On Linux, the random-number test requires
glibc 2.36 or later. Failing test cases are printed by name.

## Dependencies and development

Run `make check` to build the library, run the test suite, and check
formatting. Use `make format` to format Verona sources in place and
`make clean` to remove the generated archive, header, and test executable.
Override the tools or output path with `VERONA`, `VERONA_FORMATTER`, and
`BUILD_DIR`.

The package version is declared in `verona.build`. libc depends on Verona Base;
place its source checkout beside this repository as `base/`, providing
`../base/src` to the build. Consumers also need Base on their module search path.

This repository is pinned at `projects/libc` in
[Verona](https://github.com/verona-project/verona). Compiler ABI checks and the
project-tool and formatter integration suites run from the main repository:

```sh
make test-compiler
make build
sbcl --script projects/project/tests/run-integration.lisp
make test-formatter
```

Use Verona's pinned Nix development environment for these checks. Public clones
use HTTPS. To push libc changes over SSH:

```sh
git remote set-url --push origin git@github.com:verona-project/libc.git
```

Commit changes here before updating Verona's submodule reference.
Released under the Unlicense; see `LICENSE`.
