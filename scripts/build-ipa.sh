#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
xcodebuild -version
swiftc DayformWalk/Models.swift DayformWalk/AdventureModels.swift Tests/main.swift -o build/model-tests
build/model-tests
xcodebuild -project DayformWalk.xcodeproj -scheme DayformWalk -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' build
mkdir -p build/Payload
ditto build/DerivedData/Build/Products/Release-iphoneos/DayformWalk.app build/Payload/DayformWalk.app
test -f build/Payload/DayformWalk.app/DayformWalk
test -f build/Payload/DayformWalk.app/Info.plist
(cd build && /usr/bin/zip -qr DayformWalk-unsigned.ipa Payload)
echo 'IPA für die Signierung mit deiner Apple-ID erstellt: build/DayformWalk-unsigned.ipa'
