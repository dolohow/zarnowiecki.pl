---
title: "Btrfs RAID1 does not mount after upgrade to Linux 5.11"
date: 2021-08-18T10:55:46+02:00
summary: This could happen since there is a new sanity check in newer
         kernel.  Error message is _device total_bytes should be at
         most 6000606183424 but found 6001175126016_
draft: true
---

## Situation
I upgraded kernel to 5.11 on my server where I am using Btrfs RAID1 for
storing data on rotational disks and I found that it did not mount and
there are no files where they should be.

I did not panic, because I knew it must have something to do with kernel
upgrade.  I took a quick look at `dmesg`.  The error message was saying:

```
[ 202.604064] BTRFS error (device sdd): device total_bytes should be at most 6000606183424 but found 6001175126016 
```

A quick DuckDuckGo search revealed that this problem occurs after
upgrading to kernel 5.11, since they added a new sanity check to uncover
some funny bugs.  There was a
[solution](https://bugs.archlinux.org/task/69778) I found, saying I need
to boot to previously working kernel (5.8 in my case) and invoke:
```
btrfs filesystem resize max /path/to/mount
```

In order to boot the previous kernel, I had to instruct GRUB to do me a
favor. At the third attempt, I manage to pick the correct number for the
following command:

```
grub-reboot 1>3  # ">" means inside submenu
```

But that Btrfs resize command did not work, and I had to dig deeper.

I found a bugs report at
[launchpad](https://bugs.launchpad.net/ubuntu/+bug/1931790), reporter
had the same problem, plus the command did not work for him as well.  He
managed to fix his problem by reformatting partitions.  I asked for some
commands, but he did not have them handy.  I had to do it on my own.

## Solution
First, I had to take out one disk from the array:
```
btrfs balance start -sconvert=single,devid=1 -dconvert=single,devid=1 -mconvert=single,devid=1 -f <mountpoint>
```

You can find out your _devid_ by issuing:
```
btrfs fi show /mnt/storage
```

Now, I have no idea why this operation takes so long.  I had the feeling
that it zeroed the other disk... No idea.  I was seriously thinking
about just reformatting that disk, but I was afraid that kernel would
try to write to it and that would fail miserably... So I patiently wait.

Now I could remove disk and reformat it, previously it would fail saying
that disk is in use.  In my case, _devid=2_ was _/dev/sdc_:
```
btrfs device delete /dev/sdc <mountpoint>
mkfs.btrfs /dev/sdc
```

Almost last step.  I had to create a snapshot of the _old disk_ and copy
data over to the _new disk_.  Snapshot is needed for consistency, but
you might have different use case.  My server was online thought out
this process the whole time, and it took a week to complete all of these
operations and I do not want to risk data inconsistency.

```
mkdir /mnt/new_disk
mount /dev/sdc /mnt/new_disk
btrfs subvolume snapshot -r <mountpoint> <mountpoint>/ss
rsync -aAXHSv --info=progress2 --delete <mountpoint>/ss /mnt/new_disk
```

Now I can remove snapshot, stop services and do last sync that suppose
to be quick (it took 2 hours):
```
rsync -aAXHSv --info=progress2 --delete <mountpoint> /mnt/new_disk
```

Now I need to tweak `/etc/fstab`, but before doing so, I had to find out
UUID of my `/dev/sdc`.  This should do the trick:
```
blkid | grep /dev/sdc
```

...And reboot.  Hope that works or I am screwed.

It did!  Partition was mounted successfully.  Last step is to create
RAID1 out of _old disk_

```
btrfs balance start -dconvert=raid1 -mconvert=raid1 <mountpoint>
```

Once it is done, you should see something similar:
```
btrfs fi df /mnt/storage

Data, RAID1: total=2.37TiB, used=2.37TiB
System, RAID1: total=64.00MiB, used=368.00KiB
Metadata, RAID1: total=7.00GiB, used=5.82GiB
GlobalReserve, single: total=512.00MiB, used=0.00B
```

## Bottom line
The whole process took one week and data was copied many times, and I
was a bit afraid what would happen in the event of power loss or if one
disk would just fail. Thankfully, it was butter smooth. I was also
considering switching to a different file system, because of errors like
this, but checksumming made me stay with Btrfs. Honestly, I am even
running RAID5 for a year and did not have any issues with this file
system till today.


