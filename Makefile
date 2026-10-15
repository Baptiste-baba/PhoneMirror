NAME    := PhoneMirror
PROJECT := $(NAME).xcodeproj
DERIVED := build/DerivedData
APP     := $(DERIVED)/Build/Products/Debug/$(NAME).app

.PHONY: generate build run clean open

## Generate the Xcode project from project.yml (skipped when nothing changed).
generate:
	xcodegen generate --quiet --use-cache

## Build the Debug app.
build: generate
	xcodebuild -project $(PROJECT) -scheme $(NAME) -configuration Debug \
		-derivedDataPath $(DERIVED) -destination "platform=macOS,arch=$(shell uname -m)" -quiet build

## Build and launch the app, replacing any running instance.
## `open` (rather than running the binary directly) makes macOS attribute the
## camera permission to the app itself instead of your terminal or VSCode.
run: build
	pkill -x $(NAME) || true
	open $(APP)

## Remove build products and the generated project.
clean:
	rm -rf build $(PROJECT) Packages/MirrorKit/.build

## Open the generated project in Xcode.
open: generate
	open $(PROJECT)
