# Bazel Central Registry (BCR) contribution policies

Contributors should follow these policies when reviewing and accepting modules to the Bazel Central Registry:

- All changes to the BCR repository must be submitted and reviewed as a pull request.
- Add-only: existing module versions must not be modified to ensure reproducible builds.
- Every module version must have a [presubmit.yml](https://docs.google.com/document/d/1moQfNcEIttsk6vYanNKIy3ZuK53hQUFq1b1r0rmsYVg/edit#heading=h.e6t527rxhw5i) file.
-   BCR modules can only depend on modules already in the BCR.

## BCR maintenance policies

Registry maintainers and module maintainers maintain the BCR. BCR maintainers are members of the community who have restricted ability to accept Bazel modules reusable packages into the BCR.

## Become a BCR maintainer

- We recommend contributing and maintaining a Bazel module before becoming a BCR Maintainer.
- All maintainer requests will be reviewed by the [Rules Authors SIG](https://github.com/bazel-contrib/SIG-rules-authors) and the Bazel team before approval.

### Responsibilities of a BCR maintainer

- Review and accept contributions made by the community that align with the BCR contribution policy. Maintainers can merge any PR they have carefully reviewed and is passing CI. BCR maintainer attention is required when:
  - A PR changes a module that has no existing maintainers: this requires the BCR maintainer to approve the PR using GitHub's PR review workflow.
    - This includes when the PR adds an entirely new module, or if the module's sole existing maintainer is also the PR author (since a PR author cannot approve their own PR).
  - A PR changes the presubmit.yml file for a module: this requires the BCR maintainer to apply the `presubmit-auto-run` label to unblock CI.
  - A PR author is a first-time contributor to the BCR: this requires the BCR maintainer to click the "Approve and run" button to unblock certain GitHub actions.
- Assess the health of the BCR by monitoring the BCR testing and serving infrastructure.
- Identify and appoint module maintainers.
- Triage issues in the BCR GitHub repository.

### BCR maintainer playbook

Here are steps that a BCR maintainer should keep in mind when reviewing PRs:

- When a PR adds an entirely new module to the BCR, perform a sanity check on its name.
  - Ideally, the name is succinct and unambiguous. Overly generic names should be avoided unless it's well-known in the developer community. (If the project is hosted on GitHub, the number of stars would provide a good basic signal.) If necessary, ask the PR author to prepend their user or org to the module name.
  - For example, a module named `package-utils` would be too generic. `mycompany-package-utils` would work instead.
- When a PR adds to a module with no existing maintainers (including if the module is new), encourage the PR author to take on module maintainership.
  - Modules with no maintainers always require BCR maintainer review, which adds to response times and toil.
- When a module version uses overlays, remind PR authors to include `bazel_compatibility` of at least `7.2.1`.
- When a PR contains C++ modules with BUILD patches or overlays, encourage usage of a build target with the same name as the module itself.
  - This enables the shortform label syntax `@foo`, which is shorthand for `@foo//:foo`.
  - For modules whose name start with `lib` (for example, `libfoo`), ask for a target named `foo` with an alias named `libfoo` pointing to `foo` ([example](https://github.com/bazelbuild/bazel-central-registry/pull/3821#discussion_r1959200504)).
- When a PR contains C++ modules with BUILD patches or overlays, double check visibility specifications.
  - PR authors sometimes forget `//visibility:public`, and this is often not caught unless the presubmit.yml has a test module.
  - Encourage PR authors to keep the set of publicly visible targets small.
- When a PR contains C++ modules with large BUILD overlays, ask for some documentation on how these BUILD files are created.
  - Such documentation can either be in a `README.md` file under the module directory, or simply be some comments in the BUILD overlays.
- When a PR's CI checks are blocked because its presubmit.yml has changed, review those changes before applying the `presubmit-auto-run` label to unblock CI.
  - Look for the "Generate module diff" check, which produces a diff of the module version under review versus the latest checked-in version.
  - If possible, encourage PR authors to add the latest LTS track to the `bazel` field in `presubmit.yml`.

## Become a module maintainer

Every module must have a list of maintainers provided in its metadata.json file. The first contributor to a Bazel module is likely be appointed as the module maintainer. Anyone can apply to be a maintainer of some specific modules. Library authors / rule authors / Bazel users who have special interest on some projects can be module maintainers.

### Responsibilities of a module maintainer

- Review and approve changes related to the designated Bazel module.
  - Module maintainers can use the normal GitHub PR review process to approve PRs, despite not having write access to the BCR repo. See the contribution guidelines for [approval and submission](https://github.com/bazelbuild/bazel-central-registry/blob/main/docs/README.md#approval-and-submission) for more details.
- Update new versions for the designated Bazel module.
- Serve as the contact point for issues of their assigned module.

## Contacting the repository or module maintainers

Whenever possible, conduct all communication in public on GitHub. Contact maintainers via GitHub or Slack. Contact maintainers over slack group [bzlmod](https://bazelbuild.slack.com/archives/C014RARENH0) when contacting over GitHub is not possible.

### Maintenance timeline expectations

Maintainers are volunteers from the community. Hence, most PRs may be addressed in 3 business days. If a PR is not marked with a label "awaiting user response", then it should be addressed by a register maintainer within 3 days.
