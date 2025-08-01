#!/data/data/com.termux/files/usr/bin/bash
set -e

# -----------------------------
# Config
# -----------------------------
REPO_OWNER="abhay-byte"
REPO_NAME="turnip-drivers"

VULKAN_DRIVER_DIR="$PREFIX/lib/hw/vulkan"
ICD_DIR="$PREFIX/share/vulkan/icd.d"
ICD_FILE="$ICD_DIR/freedreno_icd.json"

# -----------------------------
# Install dependencies
# -----------------------------
echo "[*] Installing dependencies..."
pkg update -y
pkg install -y wget curl tar vulkan-loader git cmake ninja clang libx11-dev mesa-dev x11-repo termux-x11 jq

# -----------------------------
# Detect latest release from GitHub
# -----------------------------
echo "[*] Fetching latest Turnip release from GitHub..."
LATEST_API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
ASSET_URL=$(curl -s "$LATEST_API" | jq -r '.assets[] | select(.name | endswith(".tar.gz")) | .browser_download_url')
ASSET_NAME=$(basename "$ASSET_URL")
ARCHIVE_DIR="${ASSET_NAME%.tar.gz}"

if [ -z "$ASSET_URL" ]; then
    echo "[!] Could not find .tar.gz asset in latest release."
    exit 1
fi

# -----------------------------
# Setup DISPLAY & X11
# -----------------------------
if [ -z "$DISPLAY" ]; then
  echo "[*] DISPLAY not set. Setting DISPLAY=:0"
  export DISPLAY=:0
fi

if ! pgrep -f "termux-x11" > /dev/null; then
  echo "[*] Starting termux-x11 in background..."
  nohup termux-x11 :0 > /dev/null 2>&1 &
  sleep 2
fi

# -----------------------------
# Download and extract driver
# -----------------------------
cd $HOME
echo "[*] Downloading: $ASSET_NAME"
wget -O "$ASSET_NAME" "$ASSET_URL"

echo "[*] Extracting: $ASSET_NAME"
tar -xf "$ASSET_NAME"

# -----------------------------
# Install Vulkan driver
# -----------------------------
echo "[*] Installing Vulkan driver..."
mkdir -p "$VULKAN_DRIVER_DIR"
cp "$ARCHIVE_DIR/libvulkan_freedreno.so" "$VULKAN_DRIVER_DIR/"
chmod 755 "$VULKAN_DRIVER_DIR/libvulkan_freedreno.so"

# -----------------------------
# Patch and install ICD JSON
# -----------------------------
echo "[*] Patching ICD JSON from archive..."
ORIGINAL_JSON="$ARCHIVE_DIR/freedreno_icd.x86_64.json"

if [ ! -f "$ORIGINAL_JSON" ]; then
    echo "[!] Original ICD JSON not found in archive."
    exit 1
fi

mkdir -p "$ICD_DIR"

jq --arg libpath "$VULKAN_DRIVER_DIR/libvulkan_freedreno.so" \
   '.ICD.library_path = $libpath' \
   "$ORIGINAL_JSON" > "$ICD_FILE"


# -----------------------------
# Clone and build vkcube
# -----------------------------
echo "[*] Cloning and building Vulkan-Tools (vkcube)..."
cd $HOME
rm -rf Vulkan-Tools
git clone --depth=1 https://github.com/KhronosGroup/Vulkan-Tools.git
cd Vulkan-Tools

mkdir -p build && cd build
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release
ninja vkcube

# -----------------------------
# Run vkcube
# -----------------------------
echo "[*] Running vkcube using Turnip..."
VK_ICD_FILENAMES="$ICD_FILE" ./vkcube
