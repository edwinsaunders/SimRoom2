# Handoff

Use this file as the first thing to read on a new machine or in a new Codex session.

## What To Read First

1. [docs/current-state.md](/home/edwin/Documents/SimRoom2/docs/current-state.md)
2. [docs/exports.md](/home/edwin/Documents/SimRoom2/docs/exports.md)
3. [scripts/main.gd](/home/edwin/Documents/SimRoom2/scripts/main.gd)
4. [scenes/main.tscn](/home/edwin/Documents/SimRoom2/scenes/main.tscn)

## Short Project Summary

This repo is a small Redot 3D starter game that now has:

- two connected rooms
- an interactive door between them
- a procedural animated screen in room one
- a video screen in room two using `output.ogv`
- desktop controls
- mobile touch controls
- Android packaging support
- cross-platform export automation

## Important Current Decisions

- Keep the first room's original screen behavior unchanged.
- Keep the second room video on `output.ogv` with embedded audio, because that is the currently working path on both editor-run desktop and Android.
- Avoid large refactors unless the next feature really demands them.
- Prefer minimal, reviewable changes over architectural churn.

## Current Export Rule Of Thumb

Use [tools/export.py](/home/edwin/Documents/SimRoom2/tools/export.py) for local exports.

In this repo, include `--android-sdk ...` even for desktop exports because the committed Android preset is validated during export startup.

## Suggested Prompt For A New Codex Session

```text
Please inspect docs/current-state.md, docs/handoff.md, docs/exports.md, scenes/main.tscn, and scripts/main.gd first. Then continue from there.
```

If you already know the next feature, append it:

```text
Please inspect docs/current-state.md, docs/handoff.md, docs/exports.md, scenes/main.tscn, and scripts/main.gd first. Then implement <next task> with minimal, reviewable changes.
```

## If You Are Moving To Another Computer

Recommended order:

1. clone or pull the repo
2. read [docs/current-state.md](/home/edwin/Documents/SimRoom2/docs/current-state.md)
3. read [docs/exports.md](/home/edwin/Documents/SimRoom2/docs/exports.md)
4. install the local Redot binary, templates, and Android SDK as needed
5. start the next Codex session with the prompt above

## If You Want The Old Chat Context Too

The repo does not store the chat thread itself. The likely local Codex session/history data on this machine lives under:

- `/home/edwin/.codex/`

If you want the best chance of carrying local Codex history to another machine, copy that directory separately in addition to the repo.
