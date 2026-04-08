# Multi-Machine Workflow

This project is set up to work from multiple computers with GitHub as the remote. The source of truth is the `main` branch on GitHub. The intended workflow is:

1. Clone or update the repo on a machine.
2. Check that you are on the right branch and the working tree is clean.
3. Do work.
4. Commit only source and intentional project files.
5. Push before leaving that machine.
6. Pull on the next machine and continue.

This document is tailored to this repository as it exists now.

## Repository Facts

- Remote: `origin` -> `git@github.com:edwinsaunders/SimRoom.git`
- Main branch: `main`
- No submodules are used
- No Git LFS is used
- Shared project files live at the repo root:
  - `project.godot`
  - `export_presets.cfg`
  - `scenes/`
  - `scripts/`
  - `platform/android/`
  - `docs/`
- Generated and machine-local files are intentionally ignored:
  - `build/`
  - `.godot/`
  - `.xdg_data/`
  - `.xdg_config/`
  - `.xdg_cache/`
  - `android-sdk/`
  - `android-home/`
  - local engine binaries and zip archives

## How This Repo Handles Local State

The Linux launcher [run.sh](/home/edwin/Documents/SimRoom/run.sh) sets:

- `HOME` to the repo root
- `XDG_DATA_HOME` to `.xdg_data/`
- `XDG_CONFIG_HOME` to `.xdg_config/`
- `XDG_CACHE_HOME` to `.xdg_cache/`

That means Redot editor settings, caches, and app userdata stay inside the repo directory on each machine instead of going into your normal home directory. Those folders are ignored in git and should stay machine-local.

This is good for portability, but it also means:

- every machine needs its own local Redot/runtime setup
- Android SDK/JDK settings stored under `.xdg_config/` do not travel through git
- generated import/export output should never be committed

## Fresh Machine Setup

Use this when the machine has never worked on this repo before.

### 1. Install required tools

Minimum tools:

- `git`
- `ssh`
- a Redot editor/runtime compatible with this project

Needed only if you will build Android:

- Java 17
- Android SDK command-line tools
- Android platform/build-tools

Recommended checks:

```bash
git --version
ssh -V
```

If you plan to use the Linux launcher, make sure you have a local Redot binary available. This repo intentionally does not commit the Redot executable.

### 2. Clone the repo

```bash
git clone git@github.com:edwinsaunders/SimRoom.git
cd SimRoom
```

### 3. Confirm branch, remote, and status

```bash
git branch -vv
git remote -v
git status --short --branch
```

Expected baseline:

- branch is `main`
- remote is `origin`
- working tree is clean

### 4. Pull the latest changes

```bash
git fetch origin
git pull --rebase origin main
```

If you prefer tracking branch shortcuts and the branch is already tracking `origin/main`, this is also fine:

```bash
git pull --rebase
```

### 5. Check submodules

This repo currently has no submodules.

Verify if you want:

```bash
git submodule status
```

No output is expected.

### 6. Check large and binary asset handling

This repo does not use Git LFS. Large engine binaries and export outputs are intentionally not committed.

Important implications:

- do not commit `redot.linuxbsd.editor.x86_64`
- do not commit `Redot_v26.1-stable_linux_x64.zip`
- do not commit any `build/` output
- do not commit Android SDK contents

Confirm the ignore rules if needed:

```bash
sed -n '1,260p' .gitignore
```

### 7. Set up your local Redot binary

If you want to use `./run.sh`, place a local Redot binary at:

```text
./redot.linuxbsd.editor.x86_64
```

That file is ignored by git and is expected to be machine-local.

Then:

```bash
chmod +x ./run.sh ./redot.linuxbsd.editor.x86_64
./run.sh
```

Headless smoke test:

```bash
./run.sh --headless --quit-after 120
```

## Daily Workflow On A Machine That Already Has The Repo

### 1. Start from a clean understanding of state

```bash
cd /path/to/SimRoom
git status --short --branch
git branch -vv
```

If there are uncommitted changes, stop and decide whether they should be:

- committed
- stashed
- discarded

### 2. Update from GitHub before new work

```bash
git fetch origin
git pull --rebase origin main
```

This keeps your local work on top of the current remote branch and reduces merge noise.

### 3. Do work

Typical loop:

```bash
./run.sh
```

or:

```bash
./run.sh --headless --quit-after 120
```

### 4. Review changes before committing

```bash
git status --short
git diff --stat
git diff
```

Pay extra attention to accidentally changed generated files.

### 5. Commit with a clear message

```bash
git add <files>
git commit -m "Describe the change clearly"
```

Good commit messages in this repo are short, specific, and outcome-focused.

Examples:

- `Adjust player movement and input handling`
- `Add Android export helper script`
- `Document multi-machine GitHub workflow`

### 6. Push

```bash
git push origin main
```

If `main` is already tracking `origin/main`, `git push` is enough.

## Switching To Another Machine Later

The rule is simple: the next machine should start from GitHub, not from memory.

Before you leave one machine:

1. Check for uncommitted changes.
2. Commit anything that should persist.
3. Push to GitHub.
4. Confirm the push succeeded.

On the next machine:

1. Clone if needed, or enter the existing clone.
2. Fetch.
3. Rebase/pull from `origin/main`.
4. Confirm the working tree is clean.
5. Recreate any machine-local tooling that is not committed, such as the Redot binary or Android SDK setup.

