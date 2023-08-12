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

- Review and accept contributions made by the community that align with the BCR contribution policy. Maintainers can merge any PR they have carefully reviewed and is passing CI. BCR maintainer review is required when:
  - Raise a PR to add a new module for the first time to the BCR.
  - Raise a PR to change a presubmit.yml file for a module.
- Assess the health of the BCR by monitoring the BCR testing and serving infrastructure.
- Identify and appoint module maintainers.
- Triage issues in the BCR github repository.

## Become a module maintainer

Every module must have a list of maintainers provided in its metadata.json file. The first contributor to a Bazel module is likely be appointed as the module maintainer. Anyone can apply to be a maintainer of some specific modules. Library authors / rule authors / Bazel users who have special interest on some projects can be module maintainers.

### Responsibilities of a module maintainer

- Review and approve changes related to the designated Bazel module.
- Update new versions for the designated Bazel module.
- Serve as the contact point for issues of their assigned module

## Contacting the repository or module maintainers

Whenever possible, conduct all communication in public on GitHub. Contact maintainers via GitHub or Slack. Contact maintainers over slack group [bzlmod](https://bazelbuild.slack.com/archives/C014RARENH0) when contacting over GitHub is not possible.

### Maintenance timeline expectations

Maintainers are volunteers from the community. Hence, most PRs may be addressed in 3 business days. If a PR is not marked with a label "awaiting user response", then it should be addressed by a register maintainer within 3 days.
