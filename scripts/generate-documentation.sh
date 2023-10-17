#!/bin/zsh

mkdir -p .temp/docbuild-output
mkdir -p .temp/doccarchives

# Build the documentation.
xcodebuild docbuild                  \
  -scheme "LiveKitComponents"             \
  -destination 'generic/platform=ios' \
  -derivedDataPath .temp/docbuild-output
  
# Copy the documentation archive where we can find it.
find .temp/docbuild-output               \
  -name "*.doccarchive"              \
  -exec cp -R {} .temp/doccarchives \;



# swift package --allow-writing-to-directory ./docs generate-documentation --target 'LiveKitComponents' --disable-indexing --transform-for-static-hosting --hosting-base-path components-swift --output-path ./docs