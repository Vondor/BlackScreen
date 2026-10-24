# AGENTS.md — Black Screen

Rules for any AI agent that changes this repository. The team-wide working rules (roles, pull requests, CI failures, self-merge, notifications, sample data) are in the private repository `Vondor/Agent-Teams`: start at its `AGENTS.md`, then `projects/blackscreen/README.md`. This file wins on anything about this product's code; its boundaries and human gates are never changed from Agent-Teams.

## What it is

A KDE Plasma 6 widget (plasmoid). It shows every connected monitor in its real position; picking one covers every other monitor with a full-screen black window. A global shortcut toggles the same thing. Plain QML in a KPackage, no compiled code.

```
metadata.json               package id, name, version, license
contents/config/main.xml    settings schema (KConfigXT)
contents/config/config.qml  settings pages
contents/ui/main.qml        widget, monitor model, blackout windows, shortcut
contents/ui/ScreenMap.qml   the clickable monitor map
contents/ui/configGeneral.qml  settings page
```

## Boundaries

- **Only modules that ship with every Plasma 6 desktop** (QtQuick, Kirigami, Plasma components, plasmoid). No compiled plugins, no extra runtime dependencies, no network access.
- **Never leave the user with black screens.** Every change keeps at least one way back: clicking a blacked-out monitor (when enabled), the global shortcut, and the widget itself. A blackout must end cleanly when monitors are added or removed.
- **No personal data.** The widget stores only monitor names and options in the applet config.
- UI text in English, with German translations kept in step where they exist (`metadata.json`).
- Keep the SPDX header (`GPL-3.0-or-later`) on every source file.

## Human gates

A pull request that touches any of these waits for the maintainer. Agents never merge it.

- License (`LICENSE`, SPDX headers, `metadata.json` "License")
- Package id (`metadata.json` "Id"); changing it breaks every existing install
- Version number and releases (`metadata.json` "Version", tags, publishing to the KDE Store)
- A new dependency or a raised minimum Plasma version (`X-Plasma-API-Minimum-Version`)
- This file's boundaries or human gates
- CI or workflow changes

## Checks

CI (`.github/workflows/ci.yml`) parses every QML file, `metadata.json` and the settings schema. Run the same locally:

```
for f in $(git ls-files '*.qml'); do /usr/lib/qt6/bin/qmlformat "$f" > /dev/null || exit 1; done
jq empty metadata.json
xmllint --noout contents/config/main.xml
```

CI cannot run Plasma. Behaviour is checked on the maintainer's desktop: he installs the branch and tries it. Hand him one command, for example

```
kpackagetool6 -t Plasma/Applet -u . || kpackagetool6 -t Plasma/Applet -i .
```

then "restart Plasma (`plasmashell --replace &`) or re-add the widget, and you should see …". Before touching his local checkout, follow Agent-Teams `general/rules/local-checkouts.md`.

## Pull requests

- One purpose per pull request, opened from a `claude/…` branch; the body follows `.github/pull_request_template.md` and keeps its full human-gate list.
- Commit messages say what changed and why, for an agent with no memory of the session.
