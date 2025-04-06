#!/usr/bin/env bash
set -eEu -o pipefail
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Setups
export WINEPREFIX="$(pwd)/cqds"
export WINEARCH=win32

function extractDedicatedServerSetup() {
    if [ ! -d "Data_Setup" ]; then
        mkdir "Data_Setup"
        unzip -o -q -d "Data_Setup" LOTR_Conquest_Server_PC.zip
    fi
}

function installDedicatedServer() {
    if [ ! -d $WINEPREFIX ]; then
        # Start Xorg in the background
        export LIBGL_ALWAYS_SOFTWARE=1
        export DISPLAY=:0
        sudo Xorg "$DISPLAY" -config /etc/X11/xorg.conf -nolisten tcp -listen unix -noreset +extension GLX +extension RANDR +extension RENDER &
        XORG_PID=$!
        sleep 3

        # Check if Xorg is still up
        if ! kill -0 $XORG_PID; then
            echo "Xorg is not running, exiting..."
            exit 1
        fi

        # Run wine-based setup
        wineboot --init
        sleep 1

        # Install Visual C++ 2010 Redistributable
        winetricks -q vcrun2010

        # Add a secondary drive D: (SecuROM may expects an additional drive?!)
        mkdir -p "$WINEPREFIX/dosdevices"
        mkdir -p "$WINEPREFIX/drive_d"
        ln -s "$WINEPREFIX/drive_d" "$WINEPREFIX/dosdevices/d:"

        # Run the actual installer...
        echo "Launching Dedicated Server Setup..."
        wine "Data_Setup/EASetup.exe" &
        WINE_PID=$!

        echo "Step 1"
        # Accept EULA
        echo "Accepting Eula..."
        sleep 10
        xdotool key space

        echo "Step 2"
         # Next
        echo "Pressing 'next' (1)..."
        sleep 2
        xdotool key Return

        echo "Step 3"
        echo "Pressing 'next' (2)..."
        sleep 3
         # Next
        xdotool key Return

        echo "Step 4"
         # Install
        echo "Pressing 'next' (install)..."
        sleep 3
        xdotool key Return

        echo "Step 5"
        # Finish
        echo "Waiting 10 seconds until the setup finishes..."
        echo "...then pressing final 'return' to exit the setup."
        sleep 10
        xdotool key Return

        # Wait for the setup to finish
        echo "Return pressed... Waiting 3 seconds to let the setup close itself..."
        sleep 3

        echo "Dedicated Server Setup finished..."
        sleep 2

        # Xorg should not have been crashed...
        if ! kill -0 $XORG_PID; then
            echo "Xorg is not running, exiting..."
            exit 1
        fi

        # Clean up processes
        kill -SIGTERM $WINE_PID 2>/dev/null || true
        echo "Stopping Xorg..."
        sudo kill -SIGTERM $XORG_PID 2>/dev/null  || true
        sudo rm -f "/tmp/.X${DISPLAY}-lock" 2>/dev/null  || true
    fi
}

function patchDedicatedServer() {
    OriginalConquestServer="$WINEPREFIX/drive_c/Program Files/Electronic Arts/The Lord of the Rings - Conquest Dedicated Server (PC)/OriginalConquestServer.exe"
    if [ ! -f "$OriginalConquestServer" ]; then
        cp "$WINEPREFIX/drive_c/Program Files/Electronic Arts/The Lord of the Rings - Conquest Dedicated Server (PC)/ConquestServer.exe" "$OriginalConquestServer"
        cp "ConquestServer.exe" "$WINEPREFIX/drive_c/Program Files/Electronic Arts/The Lord of the Rings - Conquest Dedicated Server (PC)/ConquestServer.exe"
    fi
}

function cleanupFiles() {
    # Cleanup the Install and DLC folders and files
    rm -rf Data_Setup LOTR_Conquest_Server_PC.zip
    # Remove Mono
    rm -f wine-mono.msi
    # Clean winetricks cache...
    rm -rf .cache
    # Remove the Server Launcher
    rm -f ConquestServer.exe
}

# Run the script functions
extractDedicatedServerSetup
installDedicatedServer
patchDedicatedServer
cleanupFiles