# Black Screen

A KDE Plasma 6 widget: show one monitor and black out all the others. It draws your monitors in their real arrangement; click one and every other monitor goes black. Click again, click a black monitor, or press the global shortcut to bring them all back.

## Install

```
git clone https://github.com/Vondor/BlackScreen.git
cd BlackScreen
kpackagetool6 -t Plasma/Applet -i .
```

Then add "Black Screen" from the widget list. To update later: `git pull && kpackagetool6 -t Plasma/Applet -u .`

## Settings

- Monitor kept visible by the global shortcut (default: the last one picked)
- Click a black monitor to restore all
- Hide the mouse cursor on black monitors
- Show resolutions, close the popup after picking

## Publisher

Black Screen is published by SerpentSoftware.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/branding/serpentsoftware-mark-dark.svg">
  <img src="docs/branding/serpentsoftware-mark.svg" alt="SerpentSoftware logo" width="64">
</picture>

## License

Code: GPL-3.0-or-later, see [LICENSE](LICENSE). The SerpentSoftware logo is the publisher's brand mark and is not covered by the GPL (`LicenseRef-SerpentSoftware-Logo`, text in [LICENSES/](LICENSES/), files listed in [REUSE.toml](REUSE.toml)): copy it unmodified with the project, but remove it if you publish a fork under your own name.
