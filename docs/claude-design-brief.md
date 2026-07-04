# Claude Design Brief: RaytoneCodex Mac UI

Date: 2026-06-09

Design a native macOS desktop client that visually tracks the OpenAI Codex Mac
App as closely as possible while using the RaytoneCodex product name.

## Goal

Create a high-fidelity app-shell design for a Codex-style coding agent client.
This is not a landing page. The first screen must be the working application.

## Required Screen

- Canvas: 1440 x 900, light mode, macOS desktop window.
- Window chrome: Codex-like compact desktop chrome, not a marketing hero.
- Layout:
  - single left sidebar with top actions and thread/project groups
  - central thread transcript
  - bottom composer
  - right context/command/output panel
- Density: compact professional desktop tool. Avoid oversized cards, hero type,
  decorative gradients, and stock-art panels.

## Codex-Like Visual Targets

- Quiet gray/white system surfaces with low-contrast borders.
- Thin dividers, small icon buttons, compact toolbar controls.
- Thread rows and project rows should feel like a desktop sidebar, not a
  website navigation list.
- Transcript should be mostly plain rows with avatars/labels and subtle
  separators; avoid large chat bubbles.
- Composer should be the dominant control: rounded, material-like, floating at
  the bottom of the thread, with small pills for workspace/model/sandbox.
- Right panel should be low contrast and information-dense, with tabs/segments
  for Runtime, Command, Output.

## Functional Slots To Preserve

The implementation already has these live controls and they need visual homes:

- New Thread
- Workspace selector
- Runtime status and CLI version
- Transcript rows for user/system/Codex output
- Prompt input
- Model text field
- Sandbox picker: Read only, Workspace write, Full access
- Approval policy display: current `codex exec` slice is fixed to Headless never
- Run button
- Inspector tabs: Runtime, Command, Output

## Copy

Use concise product UI text only:

- App label: Raytone Codex
- Main thread title: Local Thread
- Composer placeholder: Ask Codex to work in this project
- Runtime label: Bundled CLI

Do not add explanatory product marketing text.

## Deliverables

- One 1440 x 900 light-mode screenshot.
- Optional 1280 x 760 compact screenshot.
- Color tokens for background, sidebar, border, muted text, primary text,
  selected row, composer surface, and accent.
- Spacing notes for sidebar width, inspector width, composer max
  width, transcript max width, and border radii.

## Implementation Notes

The SwiftUI implementation can reproduce the design with:

- sidebar width around 230-260 px
- inspector width around 280-330 px
- central transcript max width around 720-800 px
- rounded corners at 8-12 px for rows/panels and 16-20 px for composer

If a design choice conflicts with Codex fidelity, prefer Codex fidelity over
Raytone branding.
