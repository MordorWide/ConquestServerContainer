#!/usr/bin/env bash
set -eEu -o pipefail
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Setups
export WINEPREFIX="$(pwd)/cqds"
export WINEARCH=win32

function extractAndCopyDLCFiles() {
    if [ ! -d "Data_DLC" ]; then
        mkdir "Data_DLC"
        unzip -o -q -d "Data_DLC" DLC_Files.zip
    fi
    cp -r "Data_DLC"/* "$WINEPREFIX/drive_c/Program Files/Electronic Arts/The Lord of the Rings - Conquest Dedicated Server (PC)/"
}

function cleanupFiles() {
    # Cleanup the Install and DLC folders and files
    rm -rf Data_DLC DLC_Files.zip
}

# Run the script functions
extractAndCopyDLCFiles
cleanupFiles