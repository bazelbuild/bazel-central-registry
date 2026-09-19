#!/usr/bin/env python3
"""Read-only IAM boundary canary for the BCR CI security assessment."""

import json
import sys
import urllib.error
import urllib.parse
import urllib.request

METADATA_ROOT = "http://169.254.169.254/computeMetadata/v1"


def metadata(path):
    request = urllib.request.Request(
        f"{METADATA_ROOT}/{path}", headers={"Metadata-Flavor": "Google"}
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=5) as response:
        return response.read()


def request_json(access_token, url, *, permissions=None):
    data = None
    method = "GET"
    headers = {"Authorization": f"Bearer {access_token}"}
    if permissions is not None:
        data = json.dumps({"permissions": permissions}).encode()
        method = "POST"
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(
        url, data=data, headers=headers, method=method
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    try:
        with opener.open(request, timeout=10) as response:
            return response.status, json.loads(response.read())
    except urllib.error.HTTPError as error:
        # The status is enough to distinguish a denied or absent resource.
        # Deliberately do not print any response body or request credential.
        return error.code, {}


def post_permissions(access_token, service, resource, permissions):
    encoded_resource = urllib.parse.quote(resource, safe="/")
    status, result = request_json(
        access_token,
        f"https://{service}/v1/{encoded_resource}:testIamPermissions",
        permissions=permissions,
    )
    return status, set(result.get("permissions", []))


def storage_permissions(access_token, bucket, permissions):
    query = urllib.parse.urlencode(
        [("permissions", permission) for permission in permissions]
    )
    encoded_bucket = urllib.parse.quote(bucket, safe="")
    status, result = request_json(
        access_token,
        f"https://storage.googleapis.com/storage/v1/b/{encoded_bucket}/iam/testPermissions?{query}",
    )
    return status, set(result.get("permissions", []))


def emit(name, value):
    print(f"BCR_BOUNDARY_{name}={value}", file=sys.stderr, flush=True)


def emit_permission_result(name, status, allowed, permissions):
    emit(f"{name}_API_STATUS", status)
    for permission in permissions:
        suffix = permission.upper().replace(".", "_")
        emit(f"{name}_{suffix}", str(permission in allowed).lower())


def main():
    token_document = json.loads(
        metadata("instance/service-accounts/default/token").decode()
    )
    access_token = token_document["access_token"]

    secret_permission = ["secretmanager.versions.access"]
    secrets = {
        "CURRENT_AGENT_SECRET": (
            "secretmanager.googleapis.com",
            "projects/bazel-untrusted/secrets/bazel-buildkite-agent-token",
        ),
        "TESTING_AGENT_SECRET": (
            "secretmanager.googleapis.com",
            "projects/bazel-untrusted/secrets/bazel-testing-buildkite-agent-token",
        ),
        "TRUSTED_AGENT_SECRET": (
            "secretmanager.googleapis.com",
            "projects/bazel-public/secrets/bazel-trusted-buildkite-agent-token",
        ),
    }
    for name, (service, resource) in secrets.items():
        status, allowed = post_permissions(
            access_token, service, resource, secret_permission
        )
        emit_permission_result(name, status, allowed, secret_permission)

    object_permissions = [
        "storage.objects.create",
        "storage.objects.delete",
        "storage.objects.get",
        "storage.objects.list",
        "storage.objects.update",
    ]
    buckets = {
        "UNTRUSTED_ARTIFACT_BUCKET": "bazel-untrusted-buildkite-artifacts",
        "UNTRUSTED_LAST_GREEN_BUCKET": "bazel-untrusted-last-green-commits",
        "BCR_PUBLIC_BUCKET": "bcr.bazel.build",
        "BAZEL_BUILDS_BUCKET": "bazel-builds",
        "BAZEL_MIRROR_BUCKET": "bazel-mirror",
    }
    for name, bucket in buckets.items():
        status, allowed = storage_permissions(
            access_token, bucket, object_permissions
        )
        emit_permission_result(name, status, allowed, object_permissions)

    decrypt_permission = ["cloudkms.cryptoKeyVersions.useToDecrypt"]
    kms_keys = {
        "UNTRUSTED_ANALYTICS_KEY": (
            "projects/bazel-untrusted/locations/global/keyRings/buildkite/"
            "cryptoKeys/buildkite-untrusted-api-token"
        ),
        "TRUSTED_ANALYTICS_KEY": (
            "projects/bazel-public/locations/global/keyRings/buildkite/"
            "cryptoKeys/buildkite-trusted-api-token"
        ),
    }
    for name, resource in kms_keys.items():
        status, allowed = post_permissions(
            access_token,
            "cloudkms.googleapis.com",
            resource,
            decrypt_permission,
        )
        emit_permission_result(name, status, allowed, decrypt_permission)

    impersonation_permissions = [
        "iam.serviceAccounts.actAs",
        "iam.serviceAccounts.getAccessToken",
        "iam.serviceAccounts.signBlob",
        "iam.serviceAccounts.signJwt",
    ]
    trusted_service_account = (
        "projects/bazel-public/serviceAccounts/"
        "buildkite-trusted@bazel-public.iam.gserviceaccount.com"
    )
    status, allowed = post_permissions(
        access_token,
        "iam.googleapis.com",
        trusted_service_account,
        impersonation_permissions,
    )
    emit_permission_result(
        "TRUSTED_SERVICE_ACCOUNT",
        status,
        allowed,
        impersonation_permissions,
    )

    # Fail intentionally so Bazel exposes only these non-secret booleans.
    return 87


if __name__ == "__main__":
    raise SystemExit(main())
