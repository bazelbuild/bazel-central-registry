#include <stddef.h>

#include <libudev.h>

int main(void) {
   struct udev *udev = udev_new();
   if (udev == NULL)
   {
      return 1;
   }
   struct udev_enumerate *enumerate = udev_enumerate_new(udev);
   if (enumerate == NULL)
   {
      udev_unref(udev);
      return 2;
   }
   udev_enumerate_unref(enumerate);
   udev_unref(udev);
   return 0;
}
