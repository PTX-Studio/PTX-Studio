# Release Folder Model

This guide explains how local release folders and GitHub Releases relate to each other.

## The Key Idea

Your Windows folders and GitHub Releases are different systems.

Windows folders organize files by path.

GitHub Releases organize uploaded files by tag.

## Local Windows Folder Model

On your computer, two files with the same name cannot live in the same folder.

That is why local releases should use version folders:

```text
Deployments
└─ ptx-download
   ├─ studio
   │  ├─ latest
   │  │  └─ PTX Studio.exe                ← current live/current version
   │  └─ releases
   │     ├─ v1.1.0
   │     │  └─ PTX Studio.exe             ← archived v1.1.0 copy
   │     └─ v1.2.0
   │        └─ PTX Studio.exe             ← archived v1.2.0 copy
   │
   ├─ editor_express
   │  ├─ latest
   │  │  └─ PTX Editor Express.exe
   │  └─ releases
   │     ├─ v1.1.0
   │     │  └─ PTX Editor Express.exe
   │     └─ v1.2.0
   │        └─ PTX Editor Express.exe
   │
   └─ modules
      └─ editor_pro
         ├─ latest
         │  └─ PTX Editor Pro.exe
         └─ releases
            ├─ v1.1.0
            │  └─ PTX Editor Pro.exe
            └─ v1.2.0
               └─ PTX Editor Pro.exe
```

The `latest` folders are allowed to overwrite old files because `latest` means "current version."

The `releases\vX.Y.Z` folders should not overwrite old releases. Each version gets its own folder.

## GitHub Release Model

GitHub Releases do not work like normal Windows folders.

Each GitHub Release is a separate container attached to a version tag:

```text
GitHub repository: PTX-Studio/PTX-Studio

Releases
├─ PTX Studio 1.1.0
│  Tag: v1.1.0
│  Assets:
│  ├─ PTX Studio.exe
│  ├─ PTX Editor Express.exe
│  └─ PTX Editor Pro.exe
│
└─ PTX Studio 1.2.0
   Tag: v1.2.0
   Assets:
   ├─ PTX Studio.exe
   ├─ PTX Editor Express.exe
   └─ PTX Editor Pro.exe
```

The filenames can be the same because they are attached to different release containers.

The tag is the container label.

## Upload Flow For A New Version

Example: releasing `v1.2.0`.

### Step 1: Keep A Versioned Local Copy

Put the approved files here:

```text
ptx-download\studio\releases\v1.2.0\PTX Studio.exe
ptx-download\editor_express\releases\v1.2.0\PTX Editor Express.exe
ptx-download\modules\editor_pro\releases\v1.2.0\PTX Editor Pro.exe
```

### Step 2: Update Latest

Copy the same files into:

```text
ptx-download\studio\latest\PTX Studio.exe
ptx-download\editor_express\latest\PTX Editor Express.exe
ptx-download\modules\editor_pro\latest\PTX Editor Pro.exe
```

Windows will ask to overwrite in `latest`. That is expected.

### Step 3: Create A GitHub Release Container

On GitHub, create:

```text
Release title: PTX Studio 1.2.0
Tag: v1.2.0
```

### Step 4: Upload Assets Into That Release

Drag these files into the `v1.2.0` GitHub Release page:

```text
PTX Studio.exe
PTX Editor Express.exe
PTX Editor Pro.exe
```

Because the page is the `v1.2.0` release page, GitHub stores those files under `v1.2.0`.

## What Not To Do

Do not drag new `v1.2.0` files into the old `v1.1.0` release page.

Do not commit `.exe` files into this Git repo.

Do not put multiple versions with the same filename into one local Windows folder.

## Simple Rule

Local computer:

```text
Version folders separate versions.
```

GitHub:

```text
Release tags separate versions.
```

