#!/usr/bin/env bash
# A small script to build the registry and download a few pages for a static build

set -euo pipefail
set -x

DMD_VERSION="2.085.0"
BUILD_DIR="out"

CURL_FLAGS=(-fsSL --retry 10 --retry-delay 30 --retry-max-time 600 --connect-timeout 5 --speed-time 30 --speed-limit 1024)

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${DIR}"

. "$(curl "${CURL_FLAGS[@]}" https://dlang.org/install.sh | bash -s install "dmd-${DMD_VERSION}" --activate)"

# Build and start the doc server
dub build
./dub-docs &
PID_DOCS=$!
sleep 1s

DOCS_URL="http://127.0.0.1:8005"

# ignore pages with a ? (not supported by netlify)
# Netlify doesn't support filenames containing # or ? characters
# TODO: replace all files and links containing a ? with e.g. _
# with the reject files with ? + most package version listings are rejected
wget --mirror --level 6 --convert-links --adjust-extension --page-requisites --no-parent ${DOCS_URL} || true
echo "Finished mirroring."

mv "127.0.0.1:8005" ${BUILD_DIR}
# Chrome doesn't like images without an extension
find out -name "logo" | xargs -I {} mv {} {}.svg
sed 's/src="\([^"]*\)\/logo"/src="\1\/logo.svg"/'  -i $(find out -name "*.html")

# Replace all local links with dub.pm
sed 's/http:\/\/127.0.0.1:8005/https:\/\/dub.pm/'  -i $(find out -name "*.html")

kill -9 $PID_DOCS || true

# Final cleanup (in case something was missed)
pkill -9 -P $$ || true
