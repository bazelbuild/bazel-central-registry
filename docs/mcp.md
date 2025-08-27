# Bazel Central Registry MCP server

The repository exposes a Model Context Protocol (MCP) server that provides programmatic access to module information.
It is implemented using [FastMCP](https://gofastmcp.com/getting-started/quickstart).

## Running the server

Use Bazel to start the server, no Python virtual environment setup needed:

```bash
bazel run //tools:mcp_server
```

## Available tools

The server registers a set of MCP tools mirroring the functionality of [tools/registry.py](../tools/registry.py):

- `list_modules()` – list all module names in the registry
- `search_modules(pattern)` – search module names using a regex
- `list_versions(module, include_yanked=False)` – list versions for a module
- `get_metadata(module)` – return the module's `metadata.json`
- `get_source(module, version)` – return `source.json` for a version
- `get_patch_file(module, version, patch_name)` – return the patch file content for a given patch
- `get_module_bazel(module, version)` – return the `MODULE.bazel` file
- `get_presubmit_yaml(module, version)` – return `presubmit.yml` if present
- `get_attestations(module, version)` – return `attestations.json` if present
- `get_registry_info()` – return the contents of `bazel_registry.json`

## Set up with Gemini CLI

Add the server to Gemini CLI's [settings](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/configuration.md#settings-files).

```json
  "mcpServers": {
    "BCR": {
      "command": "bazel",
      "args": ["run", "//tools:mcp_server"],
      "cwd": "<Your local path to this repository>",
      "timeout": 5000,
      "trusted": true
    }
  }
```

Make sure to build the target first to reduce startup time.

## Example prompts

- Update all Bazel modules in my MODULE.bazel file.
- What are the dependencies in the latest protobuf version?
- Any version of rules_cc was yanked?
- Show me all modules starting with "rules_"
- Show me the source.json of the latest version of rules_go.
- On which platforms was zlib tested?
- Does the latest rules_cc version have attestations?
- Who are the maintainers of rules_python?
