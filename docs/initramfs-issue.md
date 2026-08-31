# Debian Kernel Upgrade / initramfs Issue

## Problem

During the Debian kernel upgrade to `6.12.107+deb13-amd64`, `dpkg` appeared to hang while generating the new initramfs:

```text
update-initramfs: Generating /boot/initrd.img-6.12.107+deb13-amd64
```

`mkinitramfs`/`cpio` processes spent a very long time in:

```text
jbd2_log_wait_commit
```

and the kernel stack showed:

```text
jbd2_log_wait_commit
ext4_sync_file
ext4_buffered_write_iter
```

This indicated that the process was waiting on the ext4 journal for `/boot`, rather than being stuck in CPU processing.

The `/boot` filesystem was a small 200 MB ext4 filesystem:

```text
/dev/vda1  200M  ext4  /boot
```

It had plenty of free space and inodes, so this was **not a simple disk-full or inode exhaustion problem**.

A direct write test to `/boot` also showed unusually slow I/O (~14 MB/s):

```text
50 MiB copied, 3.67 s, 14.3 MB/s
```

The initramfs generation could therefore take an extremely long time while waiting for `/boot`'s ext4 journal.

## What we did

The important discovery was that the existing initramfs was already valid:

```text
/boot/initrd.img-6.12.107+deb13-amd64
35M
```

The slow regeneration produced an incomplete temporary:

```text
initrd.img-6.12.107+deb13-amd64.new
```

We **did not replace the known-good initramfs with the incomplete one**.

The kernel package was ultimately configured while temporarily disabling the `/etc/kernel/postinst.d/initramfs-tools` hook, thereby preventing another unnecessary initramfs regeneration.

The existing initramfs was retained.

The `initramfs-tools` package had also been left half-configured because its postinst itself runs `update-initramfs`. We temporarily bypassed that postinst to allow dpkg to complete its bookkeeping, then restored it.

Finally:

```text
dpkg --audit
```

returned no output, confirming a clean package state.

Both VMs were rebooted successfully and confirmed to be running:

```text
6.12.107+deb13-amd64
```

## Root cause / contributing factors

The precise underlying cause of the extremely slow `/boot` writes was not conclusively established.

However, the evidence strongly points to **very slow ext4 journal/write behaviour on the small `/boot` filesystem**, rather than an initramfs, kernel, or dpkg corruption problem.

The `/boot` filesystem was also unusually small at only 200 MB.

## Recommendations

### 1. Increase `/boot` size

This is the biggest preventative measure.

The current 200 MB `/boot` is unnecessarily small for modern Debian systems. Increase it to at least **1 GB**, preferably **1–2 GB**, before the next major Debian upgrade.

This gives sufficient room for multiple kernels and their increasingly large initramfs images.

### 2. Investigate `/boot` storage performance

The journal waits should not normally take hours.

The underlying virtual disk/storage configuration should be investigated, particularly because `/boot` is a separate filesystem/device (`/dev/vda1`) and exhibited much slower behaviour than expected.

If practical, consider recreating `/boot` with a more conventional ext4 configuration rather than continuing to use the very old 200 MB filesystem.

### 3. Do not permanently disable initramfs generation

The temporary hook workaround was appropriate for recovering these VMs because they were **already booting successfully with the new kernel and a valid initramfs**.

It should **not** be made permanent.

Future kernels may require a newly generated initramfs.

### 4. Before future upgrades

Check:

```bash
df -h /boot
```

and ensure there is plenty of free space.

If an initramfs generation appears to hang, check:

```bash
ps -eo pid,stat,etime,wchan:30,cmd | grep -E 'mkinitramfs|cpio|zstd'
```

If `cpio` is stuck in:

```text
jbd2_log_wait_commit
```

investigate `/boot` I/O/journal behaviour rather than simply waiting indefinitely.

## Final state

Both VMs are now:

* Running Debian kernel `6.12.107+deb13-amd64`
* Successfully booting the new kernel
* Using a valid ~35 MB initramfs
* Fully configured according to `dpkg`
* Reporting no issues from `dpkg --audit`

The immediate upgrade problem is resolved, but **the small `/boot` filesystem and abnormal journal/write latency should be addressed before the next major Debian upgrade.**

