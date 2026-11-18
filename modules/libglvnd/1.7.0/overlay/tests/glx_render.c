/* GLX render test: opens the X display in $DISPLAY, creates a pbuffer
 * context through GLX, clears it and reads it back. Built two ways (see
 * BUILD.bazel):
 *   default         -> :GLX + :OpenGL (the libglvnd-recommended split)
 *   USE_LEGACY_GL   -> :GL alone (libGL.so.1, the legacy ABI)
 */
#include <GL/gl.h>
#include <GL/glx.h>

#include "render_common.h"

int main(void) {
    check_real_library("glXChooseFBConfig");
    check_real_library("glClear");

    Display* dpy = XOpenDisplay(NULL);
    CHECK(dpy != NULL, "cannot open X display '%s' (is DISPLAY set and passed to the test?)",
          getenv("DISPLAY") ? getenv("DISPLAY") : "");
    int major = 0, minor = 0;
    CHECK(glXQueryVersion(dpy, &major, &minor), "glXQueryVersion failed");
    printf("GLX %d.%d, client vendor = %s\n", major, minor, glXGetClientString(dpy, GLX_VENDOR));

    const int fb_attrs[] = {
        GLX_DRAWABLE_TYPE, GLX_PBUFFER_BIT, GLX_RENDER_TYPE, GLX_RGBA_BIT,
        GLX_RED_SIZE,      8,               GLX_GREEN_SIZE,  8,
        GLX_BLUE_SIZE,     8,               GLX_ALPHA_SIZE,  8,
        None,
    };
    int n = 0;
    GLXFBConfig* configs = glXChooseFBConfig(dpy, DefaultScreen(dpy), fb_attrs, &n);
    CHECK(configs && n > 0, "no matching GLXFBConfig");

    const int pbuffer_attrs[] = {GLX_PBUFFER_WIDTH, 16, GLX_PBUFFER_HEIGHT, 16, None};
    GLXPbuffer pbuffer = glXCreatePbuffer(dpy, configs[0], pbuffer_attrs);
    GLXContext ctx = glXCreateNewContext(dpy, configs[0], GLX_RGBA_TYPE, NULL, True);
    CHECK(ctx != NULL, "glXCreateNewContext failed");
    CHECK(glXMakeContextCurrent(dpy, pbuffer, pbuffer, ctx), "glXMakeContextCurrent failed");

    clear_and_verify();

    glXMakeContextCurrent(dpy, None, None, NULL);
    glXDestroyContext(dpy, ctx);
    glXDestroyPbuffer(dpy, pbuffer);
    XFree(configs);
    XCloseDisplay(dpy);
    printf("PASS\n");
    return 0;
}
