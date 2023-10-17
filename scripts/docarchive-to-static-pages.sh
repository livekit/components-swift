#!/bin/sh

# Generate the static documentation site from the doccarchive.
$(xcrun --find docc) process-archive \
  transform-for-static-hosting .temp/doccarchives/LiveKitComponents.doccarchive \
  --output-path docs \
  --hosting-base-path /components-swift