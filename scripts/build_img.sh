fallocate -l 20G providentia.img
sudo losetup -fP providentia.img
cat | losetup -a
