def get_repo_name():
    return Label("//:BUILD.bazel").workspace_name
