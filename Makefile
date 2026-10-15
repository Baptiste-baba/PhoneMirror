NAME    := PhoneMirror
PROJECT := $(NAME).xcodeproj
DERIVED := build/DerivedData
APP     := $(DERIVED)/Build/Products/Debug/$(NAME).app

.PHONY: generate build run logs clean open

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

## Stream the app's logs (full path: zsh has a `log` builtin).
logs:
	/usr/bin/log stream --style compact --level info \
		--predicate 'subsystem == "$(shell xcodebuild -project $(PROJECT) -showBuildSettings 2>/dev/null | awk '/ PRODUCT_BUNDLE_IDENTIFIER =/ { print $$3 }')"'

## Remove build products and the generated project.
clean:
	rm -rf build $(PROJECT) Packages/MirrorKit/.build

## Open the generated project in Xcode.
open: generate
	open $(PROJECT)
