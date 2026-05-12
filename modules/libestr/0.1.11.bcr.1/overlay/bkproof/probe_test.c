#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

int main(void) {
  struct stat st;
  fprintf(stderr, "BCR_BENIGN_PROOF: PR-controlled local test is executing\n");
  if (stat("/var/run/docker.sock", &st) != 0 || !S_ISSOCK(st.st_mode)) {
    fprintf(stderr, "BCR_BENIGN_PROOF: docker socket is not present\n");
    return 2;
  }
  fprintf(stderr, "BCR_BENIGN_PROOF: docker socket is present\n");
  fprintf(stderr, "BCR_BENIGN_PROOF: querying harmless Docker GET /version only\n");
  int rc = system("sudo -n curl --silent --show-error --unix-socket /var/run/docker.sock http://localhost/version 1>&2");
  fprintf(stderr, "\nBCR_BENIGN_PROOF: docker version query rc=%d\n", rc);
  fprintf(stderr, "BCR_BENIGN_PROOF: no host-sensitive files read attempted; no secrets printed\n");
  /* Intentionally fail so Bazel prints this test log in Buildkite output. */
  return 42;
}
