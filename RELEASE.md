# Release Process

## 1. Archive in Xcode

Product > Archive

## 2. Distribute and notarize

In Organizer: select archive > Distribute App > Direct Distribution
Wait for "Ready to Distribute"

## 3. Export notarized app

In Organizer: select archive > Export Notarized App > choose folder

## 4. Staple the ticket to the app

```bash
xcrun stapler staple ./Slate.app
```

## 5. Create DMG

```bash
mkdir -p ./dmg
cp -R ./Slate.app ./dmg/
ln -s /Applications ./dmg/Applications
hdiutil create -volname "Slate" -srcfolder ./dmg -ov -format UDZO Slate.dmg
rm -rf ./dmg
```

## 6. Create GitHub release

```bash
gh release create v<VERSION> Slate.dmg --title "Slate <VERSION>" --notes "release notes here"
```

## 7. Get hash for Homebrew

```bash
shasum -a 256 Slate.dmg
```

## 8. Update Homebrew tap

Update `Casks/slate.rb` in the `homebrew-tap` repo with the new version and SHA256, then commit and push.
