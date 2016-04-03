# *Unofficial* eXtended Machine Emulator

_UXME_: a build of the popular hardware emulator known as [MAME][mamedev].

**OSX** [![Build Status](https://build.zaplabs.com/bot/png?builder=uxme-osx&size=medium)][buildosx]
**W64** [![Build Status](https://build.zaplabs.com/bot/png?builder=uxme-win-x86_64&size=medium)][buildw64]

### Features

* UI screen white border toggle. (render_border=0)
* Option for running machine unthrottled for a specific interval at start. Useful for skipping through initialization sequence. (faststart=0-2, faststart_skip=0,1)
* Input assignable mute toggle and fix to fully silence.
* Skip loading and warning messages with configuration toggles.
* In-game clock with input assignable toggle.
* Advanced options configuration menu (merged in 0.173).

### Hacks

* Optional single joystick control for Defender, Stargate, and Battlezone

### Notice

Even though this software is almost entirely based on other software, **bugs or request for support should never be sumbitted to any other project**. [Submit issue][issue] to report a bug.

[uxme]: https://build.zaplabs.com/project/uxme/
[issue]: https://github.com/zaplabs/buildsupport
[buildosx]: https://build.zaplabs.com/bot/builders/uxme-osx
[buildw64]: https://build.zaplabs.com/bot/builders/uxme-win_x86_64
