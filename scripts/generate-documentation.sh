#!/bin/sh

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

# Generate the static documentation site from the doccarchive.
$(xcrun --find docc) process-archive \
transform-for-static-hosting .temp/doccarchives/LiveKitComponents.doccarchive \
--output-path ./docs \
--hosting-base-path LiveKitComponents