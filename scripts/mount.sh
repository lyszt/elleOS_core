#!/bin/bash
# mount_lfs.sh - Mounts the ProvidentiaOS build environment

IMAGE_NAME="../providentia.img" # Adjust path if needed
export LFS="/mnt/lfs"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

# 1. Attach the image to a loop device if not already attached
DISK=$(losetup -j "$IMAGE_NAME" | cut -d: -f1)

if [ -z "$DISK" ]; then
  echo "--- Attaching $IMAGE_NAME..."
  DISK=$(losetup -P -f --show "$IMAGE_NAME")
else
  echo "--- $IMAGE_NAME already attached at $DISK"
fi

# 2. Create mount point
mkdir -pv "$LFS"

# 3. Mount Partition 3 (XFS) as our primary Build Workspace
if ! mountpoint -q "$LFS"; then
  echo "--- Mounting Workspace (Partition 3) to $LFS..."
  mount -v -t xfs "${DISK}p3" "$LFS"
else
  echo "--- $LFS is already mounted."
fi

# 4. Mount Partition 1 (EFI) to /boot
mkdir -pv "$LFS/boot"
if ! mountpoint -q "$LFS/boot"; then
  echo "--- Mounting EFI (Partition 1) to $LFS/boot..."
  mount -v -t vfat "${DISK}p1" "$LFS/boot"
fi

# 5. Final directory and permission checks
if [ -d "$LFS" ]; then
  mkdir -pv "$LFS/sources"
  chmod -v a+wt "$LFS/sources"
fi

echo "---"
echo "Done. Verify with: df -h | grep lfs"
echo "IMPORTANT: Run 'export LFS=/mnt/lfs' in your current terminal now."
