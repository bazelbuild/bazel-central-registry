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
the target platform and writes these files accordingly, but this workflow doesn't
happen on Bazel, so we will have to edit these files and provide our own feature
detection.

Run `cmake` to generate `evconfig-private.h` and `event2/event-config.h` in
`build/include`.

```shell
mkdir build && cd build
cmake ..
```

From here I used the generated files as a starting point and decided to make the
config files platform specific for better organization. So for example, I
renamed `evconfig-private.h` to `evconfig-private_linux.h` and then made
`evconfig-private.h` into a platform selector file. I did the same with
`event2/event-config.h`. When you rename these files, be sure to fix the strings
used by the `#include` guards as well. These files get overlayed onto the tree
in the Bazel Central Registry.

I also factored out the version constants like `EVENT__PACKAGE_VERSION` into a
seperate file, `event2-config_common.h`, which *may* allow the platform specific
files to be reused between versions since only the version constants in
`event2-config_common.h` may need to be updated. Use caution with this
strategy. If new feature detection macros are introduced, the platform specific
configuration files will also need to be updated.

Since we cannot guarantee that the user is running a Bazel build targeting an
identical platform as the CMake target, some feature test macros will have to be
updated for portability. For example, `strlcpy` was introduced in glibc
2.38. The generated value of `EVENT__HAVE_STRLCPY` will depend entirely on the
platform (or in this case, the version of glibc on the platform) that CMake ran
on. In this case, I changed the macro to
```c
/* Define to 1 if you have the `strlcpy' function. */
#if EVENT__GLIBC_PREREQ(2, 38)
#define EVENT__HAVE_STRLCPY 1
#endif
```
so that it is correct regardless of the platform CMake ran on.

Figuring out which macros need to be fixed requires some testing. One thing you
could try is running CMake on the oldest platform you would like to support, and
running it on the newest platform you would like to support, and looking at the
diff between the generated files. From there it may require some research to
figure out what the correct feature test is.

Another class of macros that may need to be fixed for portability are the
`SIZEOF` constants in the config files, for example `EVENT__SIZEOF_LONG`, since
this may differ between 32-bit and 64-bit platforms. Note that `sizeof(type)`
cannot be used by the preprocessor. Normally CMake computes the values that will
be used on the target platform. We have to manually get these right. For `gcc`
and `clang`, some of these constants are provided by the compiler. You can see
some of the predefined symbols that may be useful with the following command:

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
