#include <graphene.h>
#include <math.h>
int main(void) {
  graphene_vec3_t v;
  graphene_vec3_init(&v, 3.f, 4.f, 0.f);
  if (fabsf(graphene_vec3_length(&v) - 5.f) > 0.0001f) return 1;
  graphene_matrix_t matrix;
  graphene_matrix_init_identity(&matrix);
  return !graphene_matrix_is_identity(&matrix);
}
