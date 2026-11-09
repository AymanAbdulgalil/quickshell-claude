#!/usr/bin/env python3
"""Prints 1 when a camera is in use and 0 when it is not, once at start and then on every change.

Waits on inotify for /dev/video* being opened or closed, so it costs nothing while nothing happens.
A camera counts as in use when some process still holds it open a moment after the event: apps that
only list the cameras open and close them at once.
"""
import ctypes
import glob
import os
import select
import struct
import sys
import time

IN_OPEN, IN_CLOSE_WRITE, IN_CLOSE_NOWRITE = 0x20, 0x08, 0x10
IN_CREATE, IN_DELETE = 0x100, 0x200
SETTLE = 0.25

libc = ctypes.CDLL(None, use_errno=True)
fd = libc.inotify_init1(os.O_CLOEXEC)
watched = {}


def watch(path, mask):
    wd = libc.inotify_add_watch(fd, path.encode(), mask)
    if wd >= 0:
        watched[path] = wd


def watch_devices():
    for dev in glob.glob("/dev/video*"):
        if dev not in watched:
            watch(dev, IN_OPEN | IN_CLOSE_WRITE | IN_CLOSE_NOWRITE)


def in_use():
    for pid in os.listdir("/proc"):
        if not pid.isdigit() or pid == str(os.getpid()):
            continue
        try:
            for fdname in os.listdir(f"/proc/{pid}/fd"):
                try:
                    if os.readlink(f"/proc/{pid}/fd/{fdname}").startswith("/dev/video"):
                        return True
                except OSError:
                    pass
        except OSError:
            pass
    return False


watch("/dev", IN_CREATE | IN_DELETE)
watch_devices()
state = in_use()
print(int(state), flush=True)

while True:
    select.select([fd], [], [])
    data = os.read(fd, 65536)
    # Gather what follows, then look once.
    deadline = time.monotonic() + SETTLE
    while (left := deadline - time.monotonic()) > 0:
        if select.select([fd], [], [], left)[0]:
            data += os.read(fd, 65536)
    watch_devices()
    now = in_use()
    if now != state:
        state = now
        print(int(state), flush=True)
