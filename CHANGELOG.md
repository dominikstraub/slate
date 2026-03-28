# Changelog

## 1.3

Modernized fork by Dominik Straub ([dominikstraub/slate](https://github.com/dominikstraub/slate))

- Requires macOS 26.4 (Tahoe) or later, Apple Silicon only
- Replaced WebView (WebKit 1) with JavaScriptCore (`JSContext`/`JSValue`/`JSExport`)
- Removed Sparkle auto-update framework and legacy build scripts
- Replaced all deprecated APIs with modern equivalents
- Removed private CGS API usage
- Replaced `LSSharedFileList` login items with `SMAppService`
- Replaced `AXAPIEnabled()` with `AXIsProcessTrustedWithOptions()`
- Replaced `GetProcessForPID`/`SetFrontProcessWithOptions` with `NSRunningApplication`
- Enabled hardened runtime with proper entitlements for code signing and notarization

## 1.2

- Removed support for OS X 10.7 and below
- Added options to hide the menu bar icon (jigish/slate#371)
- Converted the test suite to use XCTest

## 1.1

- Exposed the bundle identifier in the JavaScript API app object (jigish/slate#387)
- Added a missing period in the README (jigish/slate#395)
- Prevented Slate from hanging due to unresponsive apps (jigish/slate#414)
- Fixed snapshot operations to properly get the name from the config (jigish/slate#393)
- Updated the README with info for Mavericks (jigish/slate#362)
- Added the ability to use the delete key from larger keyboards (jigish/slate#351)
- Fixed crash due to uninitialized variable (jigish/slate#344)

## 1.0.25

- Updates to JavaScript configs:
  - Added events and event listeners (#239)
  - Allow integers in `screenForRef` (#252)
  - Fixed order of operations issues in corner operation (#241)
  - Allow numbers in options for move-based operations (#233)
  - Fixed `doop` on window object
  - Fixed `screenCount`
- Added link to about page (#240)
- Load default config file properly (#250)
- Fixed undo for move-based operations (#248)
- Allow quoted arguments in shell operation (#253)

## 1.0.24

- Fixed a bug

## 1.0.23

- Updates to JavaScript configs:
  - One-off operations (#220)
  - Don't auto-fail JS operations if there is no window focused (#222)
  - Added `isMovable` and `isResizable` to windows (#218)
  - Added aliases for more functions (#221)
  - Added `visibleRect` to screen (#219)
- Fixed a crash (#206)
- Better error when a key is unrecognized (#217)
- Fixed some minor memory leaks

## 1.0.22

- Updates to JavaScript configs:
  - Added `dup` function to operations
  - `slate.log` now shows the message in the macOS Console for easier debugging

## 1.0.21

- Fixes to JavaScript configs:
  - Sequence and Chain can now take functions as well as objects
  - Screen object `rect()` function now works properly
- Fixed a bug with grid operation that did not take `orderScreensLeftToRight` into account
- Removed all logging in Slate (use the debug version for logs)

## 1.0.20

- Fixes to JavaScript configs
- `nudgePercentOf` and `resizePercentOf` now default to `screenSize`
- Added some documentation for JavaScript configs on the Wiki

## 1.0.19

- JavaScript config file support (beta, #91)
- Modal mode toggle (#172)

## 1.0.18

- Fixed modal bindings (#209)
- JavaScript config file (work in progress, #91)

## 1.0.17

- Merged Pull Request #191 (Fix #190)
- Merged Pull Request #166 (Fix #130)
- Merged Pull Request #204
- Merged Pull Request #185

## 1.0.16

- Added `REPEAT_LAST` and `TITLE_ORDER_REGEX` to layouts

## 1.0.15

- Slate now detects the first screen change properly when `checkDefaultsOnLoad` is false (#177)
- Quoted strings with nested quotes are now allowed

## 1.0.14

- Added `undoOps` config (#171)
- Allow `BEFORE` and `AFTER` operations for layout (#179)
- Allow Window Info to be selectable (#176)

## 1.0.13

- Added undo operation (#165)
- Merged Pull Request #146
- Added `windowHintsIconAlpha` config (#143)
- Added Colemak support (#161)

## 1.0.12

- Enabled `fn` as a modifier (#121)
- Added shell operation (#85)

## 1.0.11

- Better config loading (#131)
- Modal key with modifiers (#125)
- "Load Config" renamed to "Relaunch and Load Config"
- Updated Sparkle

## 1.0.10

- Added hint icons and associated configs (#111)

## 1.0.9

- Added ability to hide, show, and toggle all apps or all except one single app

## 1.0.8

- Added ability to hide, show, and toggle the current app

## 1.0.7

- Added hide, show, and toggle operations (#118)
- Added focus an application (#117)
- Added `layoutFocusOnActivate` config (#103)
- Added modal commands (#100)
- Merged Pull Requests #119, #115, #93

## 1.0.6

- Fixed #109
- Added sequence operation (#114)

## 1.0.5

- Properly fixed #92

## 1.0.4

- Fixed #92
- DMG installation

## 1.0.3

- Upgraded Xcode project
- Added Grid operation
- Added configs: `gridBackgroundColor`, `gridRoundedCornerSize`, `gridCellBackgroundColor`, `gridCellSelectedColor`, `gridCellRoundedCornerSize`

## 1.0.2

- Added `snapshotTitleMatch` config (#76)

## 1.0.1

- Fixed Sparkle

## 1.0.0

- Version bump
- Users should download from the releases page instead of symlinking from git
- Sparkle auto-updates enabled

## 0.6.0

- Added automatic updates through Sparkle

## 0.5.12

- Defaults can now trigger snapshots

## 0.5.11

- Updated Snapshot menu items to persist and not delete
- Added "Launch Slate on Login" menu item

## 0.5.10

- Fixed #72, #74
- Added a default config if no `.slate` file exists

## 0.5.9

- Added Dvorak support (#70)

## 0.5.8

- Fixed #69

## 0.5.7

- Fixed #63

## 0.5.6

- Fixed #66
- Snapshots are now stored in the Application Support directory

## 0.5.5

- New icon

## 0.5.4

- Fixed bad access error

## 0.5.3

- Fixed #58, #60, #61, #62
- Fixed exception on Cmd+Shift+Tab with default switch operation
- Fixed switch operation to properly switch to hidden apps

## 0.5.2

- Added configs: `secondsBeforeRepeat`, `switchSecondsBeforeRepeat`
- Changed defaults: `secondsBetweenRepeat` (0.1, was 0.2), `switchSecondsBetweenRepeat` (0.05, was 0.1)

## 0.5.1

- Fixed unrecognized selector on startup for Mac OS X 10.6 (#56)

## 0.5.0

- Fixed #32
- Release version of Switch operation
- Added/updated configs: `switchOrientation`, `switchSecondsBetweenRepeat`, `switchStopRepeatAtEdge`, `switchOnlyFocusMainWindow`, `switchIconPadding`, `switchFontSize`, `switchFontColor`, `switchFontName`, `switchShowTitles`, `switchType`, `switchSelectedPadding`, `switchSelectedBackgroundColor` (renamed from `switchSelectedColor`), `switchSelectedBorderColor`, `switchSelectedBorderSize`, `switchRoundedCornerSize`
- Added `windowHintOrder` "persist" mode

## 0.4.19

- Fixed #50, #51, #52
- Beta version of Switch operation (#32, work in progress)
- Changed `windowHintsTopLeftX` and `windowHintsTopLeftY` to array configs
- Added `windowHintsOrder` config
- Added support for Cmd+Tab and Cmd+Shift+Tab bindings (disables the default macOS app switcher)
- Changed array config separator from colon to semi-colon (affects `windowHintsFontColor`, `windowHintsBackgroundColor`, `switchBackgroundColor`, `switchSelectedColor`)

## 0.4.18

- Fixed #45, #47, #48
- Pressing Esc will dismiss window hints
- Apps are now ordered by last use for all operations that loop through apps
- UI performance enhancements for window hints
- Pre-release version of Switch operation

## 0.4.17

- Fixed #36, #37, #38, #42
- Added `windowHintsIgnoreHiddenWindows` config
- Added ability to use expressions for `windowHintsHeight` and `windowHintsWidth` configs
- Added `windowHintsTopLeftX` and `windowHintsTopLeftY` configs
- Added menu options to Take/Activate Snapshots

## 0.4.16

- Performance improvements for Window Hints and other minor bug fixes

## 0.4.15

- Fixed #34, #35, #40
- Added `windowHintsRoundedCornerSize` config
- Fixed Current Window Info menu option to allow scroll

## 0.4.14

- Added Window Hints

## 0.4.13

- Switched to ARC (better memory management and performance)

## 0.4.12

- Added Snapshot operations

## 0.4.11

- Added Current Window Info menu option (#20)

## 0.4.10

- Fixed binding parse error when starting up Slate when referencing unconnected screens (#25)

## 0.4.9

- Added `orderScreensLeftToRight` config (default: true)
- Added new monitor identifier "ordered"

**Note:** This version changes the way screen IDs are ordered by default. Set `orderScreensLeftToRight` to false for the old behavior.

## 0.4.8

- Fixed some memory leaks

## 0.4.7

- Added whitelist checking to SlateConfig

## 0.4.6

- Added `focusCheckWidthMax` config

## 0.4.5

- Fixed bug in focus operation that caused some apps to be skipped
- Fixed bug in focus operation that caused same-app switching to be weird

## 0.4.4

- Added the focus directive
- Added `focusCheckWidth` config
- Added `focusPreferSameApp` config
- Fixed all MoveOperation variants to default to semi-colon separators

## 0.4.3

- Fixed bug in StringTokenizer that caused leading spaces in aliases

## 0.4.2

- Added the `if_exists` option for the source directive

## 0.4.1

- Added the source directive

## 0.4

- Added the default directive
- Added `checkDefaultsOnLoad` config

## 0.3.4

- Added the ability to specify resolutions for screens
- Added the ability to specify relative locations for screens
- Added the ability to specify screen for push and corner
- Revamped screen geometry to be more accurate
