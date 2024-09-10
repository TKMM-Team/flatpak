#!/bin/bash

# Check for required commands
for cmd in jq xmlstarlet curl; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

# File path to the XML
XML_FILE="io.github.tkmm_team.tkmm.metainfo.xml"

# Fetch the latest release data from GitHub
LATEST_RELEASE_JSON=$(curl -s "https://api.github.com/repos/Tkmm-Team/Tkmm/releases/latest")

# Extract version and date from the latest release
LATEST_VERSION=$(echo "$LATEST_RELEASE_JSON" | jq -r '.tag_name')
LATEST_DATE=$(echo "$LATEST_RELEASE_JSON" | jq -r '.published_at' | cut -d'T' -f1)

# Compare and update XML if the latest release is newer
if [[ "$LATEST_VERSION" != "$(xmlstarlet sel -t -v "/component/releases/release[1]/@version" "$XML_FILE")" ]]; then
  # Add new release entry at the top of the releases list
  xmlstarlet ed -L -i "/component/releases/release[1]" -t elem -n "release" -v "" \
    -i "/component/releases/release[1]" -t attr -n "version" -v "$LATEST_VERSION" \
    -i "/component/releases/release[1]" -t attr -n "date" -v "$LATEST_DATE" \
    "$XML_FILE"
  echo "Updated XML with new release version $LATEST_VERSION dated $LATEST_DATE."
  git commit -a -m "Automated metadata update"
  git push origin main
else
  echo "No update needed. Latest release is not newer."
fi