#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

function printUsage() {
  console.log(`Usage:
  node tools/cross_module_authz_poc.js \\
    --file modules/rules_go/0.60.0/MODULE.bazel \\
    --file modules/rules_go/0.60.0/source.json \\
    --file modules/abseil-cpp/metadata.json \\
    --approve fmeum

Options:
  --file PATH         Relative PR file path. Repeatable.
  --approve LOGIN     Simulated maintainer approver login. Repeatable.
  --author LOGIN      Simulated PR author login. Defaults to "not-a-maintainer".
  --repo-root PATH    Registry root. Defaults to the parent of this script's directory.
  --help              Show this message.
`);
}

function parseArgs(argv) {
  const options = {
    files: [],
    approvers: [],
    author: "not-a-maintainer",
    repoRoot: path.resolve(__dirname, ".."),
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--file") {
      const value = argv[++i];
      if (!value) {
        throw new Error("--file requires a value");
      }
      options.files.push(value);
      continue;
    }
    if (arg === "--approve") {
      const value = argv[++i];
      if (!value) {
        throw new Error("--approve requires a value");
      }
      options.approvers.push(value.toLowerCase());
      continue;
    }
    if (arg === "--author") {
      const value = argv[++i];
      if (!value) {
        throw new Error("--author requires a value");
      }
      options.author = value.toLowerCase();
      continue;
    }
    if (arg === "--repo-root") {
      const value = argv[++i];
      if (!value) {
        throw new Error("--repo-root requires a value");
      }
      options.repoRoot = path.resolve(value);
      continue;
    }
    if (arg === "--help" || arg === "-h") {
      options.help = true;
      continue;
    }
    throw new Error(`Unknown argument: ${arg}`);
  }

  return options;
}

function fetchAllModifiedModuleVersions(files) {
  const modifiedModuleVersions = new Set();
  for (const filename of files) {
    const match = filename.match(/^modules\/([^/]+)\/([^/]+)\//);
    if (match) {
      modifiedModuleVersions.add(`${match[1]}@${match[2]}`);
    }
  }
  return modifiedModuleVersions;
}

function fetchAllModulesWithMetadataChange(files) {
  const modulesWithMetadataChange = new Set();
  for (const filename of files) {
    const match = filename.match(/^modules\/([^/]+)\/metadata\.json$/);
    if (match) {
      modulesWithMetadataChange.add(match[1]);
    }
  }
  return modulesWithMetadataChange;
}

function generateMaintainersMap(repoRoot, modifiedModules) {
  const maintainersMap = new Map();
  const modulesWithoutGithubMaintainers = [];

  for (const moduleName of modifiedModules) {
    const metadataPath = path.join(repoRoot, "modules", moduleName, "metadata.json");
    if (!fs.existsSync(metadataPath)) {
      modulesWithoutGithubMaintainers.push(moduleName);
      continue;
    }

    const metadata = JSON.parse(fs.readFileSync(metadataPath, "utf8"));
    let hasGithubMaintainer = false;
    for (const maintainer of metadata.maintainers || []) {
      if (!maintainer.github) {
        continue;
      }
      hasGithubMaintainer = true;
      const login = maintainer.github.toLowerCase();
      if (!maintainersMap.has(login)) {
        maintainersMap.set(login, new Set());
      }
      maintainersMap.get(login).add(moduleName);
    }

    if (!hasGithubMaintainer) {
      modulesWithoutGithubMaintainers.push(moduleName);
    }
  }

  return { maintainersMap, modulesWithoutGithubMaintainers };
}

function checkIfAllModifiedModulesApproved(modifiedModules, maintainersMap, approvers, prAuthor) {
  let allModulesApproved = true;
  let anyModuleApproved = false;
  const modulesNotApproved = [];
  const moduleApprovalSources = {};

  for (const moduleName of modifiedModules) {
    let approvedBy = null;
    for (const [maintainer, maintainedModules] of maintainersMap.entries()) {
      if (!maintainedModules.has(moduleName)) {
        continue;
      }
      if (approvers.has(maintainer)) {
        approvedBy = maintainer;
        break;
      }
      if (prAuthor === maintainer) {
        approvedBy = `${maintainer} (pr_author)`;
        break;
      }
    }

    if (approvedBy) {
      anyModuleApproved = true;
      moduleApprovalSources[moduleName] = approvedBy;
    } else {
      allModulesApproved = false;
      modulesNotApproved.push(moduleName);
    }
  }

  return {
    allModulesApproved,
    anyModuleApproved,
    modulesNotApproved,
    moduleApprovalSources,
  };
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printUsage();
    return;
  }
  if (options.files.length === 0) {
    throw new Error("Provide at least one --file");
  }

  const modifiedModuleVersions = fetchAllModifiedModuleVersions(options.files);
  const modifiedModules = new Set(
    Array.from(modifiedModuleVersions, (moduleVersion) => moduleVersion.split("@")[0]),
  );
  const allModulesWithMetadataChange = fetchAllModulesWithMetadataChange(options.files);
  const modulesWithOnlyMetadataChanges = new Set(
    Array.from(allModulesWithMetadataChange, (moduleName) => moduleName).filter(
      (moduleName) => !modifiedModules.has(moduleName),
    ),
  );
  const { maintainersMap, modulesWithoutGithubMaintainers } = generateMaintainersMap(
    options.repoRoot,
    modifiedModules,
  );
  const approvers = new Set(options.approvers);
  const approval = checkIfAllModifiedModulesApproved(
    modifiedModules,
    maintainersMap,
    approvers,
    options.author,
  );

  const result = {
    repoRoot: options.repoRoot,
    prFiles: options.files,
    modifiedModuleVersions: Array.from(modifiedModuleVersions).sort(),
    modifiedModules: Array.from(modifiedModules).sort(),
    allModulesWithMetadataChange: Array.from(allModulesWithMetadataChange).sort(),
    modulesWithOnlyMetadataChanges: Array.from(modulesWithOnlyMetadataChanges).sort(),
    modulesWithoutGithubMaintainers: modulesWithoutGithubMaintainers.sort(),
    maintainersMap: Object.fromEntries(
      Array.from(maintainersMap.entries(), ([maintainer, modules]) => [
        maintainer,
        Array.from(modules).sort(),
      ]),
    ),
    approvers: Array.from(approvers).sort(),
    prAuthor: options.author,
    approval,
    reviewerLogicSummary: {
      metadataOnlyModulesExcludedFromApprovalCheck:
        Array.from(modulesWithOnlyMetadataChanges).sort(),
      requestsBcrMaintainersForMetadataOnlyModules: modulesWithOnlyMetadataChanges.size > 0,
      mergePathReachableUnderCurrentLogic: approval.allModulesApproved,
    },
  };

  console.log(JSON.stringify(result, null, 2));
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
