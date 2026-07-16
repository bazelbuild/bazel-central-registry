import { Buffer } from 'node:buffer';

export default {
    async fetch(request, env, ctx) {
        try {
            return await fetchInternal(request, env, ctx);
        } catch (e) {
            console.error({
                message: 'Unexpected error in fetch handler',
                error: e.message,
                type: e.name
            });
            return new Response('Internal Server Error', { status: 500 });
        }
    }
}

// https://github.com/bazelbuild/bazel/blob/37d25d8a4a7238a1b32377414aa1a1cf68e9daab/src/main/java/com/google/devtools/build/lib/cmdline/RepositoryName.java#L64
const MODULE_REGEX = /^[a-z]([a-z0-9._-]*[a-z0-9])?$/;
// https://github.com/bazelbuild/bazel/blob/37d25d8a4a7238a1b32377414aa1a1cf68e9daab/src/main/java/com/google/devtools/build/lib/bazel/bzlmod/Version.java#L72
const VERSION_REGEX = /^(?<release>[a-zA-Z0-9.]+)(?:-(?<prerelease>[a-zA-Z0-9.-]+))?(?:\+[a-zA-Z0-9.-]+)?$/;

async function fetchInternal(request, env, ctx) {
    const url = new URL(request.url);
    if (request.method !== 'GET') {
        return new Response('Method Not Allowed', { status: 405 });
    }
    if (url.pathname === '/favicon.ico') {
        return new Response('Not Found', { status: 404 });
    }
    if (!url.pathname || url.pathname === '/') {
        return new Response('Bad Request: path must be of the form /module/version', { status: 400 });
    }

    const segments = url.pathname.split('/');
    if (segments.length != 3) {
        return new Response('Bad Request: path must be of the form /module/version', { status: 400 });
    }
    const [_, module, version] = segments;

    // MODULE_REGEX ensures that the module name is not '.' or '..'.
    if (!MODULE_REGEX.test(module)) {
        return new Response('Bad Request: invalid module name', { status: 400 });
    }
    if (!VERSION_REGEX.test(version) || version === '.' || version === '..') {
        return new Response('Bad Request: invalid version format', { status: 400 });
    }

    const sourceJsonUrl = `${env.REGISTRY_URL}/modules/${module}/${version}/source.json`;
    const sourceJsonResponse = await fetch(sourceJsonUrl);
    if (sourceJsonResponse.status === 404) {
        return new Response('Not Found: module or version does not exist', { status: 404 });
    }
    if (!sourceJsonResponse.ok) {
        console.error({
            message: 'Failed to fetch source.json',
            url: sourceJsonUrl,
            status: sourceJsonResponse.status,
            statusText: sourceJsonResponse.statusText,
            module: module,
            version: version
        });
        return new Response('Bad Gateway: error fetching module metadata', { status: 502 });
    }

    const sourceJson = await sourceJsonResponse.json();
    const sourceUrlString = sourceJson['url'];
    const sourceIntegrity = sourceJson['integrity'];
    if (!sourceUrlString || !sourceIntegrity) {
        console.error({
            message: 'Invalid source.json metadata',
            sourceJsonUrl: sourceJsonUrl,
            hasUrl: !!sourceUrlString,
            hasIntegrity: !!sourceIntegrity,
            module: module,
            version: version
        });
        return new Response('Bad Gateway: invalid module metadata', { status: 502 });
    }

    const sourceUrl = new URL(sourceUrlString);
    if (sourceUrl.protocol !== 'http:' && sourceUrl.protocol !== 'https:') {
        console.error({
            message: 'Unsupported URL scheme',
            sourceUrl: sourceUrlString,
            protocol: sourceUrl.protocol,
            module: module,
            version: version
        });
        return new Response('Bad Gateway: unsupported source URL scheme', { status: 502 });
    }
    const sourceIntegrityParts = sourceIntegrity.split('-');
    if (sourceIntegrityParts.length != 2) {
        console.error({
            message: 'Invalid integrity format',
            integrity: sourceIntegrity,
            module: module,
            version: version
        });
        return new Response('Bad Gateway: unsupported integrity format', { status: 502 });
    }
    const [algorithm, hashBase64] = sourceIntegrityParts;
    const hash = Buffer.from(hashBase64, 'base64');
    switch (algorithm) {
        case 'sha256':
            if (hash.length != 32) {
                console.error({
                    message: 'Invalid hash length',
                    algorithm: algorithm,
                    actualLength: hash.length,
                    integrity: sourceIntegrity,
                    module: module,
                    version: version
                });
                return new Response('Bad Gateway: invalid integrity hash', { status: 502 });
            }
            break;
        case 'sha384':
            if (hash.length != 48) {
                console.error({
                    message: 'Invalid hash length',
                    algorithm: algorithm,
                    actualLength: hash.length,
                    integrity: sourceIntegrity,
                    module: module,
                    version: version
                });
                return new Response('Bad Gateway: invalid integrity hash', { status: 502 });
            }
            break;
        case 'sha512':
            if (hash.length != 64) {
                console.error({
                    message: 'Invalid hash length',
                    algorithm: algorithm,
                    actualLength: hash.length,
                    integrity: sourceIntegrity,
                    module: module,
                    version: version
                });
                return new Response('Bad Gateway: invalid integrity hash', { status: 502 });
            }
            break;
        default:
            console.error({
                message: 'Unsupported integrity algorithm',
                algorithm: algorithm,
                module: module,
                version: version
            });
            return new Response('Bad Gateway: unsupported integrity algorithm', { status: 502 });
    }

    const key = `${sourceUrl.hostname}${sourceUrl.pathname}`;
    let object = await env.BUCKET.head(key);
    if (object !== null) {
        return responseFromR2Object(object, algorithm, hash, key);
    }

    const sourceResponse = await fetch(sourceUrl);
    if (!sourceResponse.ok) {
        console.error({
            message: 'Failed to fetch source archive',
            sourceUrl: sourceUrl.toString(),
            status: sourceResponse.status,
            statusText: sourceResponse.statusText,
            module: module,
            version: version
        });
        return new Response('Bad Gateway: error fetching module source', { status: 502 });
    }

    object = await env.BUCKET.put(key, sourceResponse.body, {
        // Don't ever overwrite an existing object.
        onlyIf: {
            etagDoesNotMatch: '*'
        },
        httpMetadata: {
            'Cache-Control': 'public, max-age=31536000, immutable',
        },
        checksums: {
            [algorithm]: hash,
        },
        metadata: {
            // Multiple different modules/versions may point to the same source archive, but we just
            // record the first one that caused the object to be added.
            module: module,
            version: version,
        }
    });
    if (object !== null) {
        return new Response('', { status: 200 });
    }
    // The entry is already present. This can happen if multiple requests for the same uncached
    // object are processed concurrently and should be rare.
    object = await env.BUCKET.head(key);
    if (object !== null) {
        return responseFromR2Object(object, algorithm, hash, key);
    }
    console.error({
        message: 'Failed to retrieve cached object',
        key: key,
        module: module,
        version: version
    });
    return new Response('Internal Server Error: failed to cache module source', { status: 500 });
}

function responseFromR2Object(object, algorithm, hash, key) {
    const actualHash = object.checksums[algorithm];
    // This check performs no validation if the stored object was added with a different digest
    // algorithm. It is a best-effort check meant to help catch mutable source archives, so this
    // is acceptable.
    if (actualHash && !actualHash.equals(hash)) {
        console.error({
            message: 'Hash mismatch for cached object',
            key: key,
            algorithm: algorithm,
            expectedHash: hash.toString('hex'),
            actualHash: actualHash ? actualHash.toString('hex') : null
        });
        return new Response('Bad Gateway: invalid integrity hash for cached object', { status: 502 });
    }
    return new Response('', { status: 200 });
}
