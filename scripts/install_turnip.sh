#!/data/data/com.termux/files/usr/bin/bash
set -e

# Configurable
GITHUB_USER="abhay-byte"
REPO="turnip-drivers"
RELEASE_TAG="latest"  # or e.g. v25.3.0_R2

# Directories
VULKAN_DRIVER_DIR="$PREFIX/lib/hw/vulkan"
ICD_DIR="$PREFIX/share/vulkan/icd.d"
ICD_FILE="$ICD_DIR/turnip_icd.json"
VCUBE_REPO="https://github.com/KhronosGroup/Vulkan-Tools.git"

# Ensure dependencies
echo "[*] Installing dependencies..."
pkg update -y
pkg install -y git cmake vulkan-loader ninja clang libx11-dev mesa-dev

# Create directories
echo "[*] Creating Vulkan driver directory..."
mkdir -p "$VULKAN_DRIVER_DIR"
mkdir -p "$ICD_DIR"

# Fetch release info from GitHub
echo "[*] Downloading Turnip release from GitHub..."
API_URL="https://api.github.com/repos/$GITHUB_USER/$REPO/releases/$RELEASE_TAG"
ASSET_URL=$(curl -s $API_URL | grep browser_download_url | grep -E 'vulkan\.ad07xx\.so' | cut -d '"' -f 4)

if [ -z "$ASSET_URL" ]; then
    echo "[!] Failed to find 'vulkan.ad07xx.so' in release assets."
    exit 1
fi

curl -L -o "$VULKAN_DRIVER_DIR/vulkan.ad07xx.so" "$ASSET_URL"
chmod 755 "$VULKAN_DRIVER_DIR/vulkan.ad07xx.so"

# Write ICD JSON
echo "[*] Creating ICD JSON..."
cat > "$ICD_FILE" <<EOF
{
  "file_format_version": "1.0.0",
  "ICD": {
    "library_path": "$VULKAN_DRIVER_DIR/vulkan.ad07xx.so",
    "api_version": "1.4.318"
  }
}
EOF

# Build and install vkcube
echo "[*] Building vkcube from Vulkan-Tools..."
cd $HOME
git clone --depth=1 "$VCUBE_REPO"
cd Vulkan-Tools

mkdir -p build && cd build
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release
ninja vkcube

# Test
echo "[*] Running vkcube with VK_ICD override..."
VK_ICD_FILENAMES="$ICD_FILE" ./vkcube
