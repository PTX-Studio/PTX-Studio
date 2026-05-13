# Launch Checklist

Use this checklist when publishing the PTX Studio customer-facing GitHub repository.

## Local Preflight

- Confirm `git status` is clean.
- Confirm you are working from the intended local checkout of this repository.
- Confirm no application binaries are tracked.
- Confirm no server, storage, hosting, deployment, or private infrastructure files are tracked.
- Confirm issue templates are present.
- Confirm `README.md`, `SUPPORT.md`, `SECURITY.md`, and `CHANGELOG.md` are current.
- Confirm the `releases/` folder contains only customer-facing release notes.

## Recommended Repository Settings

- Repository name: `ptx-studio`
- Visibility: public
- Default branch: `main`
- Issues: enabled
- Pull requests: enabled, preferably restricted to collaborators only if available
- Discussions: optional
- Wiki: disabled
- Projects: optional
- Forking: disable only if GitHub shows the option for this organization/repository
- Preserve this repository: enabled
- Automatically delete head branches: optional

## GitHub Desktop Publish Flow

1. Open GitHub Desktop.
2. Sign in to GitHub if prompted.
3. Add the local repository folder.
4. Click Publish repository.
5. Name it `ptx-studio`.
6. Leave "Keep this code private" unchecked only when you are ready for the repo to be public.
7. Publish.

## After Publishing

- Open the repository on GitHub.com.
- Confirm the public file list looks customer-facing only.
- Confirm no download mirror, upload tooling, website deployment, binaries, manifests, or server details appear.
- Confirm issue templates appear when creating a new issue.
- Add a short repository description.
- Add the official PTX Studio website URL in the repository About panel.
- Review repository Settings > General.
- Review repository Settings > Security.
- Confirm the repository does not display any server-facing folders or files.
- Confirm the contribution policy states that PTX Studio is proprietary.

## First GitHub Release

Create the first GitHub Release from GitHub.com:

1. Go to Releases.
2. Click Draft a new release.
3. Create or choose tag `v1.1.0`.
4. Set title to `PTX Studio 1.1.0`.
5. Paste the notes from `releases/v1.1.0.md`.
6. Publish when ready.

Use GitHub Release attachments only for public files you intentionally want customers to download from GitHub.
