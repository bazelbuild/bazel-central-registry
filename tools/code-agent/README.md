# Bzlmod Migration Agent Setup

This script prepares your environment for an AI-assisted Bzlmod migration.

## Prerequisites

- Your project has been using Bazel 7.x or later with a `WORKSPACE` file.

## Usage

Run the script from the root of your project:

```bash
python3 tools/code-agent/setup_bzlmod_migration.py
```

The script is interactive and will prompt you for a build target to use for the migration. It will then generate two files in your current directory:

1. `GEMINI.md` (or a custom name): An instruction file with a detailed prompt for the AI agent.
2. `check_repo.sh`: A helper script for the AI to query your legacy `WORKSPACE` setup.

## After Running

1. Make sure `check_repo.sh` works by running `./check_repo.sh <repo name>`, replacing `<repo name>` with a repository you use (e.g., `bazel_skylib`).
2. Setup BCR MCP server if you haven't already. See [BCR MCP Setup Instructions](../../docs/mcp.md).
3. Start your code agent (e.g. Gemini CLI) with the generated agent file as the prompt and the MCP server configured.
4. Prompt the agent to start the migration, e.g., "Migrate my project to Bzlmod using the provided instructions and helper script."
5. Always review the output of the code agent and provide feedback as necessary.
