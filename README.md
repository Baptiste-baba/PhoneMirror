# PhoneMirror

A native, open source macOS app to see and use your iPhone from your Mac, over USB.

Apple's iPhone Mirroring is not available in the European Union. PhoneMirror aims to be an everyday alternative: a real Mac app you open and that just works, with smooth video and natural input. It is not a testing or automation tool.

> **Status: early development.** The live video of the iPhone screen works. You can see your iPhone but not control it yet: tap and swipe come in v0.2.

## How it works

- **Video**: the iPhone screen is captured over USB with AVFoundation and CoreMediaIO, the same mechanism QuickTime Player uses. The iPhone's sound can play on the Mac too.
- **Control** (from v0.2): [WebDriverAgent](https://github.com/appium/WebDriverAgent) runs on the iPhone and is driven through its HTTP API over a USB tunnel.

No jailbreak and no private Apple API.

## Using it

1. Plug your iPhone into your Mac with a USB cable, unlock it and tap **Trust** if asked.
2. Open PhoneMirror and allow access to the camera, which covers the iPhone screen. Allow the microphone too if you want the iPhone's sound on the Mac (menu **Présentation › Son de l'iPhone sur le Mac**).

The window is just the iPhone screen, with its rounded corners and Dynamic Island, and follows the iPhone when it rotates:

- **Move** it by dragging the screen.
- **Resize** it from its corners or edges. It keeps the iPhone's proportions.
- **Close** it with ⌘W, and bring it back by clicking the app in the Dock.
- **⌥⌘D** shows the resolution, frame rate and sound level.

## Known limitations

- The iPhone is view only until v0.2.
- An iPhone locked while streaming shows its lock screen as is: the video alone cannot tell it is locked. Detecting it comes with v0.2.
- In landscape, the Dynamic Island is not drawn, since the video does not tell which side it is on.
- Corner radius and Dynamic Island size are approximate. iPhones without a Dynamic Island get approximate corners only.
- The interface is in French only.

## Roadmap

- [ ] **v0.1**: show the iPhone screen in a Mac window (video only)
- [ ] **v0.2**: tap and swipe
- [ ] **v0.3**: keyboard, scrolling, system buttons (Home, App Switcher, Lock)
- [ ] **v1.0**: guided setup and demo

## Building

Requirements: macOS 14 or later (Apple Silicon recommended), Xcode, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
cp Config/Local.xcconfig.example Config/Local.xcconfig   # optional, see below
make run
```

`Config/Local.xcconfig` is not versioned. Set your own bundle ID prefix and Apple Development team in it, so macOS remembers the camera permission across rebuilds.

| Command | Description |
|---|---|
| `make run` | Generate the Xcode project, build and launch the app |
| `make build` | Build only |
| `make open` | Open the generated project in Xcode |
| `make test` | Run the unit tests |
| `make logs` | Stream the app's logs |
| `make clean` | Remove build products and the generated project |

## Project layout

```
App/                    SwiftUI app target (UI and wiring only)
Packages/MirrorKit/     Local Swift package
  Sources/Video/        iPhone screen capture and display
  Sources/Control/      iPhone input (v0.2+)
Config/                 Build settings (xcconfig)
project.yml             XcodeGen project definition
```

## License

[MIT](LICENSE). PhoneMirror is not affiliated with or endorsed by Apple. iPhone and macOS are trademarks of Apple Inc.
