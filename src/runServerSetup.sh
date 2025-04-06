#!/usr/bin/env bash
set -eEu -o pipefail
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CONFIG_IN="Dedicated.xml"
export WINEPREFIX="$(pwd)/cqds"
export WINEARCH="win32"
export WINEDEBUG="-all"
WINE_USER_DIR="$(find "$WINEPREFIX/drive_c/users" -maxdepth 1 -mindepth 1 -type d | grep -v "Public" | head -n 1)"

# Unix Path
ConquestServerDir="$WINEPREFIX/drive_c/Program Files/Electronic Arts/The Lord of the Rings - Conquest Dedicated Server (PC)"
ConquestServerConfigDir="$WINE_USER_DIR/Documents/The Lord of the Rings - Conquest (Server PC)"
ConquestServerConfigFile="$ConquestServerConfigDir/Dedicated.xml"

echo $ConquestServerConfigDir
echo ""
echo "Starting server..."
echo "See the config file:"
echo "----------------------------------------"
# Print the configuration with masked password info
sed -z 's|<Password>.*</Password>|<Password>****</Password>|g' "$CONFIG_IN" | tr '\0' '\n'
echo "----------------------------------------"
echo ""

_term() {
    echo "Caught SIGTERM signal!"

    # Stopping server launcher if present...and wait till it stops...
    if [ ! -z "${WINE_SERVER_PATCHER_PID}" ]; then
        sudo kill -TERM "$WINE_SERVER_PATCHER_PID" 2>/dev/null || true
        wait "$WINE_SERVER_PATCHER_PID"
    fi

    # Stopping game server if present... and wait till it stops...
    if [ ! -z "${WINE_PATCHED_GAMESERVER_PID}" ]; then
        sudo kill -TERM "$WINE_PATCHED_GAMESERVER_PID" 2>/dev/null || true
        wait "$WINE_PATCHED_GAMESERVER_PID"
    fi

    # Stopping Xorg if present... and wait till it stops...
    if [ ! -z "${XORG_PID}" ]; then
        sudo kill -TERM "$XORG_PID" 2>/dev/null || true
        wait "$XORG_PID"
    fi

    exit -1
}
trap _term SIGTERM

# Copy the configuration file to the config directory
mkdir -p "$ConquestServerConfigDir"
cp "$CONFIG_IN" "$ConquestServerConfigFile"

# Check if Levels should be shuffled...
if [[ "$SHUFFLE_LEVELS" == "1" ]]; then
    echo "Shuffling levels..."
    # Shuffle the levels in the config file from the xml file to the same xml file
    python3 shuffleLevels.py "$ConquestServerConfigFile" "$ConquestServerConfigFile"

    echo "[AFTER SHUFFLING]-----------------------"
    # Print the configuration with masked password info
    sed -z 's|<Password>.*</Password>|<Password>****</Password>|g' "$ConquestServerConfigFile" | tr '\0' '\n'
    echo "[AFTER SHUFFLING]-----------------------"
fi

echo "Starting server via Wine..."
export LIBGL_ALWAYS_SOFTWARE=1
export DISPLAY=:0

# Reset Xorg unix socket...
sudo rm -rf /tmp/.* || true
sudo rm -rf "/tmp/.X${DISPLAY}-lock" || true
sudo rm -rf "/tmp/.X11-unix" || true

# Start Xorg (with hidden stdout/stderr)...
sudo Xorg "$DISPLAY" -config /etc/X11/xorg.conf -nolisten tcp -listen unix -noreset +extension GLX +extension RANDR +extension RENDER >/dev/null 2>&1 &
XORG_PID=$!
sleep 2

# Check if Xorg is running....
if ! sudo ps -p "$XORG_PID" >/dev/null 2>&1; then
    echo "Xorg is not running, exiting..."
    exit 1
fi

# Launch the Server launcher...
cd "$ConquestServerDir"
wine "ConquestServer.exe" 2>&1 &
WINE_SERVER_PATCHER_PID=$!

echo "Server launcher started.... Waiting until it closes..."
sleep 2

# Verify that the Xorg server survived the app launch....
if ! sudo ps -p $XORG_PID >/dev/null 2>&1; then
    echo "Xorg is not running, exiting..."
    exit 1
fi

# Wait until the server launcher patched the game server and terminates...
wait $WINE_SERVER_PATCHER_PID
echo "Server launcher closed. Determining the PID of the patched game server..."

# Find OriginalConquestServer.exe PID
WINE_PATCHED_GAMESERVER_PID=$(ps -ax | grep "OriginalConquestServer.exe" | grep -v "grep" | awk '{print $1}')

if [ ! -z "$WINE_PATCHED_GAMESERVER_PID" ]; then
    echo ""
    echo "Patched game server has PID: $WINE_PATCHED_GAMESERVER_PID"
    echo "The server seems to run fine.... :)"
    echo "Waiting until the server closes or prints an error message..."
    echo ""

    # Loop until the PID is gone or the server reports an 'Server Error'
    while true; do
        # Check if the game server is still running...
        if ! ps -p "$WINE_PATCHED_GAMESERVER_PID" >/dev/null 2>&1; then
            # Server is not running anymore...
            echo "Server does not seem to run anymore..."
            break
        fi
        # Server seems to run...

        # Check if a 'Server Error' is present
        X_ERROR_WINDOW=$(xdotool search --name 'Server Error' || true)
        if [ ! -z "$X_ERROR_WINDOW" ]; then
            # Server Error reported....
            echo "A 'Server Error' has been triggered. Pressing 'Enter' to let the game server shut down..."

            # Pressing Return key to confirm the error message (leading the sever to shut down subsequently)
            xdotool key --window "$X_ERROR_WINDOW" Return
            echo "Pressed Return... Waiting to let the server process the input and shut itself down...."
        fi

        # Check again in 10 seconds...
        sleep 10
    done
else
    echo "Could not find the PID of the patched game server..."
fi
echo "Server terminated..."

# Should not be needed, but just in case
sudo kill -SIGTERM "$WINE_SERVER_PATCHER_PID" || true
sudo kill -SIGTERM "$WINE_PATCHED_GAMESERVER_PID" || true

echo "Stopping Xorg..."
sudo kill -SIGTERM "$XORG_PID" || true

# Cleanup Xorg stuff
sudo rm -f "/tmp/.X${DISPLAY}-lock" || true