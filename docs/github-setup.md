# GitHub Setup

## Local Repository

This folder is now structured as the Git repository:

`D:\Dev Folder\PTX Studio\Deployments\Github`

Use GitHub Desktop:

1. File > Add local repository.
2. Choose `D:\Dev Folder\PTX Studio\Deployments\Github`.
3. Review changed files before the first commit.
4. Create the repository on GitHub as public only after checking that no ignored files are staged.

## Recommended GitHub Settings

Set:

- Default branch: `main`
- Issues: enabled
- Discussions: optional
- Wiki: disabled unless needed
- Projects: optional
- Secret scanning: enabled if available
- Push protection: enabled if available
- Branch protection for `main`: require pull request or at least require status check `Validate release metadata`

## First Commit Message

Use:

`Initialize PTX Studio release repository`

## Remote Naming

Recommended repository name:

`ptx-studio-releases`

This makes the repo's purpose clear and avoids implying that application source code is present.