## Before Leaving This Machine

Use this checklist every time:

- `git status --short --branch` shows no surprises
- all intentional work is committed
- `git push origin main` succeeded
- any machine-local setup you changed is documented for yourself if needed
- no build/export artifacts are staged
- no SDK/cache/config directories are staged

Recommended command block:

```bash
git status --short --branch
git diff --stat
git push origin main
```

## When Arriving At Another Machine

Use this checklist:

- confirm `git`, `ssh`, and Redot are available
- `cd` into the repo or clone it
- run `git fetch origin`
- run `git pull --rebase origin main`
- confirm `git status --short --branch` is clean
- restore machine-local Redot binary if needed
- restore Android SDK/JDK config if you plan to export Android
- run `./run.sh --headless --quit-after 120` as a quick sanity check

## What Should Be Committed

Commit these kinds of files:

- gameplay/source files in `scripts/`
- scenes in `scenes/`
- shared project config such as `project.godot`
- shared export config such as `export_presets.cfg`
- docs in `docs/`
- Android helper scripts in `platform/android/`
- tracked script UID files like `scripts/*.uid`

## What Should Not Be Committed

Do not commit these:

- `build/`, `dist/`, `exports/`
- `.godot/`
- `.xdg_data/`, `.xdg_config/`, `.xdg_cache/`
- `android-sdk/`, `android-home/`
- local Redot or old Godot binaries and zip archives
- generated APKs, AABs, PCKs
- temporary files

## Common Mistakes To Avoid

### Forgetting to push

Symptom:

- work exists only on one machine

Avoid it:

- always end with `git push origin main`
- confirm the command succeeded before leaving

### Working on the wrong branch

Symptom:

- commits go to a detached state or an unexpected branch

Avoid it:

```bash
git branch -vv
git status --short --branch
```

This repo should normally be worked on from `main` unless you intentionally create a feature branch.

### Leaving generated build/export files tracked

Symptom:

- `git status` shows `build/` outputs or export products

Avoid it:

- never use `git add .` blindly without reviewing `git status`
- inspect `.gitignore`
- review staged changes with `git diff --cached`

### Machine-specific settings leaking into commits

Symptom:

- editor settings, caches, or SDK paths appear in your diff

Avoid it:

- keep `.xdg_*` and similar machine-local folders ignored
- do not commit local Android SDK or JDK configuration
- do not commit your local Redot executable

### Merge conflicts from generated files

This repo intentionally tracks script `.uid` files in `scripts/`. Those may conflict if two machines or branches regenerate them differently.

Avoid it:

- pull/rebase before starting work
- avoid unnecessary reimports/exports before committing
- if only the `.uid` value changed and the matching script file is unchanged, verify whether the `.uid` change is actually needed before keeping it

## Verifying The Repo Is Safe To Push

Run:

```bash
git status --short --branch
git diff --stat
git diff --cached --stat
```

You want:

- correct branch
- no unexpected untracked files
- no generated outputs staged
- only intentional source/docs/config changes staged

If the repo is clean and committed:

```bash
git push origin main
```

## Command Cheat Sheet

Fresh clone:

```bash
git clone git@github.com:edwinsaunders/SimRoom.git
cd SimRoom
git fetch origin
git pull --rebase origin main
git status --short --branch
```

Normal sync:

```bash
git fetch origin
git pull --rebase origin main
```

Check state:

```bash
git status --short --branch
git branch -vv
git diff --stat
```

Run locally on Linux:

```bash
chmod +x ./run.sh ./redot.linuxbsd.editor.x86_64
./run.sh
```

Headless check:

```bash
./run.sh --headless --quit-after 120
```

Commit and push:

```bash
git add <files>
git commit -m "Describe the change clearly"
git push origin main
```

## Troubleshooting

### Local changes block pull

Check what changed:

```bash
git status --short
```

If you want to keep the work temporarily:

```bash
git stash push -u
git pull --rebase origin main
git stash pop
```

If the changes should be committed:

```bash
git add <files>
git commit -m "Save local work"
git pull --rebase origin main
```

### Detached HEAD

Check:

```bash
git status --short --branch
```

If it says detached `HEAD`, return to `main`:

```bash
git switch main
git pull --rebase origin main
```

If you made commits while detached, stop and inspect `git log --oneline --decorate --all` before switching.

### Merge conflicts

During rebase or pull:

```bash
git status
```

Resolve the files, then:

```bash
git add <resolved-files>
git rebase --continue
```

If you need to abort:

```bash
git rebase --abort
```

### Accidental commit of build artifacts

If not committed yet:

```bash
git restore --staged <file>
rm -rf build
```

If already committed locally but not pushed:

```bash
git rm --cached <file>
git commit --amend
```

If already pushed, make a follow-up commit removing them unless history rewrite is truly necessary.

### Missing tools on a new machine

Minimum:

- install `git`
- install `ssh`
- install or copy a local Redot binary for Linux development

For Android export:

- install Java 17
- install Android SDK command-line tools
- install Android platform/build-tools
- configure them locally for that machine

If `./run.sh` fails because `redot.linuxbsd.editor.x86_64` is missing, that means the local Redot binary has not been set up on that machine yet.
