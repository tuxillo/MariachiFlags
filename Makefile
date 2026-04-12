PROJECT = MariachiFlags.xcodeproj
SCHEME  = MariachiFlags
SIM     = iPhone 17

.PHONY: build run clean

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIM)' \
		-quiet build

run: build
	@# Find the built .app in DerivedData
	$(eval APP := $(shell find ~/Library/Developer/Xcode/DerivedData -path '*/Build/Products/Debug-iphonesimulator/MariachiFlags.app' -maxdepth 5 | head -1))
	xcrun simctl boot '$(SIM)' 2>/dev/null || true
	open -a Simulator
	xcrun simctl install booted '$(APP)'
	xcrun simctl launch booted com.mariachiflags.app

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean -quiet
	rm -rf build/
