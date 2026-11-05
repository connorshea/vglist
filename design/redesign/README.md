# vglist redesign mockups

A snapshot of the "vglist redesign" canvas from Claude Design
(https://claude.ai/artifact/WcTVMmxeS2w6s2TMCbxESn), pulled in on 2026-11-05 so the
Vue frontend work can reference the mockups and their CSS directly.

The canvas is the source of truth. If it changes, re-export it and replace this
folder rather than editing these files by hand.

## What's here

- `canvas.json`: the canvas index (artboard sizes, pages, order).
- `*.dc.html`: one file per artboard. Each is a self-contained page; the
  `renderVals()` block at the bottom holds the sample data the markup renders.
- `vglist-tokens.css`: color, type and spacing tokens (CSS custom properties,
  light and dark via `data-theme`).
- `ds/vglist/components/bundle.css` and `ds/vglist/tokens.json`: the vglist
  design system (https://claude.ai/artifact/7mN2KmZcUVeCBbCj6cToNR) as it was
  installed into the canvas.
- `pages.css`: page-level layout classes shared by the artboards.

The files expect the Design runtime (`support.js`) and an uploaded logo
(`/_blob/...`), neither of which is included, so they won't render as-is in a
browser. The logo is the same mark as `frontend/src/assets/images/vglist-logo.svg`.

## Artboards

| File | Title | Canvas page |
| --- | --- | --- |
| `Main.dc.html` | Home | Current redesign |
| `Game.dc.html` | Game | Current redesign |
| `GameEdit.dc.html` | Game · editing library entry | Current redesign |
| `Profile.dc.html` | User profile | Current redesign |
| `Activity.dc.html` | Activity | Current redesign |
| `Users.dc.html` | Users | Current redesign |
| `Search.dc.html` | Search overlay | Current redesign |
| `Dialogs.dc.html` | Confirm dialog + snackbars | Current redesign |
| `PhoneGame.dc.html` | Game · phone | Current redesign |
| `PhoneNav.dc.html` | Mobile nav sheet | Current redesign |
| `Nav.dc.html` | NavBar (shared) | Current redesign |
| `LibraryShelves.dc.html` | Library A · Shelves | New: Library |
| `LibraryTable.dc.html` | Library B · Table | New: Library |
| `LibraryBulk.dc.html` | Library B · bulk edit | New: Library |
| `LibraryJournal.dc.html` | Library C · Journal | New: Library |
| `LibraryPhone.dc.html` | Library · phone | New: Library |
| `GamesFilter.dc.html` | Games A · Filter rail | New: Games & more |
| `GamesShelves.dc.html` | Games B · Shelves | New: Games & more |
| `Company.dc.html` | Resource page (Company) | New: Games & more |
| `Settings.dc.html` | Settings · Profile | New: Games & more |
| `SignIn.dc.html` | Sign in | New: Games & more |

"Current redesign" covers pages already built on `main`. The "New" pages hold
proposed directions (three for Library, two for the Games index) that haven't
been picked yet.
