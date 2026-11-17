/* Headless EGL render test: creates a pbuffer context through EGL, clears it
 * and reads it back. Built three ways (see BUILD.bazel):
 *   USE_OPENGL     -> desktop GL via :EGL + :OpenGL
 *   USE_GLES2      -> OpenGL ES 2 via :EGL + :GLESv2
 *   USE_GLES1      -> OpenGL ES 1 via :EGL + :GLESv1_CM
 * EGL extension entry points are fetched with eglGetProcAddress, as libEGL
 * only exports core EGL. */
#include <EGL/egl.h>
#include <EGL/eglext.h>

#if defined(USE_OPENGL)
#include <GL/gl.h>
#define API EGL_OPENGL_API
#define RENDERABLE EGL_OPENGL_BIT
#define CONTEXT_MAJOR 0
#elif defined(USE_GLES2)
#include <GLES2/gl2.h>
#define API EGL_OPENGL_ES_API
#define RENDERABLE EGL_OPENGL_ES2_BIT
#define CONTEXT_MAJOR 2
#elif defined(USE_GLES1)
#include <GLES/gl.h>
#define API EGL_OPENGL_ES_API
#define RENDERABLE EGL_OPENGL_ES_BIT
#define CONTEXT_MAJOR 1
#else
#error "define USE_OPENGL, USE_GLES2 or USE_GLES1"
#endif

#include "render_common.h"

static EGLDisplay get_display(void) {
    /* Prefer a device display so the test does not need a window system. */
    PFNEGLQUERYDEVICESEXTPROC query_devices =
        (PFNEGLQUERYDEVICESEXTPROC)eglGetProcAddress("eglQueryDevicesEXT");
    if (query_devices) {
        EGLDeviceEXT devices[8];
        EGLint n = 0;
        if (query_devices(8, devices, &n) && n > 0) {
            printf("EGL devices = %d, using device 0\n", n);
            EGLDisplay dpy = eglGetPlatformDisplay(EGL_PLATFORM_DEVICE_EXT, devices[0], NULL);
            if (dpy != EGL_NO_DISPLAY) {
                return dpy;
            }
        }
    }
    printf("EGL device platform unavailable, using EGL_DEFAULT_DISPLAY\n");
    return eglGetDisplay(EGL_DEFAULT_DISPLAY);
}

int main(void) {
    check_real_library("eglGetProcAddress");
    check_real_library("glClear");

    EGLDisplay dpy = get_display();
    CHECK(dpy != EGL_NO_DISPLAY, "no EGL display");
    EGLint major = 0, minor = 0;
    CHECK(eglInitialize(dpy, &major, &minor), "eglInitialize failed: 0x%x", eglGetError());
    printf("EGL %d.%d, vendor = %s\n", major, minor, eglQueryString(dpy, EGL_VENDOR));

    CHECK(eglBindAPI(API), "eglBindAPI failed: 0x%x", eglGetError());
    const EGLint config_attrs[] = {
        EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RENDERABLE_TYPE, RENDERABLE,
        EGL_RED_SIZE,     8,               EGL_GREEN_SIZE,      8,
        EGL_BLUE_SIZE,    8,               EGL_ALPHA_SIZE,      8,
        EGL_NONE,
    };
    EGLConfig config;
    EGLint num_configs = 0;
    CHECK(eglChooseConfig(dpy, config_attrs, &config, 1, &num_configs) && num_configs > 0,
          "no matching EGLConfig: 0x%x", eglGetError());

    const EGLint pbuffer_attrs[] = {EGL_WIDTH, 16, EGL_HEIGHT, 16, EGL_NONE};
    EGLSurface surface = eglCreatePbufferSurface(dpy, config, pbuffer_attrs);
    CHECK(surface != EGL_NO_SURFACE, "eglCreatePbufferSurface failed: 0x%x", eglGetError());

    EGLint context_attrs[] = {EGL_CONTEXT_MAJOR_VERSION, CONTEXT_MAJOR, EGL_NONE};
    if (CONTEXT_MAJOR == 0) {
        context_attrs[0] = EGL_NONE;
    }
    EGLContext ctx = eglCreateContext(dpy, config, EGL_NO_CONTEXT, context_attrs);
    CHECK(ctx != EGL_NO_CONTEXT, "eglCreateContext failed: 0x%x", eglGetError());
    CHECK(eglMakeCurrent(dpy, surface, surface, ctx), "eglMakeCurrent failed: 0x%x", eglGetError());

    clear_and_verify();

    eglMakeCurrent(dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    eglDestroyContext(dpy, ctx);
    eglDestroySurface(dpy, surface);
    eglTerminate(dpy);
    printf("PASS\n");
    return 0;
}
