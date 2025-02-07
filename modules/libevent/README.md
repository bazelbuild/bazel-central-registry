# Libevent

## BCR Maintainer Notes

The [Libevent book](https://libevent.org/libevent-book/) is a handy reference.

### Known Issues

* The latest OpenSSL in BCR (3.3.1.bcr.1 at the time of this writing) does not
  support Windows, so the `@libevent//:event_openssl` target is not usable on
  Windows.
* OpenSSL 3.3.1.bcr.1 also seems to be missing some symbols on macOS. Attempting
  to build `@libevent//sample:https-client` fails because of this.

### Libraries

For better or worse, I kept the same library targets as the official
release. These targets are described in the [preliminaries
chapter](https://libevent.org/libevent-book/Ref0_meta.html) in the book.

* `@libevent//:event_core` - All core event and buffer functionality. This
  library contains all the event_base, evbuffer, bufferevent, and utility
  functions.
* `@libevent//:event_extra` - This library defines protocol-specific
  functionality that you may or may not want for your application, including
  HTTP, DNS, and RPC.
* `@libevent//:event` - This library exists for historical reasons; it contains
  the contents of both libevent_core and libevent_extra. You shouldn’t use it;
  it may go away in a future version of Libevent.
* `@libevent//:event_pthreads` - This library adds threading and locking
  implementations based on the pthreads portable threading library. It is
  separated from libevent_core so that you don’t need to link against pthreads
  to use Libevent unless you are actually using Libevent in a multithreaded way.
* `@libevent//:event_openssl` - This library provides support for encrypted
  communications using bufferevents and the OpenSSL library. It is separated
  from libevent_core so that you don’t need to link against OpenSSL to use
  Libevent unless you are actually using encrypted connections.

### Notes on creating the BCR build

Upstream releases can be found at https://github.com/libevent/libevent/releases

#### Configuration Headers

The official build uses CMake to generate two files, `evconfig-private.h` and
`event2/event-config.h`. The general strategy is to generate them ourselves and
then modify them for portability. Ordinarily CMake detects the capabilities of
the host platform and writes these files accordingly, but this workflow doesn't
happen on Bazel, so we will have to edit these files and provide our own feature
detection.

Run `cmake` to generate `evconfig-private.h` and `event2/event-config.h` in
`build/include`.

```shell
mkdir build && cd build
cmake ..
```

From here I decided to make the config files platform specific for better
organization. So for example, I renamed `evconfig-private.h` to
`evconfig-private_linux.h` and then made `evconfig-private.h` into a platform
selector file. I did the same with `event2/event-config.h`. When you rename
these files, be sure to fix the strings used by the `#include` guards as
well. These files get overlayed onto the tree in the Bazel Central Registry.

One thing to note is the `SIZEOF` constants in the config files, for example
`EVENT__SIZEOF_LONG`. Since `sizeof(type)` cannot be used by the preprocessor,
normally CMake computes the values on the host platform. We have to manually get
these right. For `gcc` and `clang`, some of these constants are provided by the
compiler. You can see some of the predefined symbols that may be useful with the
following command:

```shell
${CC:-gcc} -dM -E - $@ < /dev/null
```

I added a test `@libevent//test:test-config` to check that the some of the
values in the configuration headers are correct.

#### `BUILD.bazel`

Next you will have to create the `BUILD.bazel` file. Commands like 
```shell
ls -1 include/*.h | sort | awk '{ print "\""$0"\","}'
```
are helpful for getting the list of files in a format that can be copy-pasted.

Two files are handled non-intuitively:

* `arc4random.c` is textually included by evutil_rand.c when arc4random() is not
  available. It is not compiled by itself. Put this file in `textual_hdrs`.
* `epoll_sub.c` appears to only be needed when using an ancient version of
  glibc, and will conflict with glibc when a modern version is in use. For
  simplicity this file can be omitted from the build.
