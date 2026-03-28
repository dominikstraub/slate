# Slate

Slate is a window management application similar to Divvy and SizeUp (except better and free!). Originally written to replace them due to some limitations in how each work, it attempts to overcome them by simply being extremely configurable. As a result, it may be a bit daunting to get configured, but once it is done, the benefit is huge.

This is a fork of [mattr-/slate](https://github.com/mattr-/slate) (itself a fork of [jigish/slate](https://github.com/jigish/slate)), updated to build and run on modern macOS and Apple Silicon.

## Requirements

* macOS 26.4 (Tahoe) or later
* Apple Silicon Mac

## Installation

Install via Homebrew:
```bash
brew install dominikstraub/tap/slate
```

To update to a newer version:
```bash
brew update
brew upgrade dominikstraub/tap/slate
```

Alternatively, download the latest DMG from the [Releases](../../releases) page, open it, and drag Slate to your Applications folder.

On first launch, Slate will ask for Accessibility permissions in System Settings > Privacy & Security > Accessibility. This is required for window management to work.

**Note:** If you previously had another version of Slate installed (e.g. the original version, or a different build), you may need to remove the old Slate entry from the Accessibility list before adding the new one. macOS treats each separately signed build as a distinct app, and may ignore newer versions while an old entry is still present.

## Changes from Original

* **Builds on modern Xcode** (26.3+) with zero errors and zero warnings
* **Runs natively on Apple Silicon** (arm64)
* **Removed Sparkle** auto-update framework and legacy build scripts
* **Replaced WebView with JavaScriptCore** — the JS engine (`~/.slate.js`) now uses `JSContext`/`JSValue` instead of the removed WebKit 1 `WebView` class
* **All deprecated APIs replaced** — modern AppKit constants, `NSRunningApplication` for process management, `SMAppService` for login items, `AXIsProcessTrustedWithOptions` for accessibility checks
* **Removed private API usage** — no longer uses `CGSMainConnectionID`/`CGSEventIsAppUnresponsive`
* **Hardened runtime enabled** with proper entitlements for code signing and notarization
* All 21 unit tests passing

## Summary of Features

* Highly customizable
* Bind keystrokes to:
  * move and/or resize windows
  * directionally focus windows
  * activate preset layouts
  * create, delete, and activate snapshots of the current state of windows
* Set default layouts for different monitor configurations which will activate when that configuration is detected
* Window Hints: an intuitive way to change window focus
* A better, more customizable, application switcher

## Building

Open `Slate.xcodeproj` in Xcode and build (Product > Build or Cmd+B).

From the command line:
```bash
xcodebuild -scheme Slate build
```

Run tests:
```bash
xcodebuild test -scheme Slate -destination 'platform=macOS'
```

## Manual

* [Configuring Slate](doc/configuration.md)

## Useful Stuff

* [kvs](https://github.com/kvs) has created a [Sublime Text 2](http://www.sublimetext.com/2) preference for `.slate` files [here](https://github.com/kvs/ST2Slate).
* [trishume](https://github.com/trishume) has done a really nice writeup on getting started with Slate [here](http://thume.ca/howto/2012/11/19/using-slate/).

## License

Slate is licensed under the [GNU General Public License v3.0](LICENSE).

Original code copyright Jigish Patel (2011-2013), Matt Rogers (2014-2018), and contributors. 2026 modernization by Dominik Straub.

This project includes [Underscore.js](https://underscorejs.org/) by Jeremy Ashkenas, distributed under the MIT License.

## Credits

Big thanks to the original authors [jigish](https://github.com/jigish) and [mattr-](https://github.com/mattr-), and to [philc](https://github.com/philc) for the Window Hints idea (and initial implementation) as well as plenty of other suggestions and improvement ideas.
