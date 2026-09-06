#include <X11/extensions/Xdamage.h>
int main(void) {
  /* No running display is required to verify that the public API links. */
  Bool (*volatile query)(Display *, int *, int *) = XDamageQueryExtension;
  Damage (*volatile create)(Display *, Drawable, int) = XDamageCreate;
  return query == 0 || create == 0;
}
