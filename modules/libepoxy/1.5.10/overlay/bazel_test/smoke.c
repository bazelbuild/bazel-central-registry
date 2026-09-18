#include <epoxy/gl.h>
#include <epoxy/egl.h>
#include <epoxy/glx.h>
int main(void) {
  return epoxy_glXQueryVersion == 0 || epoxy_eglInitialize == 0 || epoxy_glGetString == 0;
}
