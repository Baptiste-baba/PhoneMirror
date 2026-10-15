PROJECT := PhoneMirror.xcodeproj
SCHEME  := PhoneMirror
DERIVED := build/DerivedData
APP     := $(DERIVED)/Build/Products/Debug/PhoneMirror.app

.PHONY: generate build run test clean open

## Generate the Xcode project from project.yml.
generate:
	xcodegen generate --quiet

## Build the Debug app.
build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-derivedDataPath $(DERIVED) -destination "platform=macOS,arch=$(shell uname -m)" -quiet build

## Build and launch the app.
## `open` (rather than running the binary directly) makes macOS attribute the
## camera permission to PhoneMirror itself instead of your terminal or VSCode.
run: build
	open $(APP)

## Run the MirrorKit unit tests.
test:
	swift test --package-path Packages/MirrorKit

## Remove build products and the generated project.
clean:
	rm -rf build $(PROJECT) Packages/MirrorKit/.build

## Open the generated project in Xcode.
open: generate
	open $(PROJECT)
