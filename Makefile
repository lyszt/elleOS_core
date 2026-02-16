IMAGE      := ElleOS.img
MNT        := mnt_image
LOOP_DEV    = $(shell losetup -j $(IMAGE) | cut -d: -f1)

.PHONY: mount umount chroot

mount:
	@if [ "$$(id -u)" -ne 0 ]; then echo "Run with sudo"; exit 1; fi
	@if [ -z "$(LOOP_DEV)" ]; then \
		echo "--- Attaching $(IMAGE)..."; \
		losetup -Pf --show $(IMAGE); \
	else \
		echo "--- $(IMAGE) already attached at $(LOOP_DEV)"; \
	fi
	@mkdir -p $(MNT)
	@if ! mountpoint -q $(MNT); then \
		echo "--- Mounting root (p3) to $(MNT)..."; \
		mount -t xfs "$$(losetup -j $(IMAGE) | cut -d: -f1)p3" $(MNT); \
	else \
		echo "--- $(MNT) already mounted."; \
	fi
	@mkdir -p $(MNT)/boot
	@if ! mountpoint -q $(MNT)/boot; then \
		echo "--- Mounting EFI (p1) to $(MNT)/boot..."; \
		mount -t vfat "$$(losetup -j $(IMAGE) | cut -d: -f1)p1" $(MNT)/boot; \
	fi
	@echo "--- Mounted."

umount:
	@if [ "$$(id -u)" -ne 0 ]; then echo "Run with sudo"; exit 1; fi
	-@mountpoint -q $(MNT)/boot && umount $(MNT)/boot
	-@mountpoint -q $(MNT) && umount $(MNT)
	@if [ -n "$(LOOP_DEV)" ]; then \
		losetup -d $(LOOP_DEV); \
		echo "--- Detached $(LOOP_DEV)."; \
	fi
	@echo "--- Unmounted."

chroot: mount
	@if [ "$$(id -u)" -ne 0 ]; then echo "Run with sudo"; exit 1; fi
	@echo "--- Binding virtual filesystems..."
	@mkdir -p $(MNT)/{dev,proc,sys,run}
	@mountpoint -q $(MNT)/dev  || mount --bind /dev  $(MNT)/dev
	@mountpoint -q $(MNT)/proc || mount -t proc proc $(MNT)/proc
	@mountpoint -q $(MNT)/sys  || mount -t sysfs sys  $(MNT)/sys
	@mountpoint -q $(MNT)/run  || mount -t tmpfs tmpfs $(MNT)/run
	@echo "--- Entering chroot..."
	chroot $(MNT) /bin/bash
