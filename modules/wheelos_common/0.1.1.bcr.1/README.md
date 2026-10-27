# Common source delivery revision

This revision preserves the source commit used by `0.1.1`, packages it as a
checksummed archive and adds an anonymous-consumer presubmit. Its MODULE patch
matches the registry version and selects repaired core/messages/protobuf
revisions. It does not contain the unpublished `0.1.2` development tree or
the new independent perception libraries.

The archive is GitHub-generated from a full commit, not a release attachment.
Required archive/patch integrity and MODULE parity checks pass locally.
The optional URL-stability check requires a disclosed maintainer waiver;
prefer an uploaded immutable release archive for a future source release.
This local entry is not a remote publication.
