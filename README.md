# Bazel Central Registry

**Status:** This repository is still in alpha test phase, the content may not be accurate and can change without any notice.

## Goal
A registry of Bazel modules for the Bzlmod external dependency system. It is the recommended place to publish your Bazel open source projects for downstream users.

For more information, see the [Bazel Central Registry Policies and Procedures](https://docs.google.com/document/d/1ReuBBp4EHnsuvcpfXM6ITDmP2lrOu8DGlePMUKvDnXM/edit?usp=sharing).

## Add a new module

You can start with the interactive helper script
```
python3 ./tools/add_module.py
```