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

## License

GPL-3.0-or-later, see [LICENSE](LICENSE).
