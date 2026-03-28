# Installing Slate #

## Accessibility Permissions ##

On first launch, Slate will ask for Accessibility permissions in System Settings > Privacy & Security > Accessibility. This is required for window management to work.

**Note:** If you previously had another version of Slate installed (e.g. the original version, or a different build), you may need to remove the old Slate entry from the Accessibility list before adding the new one.

## Homebrew ##

Install via Homebrew:

```console
$ brew install dominikstraub/tap/slate
```

To update to a newer version:

```console
$ brew update
$ brew upgrade dominikstraub/tap/slate
```

## Manual Install ##

Download the latest DMG from the [Releases](https://github.com/dominikstraub/slate/releases/latest) page, open it, and drag Slate to your Applications folder.

## Build from Source ##

1. Install Xcode.
2. In the terminal, run: `git clone https://github.com/dominikstraub/slate.git ~/Developer/Slate`.
3. Open `~/Developer/Slate/Slate.xcodeproj` with Xcode.
4. Go to **Product** → **Archive** and wait a minute.
5. Once the Archive Organizer pops up, choose the most recently created Slate export. (It should be selected by default.)
6. Click **Export** (on the right).
7. Select **Export as a Mac Application** and click **Next**.
8. Choose where you want to save Slate.app.
9. Run Slate by opening the Finder to where you saved it and double clicking `Slate.app`.
