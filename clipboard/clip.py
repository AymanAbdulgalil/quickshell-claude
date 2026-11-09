#!/usr/bin/env python3
"""Clipboard history store. The only thing that writes the history folder.

  clip.py store          called by wl-paste --watch on every change
  clip.py copy ID        put an entry back on the clipboard
  clip.py pin ID         pin or unpin an entry
  clip.py delete ID      remove an entry
  clip.py clear          remove everything except pinned entries
  clip.py restore        after a reboot: put the newest entry back if the clipboard is empty
"""
import hashlib
import json
import os
import subprocess
import sys
import time

HOME = os.environ["HOME"]
DIR = os.path.join(os.environ.get("XDG_DATA_HOME", HOME + "/.local/share"), "quickshell/clipboard")
INDEX = os.path.join(DIR, "index.json")
MAX_TEXT = 2 * 1024 * 1024
MAX_IMAGE = 40 * 1024 * 1024
TEXT_TYPES = ["text/plain;charset=utf-8", "UTF8_STRING", "text/plain", "STRING", "TEXT"]
IMAGE_TYPES = ["image/png", "image/webp", "image/jpeg", "image/gif", "image/bmp"]
EXTENSIONS = {"image/png": "png", "image/webp": "webp", "image/jpeg": "jpg", "image/gif": "gif", "image/bmp": "bmp"}


def load():
    try:
        with open(INDEX) as f:
            return json.load(f)
    except (OSError, ValueError):
        return []


def save(entries):
    os.makedirs(DIR, mode=0o700, exist_ok=True)
    tmp = INDEX + ".tmp"
    with open(tmp, "w") as f:
        json.dump(entries, f)
    os.replace(tmp, INDEX)


def path_of(entry):
    return os.path.join(DIR, entry["file"])


def remove_file(entry):
    try:
        os.remove(path_of(entry))
    except OSError:
        pass


def limit():
    try:
        with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "settings.json")) as f:
            return int(json.load(f).get("clipboardLimit", 300))
    except (OSError, ValueError):
        return 300


def read(mime):
    return subprocess.run(["wl-paste", "--no-newline", "--type", mime], capture_output=True, timeout=20).stdout


def store():
    # Password managers mark what they copy; never save it.
    if os.environ.get("CLIPBOARD_STATE") in ("sensitive", "nil", "clear"):
        return
    listed = subprocess.run(["wl-paste", "--list-types"], capture_output=True, text=True, timeout=5)
    types = listed.stdout.split("\n")
    if "x-kde-passwordManagerHint" in types:
        return

    mime = next((t for t in TEXT_TYPES if t in types), None)
    data = read(mime) if mime else b""
    kind = "text"
    if not data.strip():
        mime = next((t for t in IMAGE_TYPES if t in types), None)
        if not mime:
            return
        data = read(mime)
        kind = "image"
    if not data or len(data) > (MAX_TEXT if kind == "text" else MAX_IMAGE):
        return

    digest = hashlib.sha256(data).hexdigest()[:16]
    entries = load()
    # The same content again moves to the top instead of repeating, and keeps its pin.
    existing = next((e for e in entries if e["id"] == digest), None)
    if existing:
        entries.remove(existing)
        existing["time"] = int(time.time())
        entries.insert(0, existing)
        save(entries)
        print("changed", flush=True)
        return

    os.makedirs(DIR, mode=0o700, exist_ok=True)
    name = digest + (".txt" if kind == "text" else "." + EXTENSIONS[mime])
    fd = os.open(os.path.join(DIR, name), os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "wb") as f:
        f.write(data)

    entry = {"id": digest, "kind": kind, "mime": "text/plain" if kind == "text" else mime, "file": name,
             "time": int(time.time()), "pinned": False, "size": len(data)}
    if kind == "text":
        entry["text"] = data[:4000].decode("utf-8", "replace")
    entries.insert(0, entry)

    # Oldest unpinned entries go first.
    maximum = limit()
    while len(entries) > maximum:
        drop = next((e for e in reversed(entries) if not e["pinned"]), None)
        if not drop:
            break
        entries.remove(drop)
        remove_file(drop)
    save(entries)
    print("changed", flush=True)


def find(entries, wanted):
    return next((e for e in entries if e["id"] == wanted), None)


def copy(wanted):
    entry = find(load(), wanted)
    if entry:
        with open(path_of(entry), "rb") as f:
            subprocess.Popen(["wl-copy", "--type", entry["mime"]], stdin=f,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def main():
    command = sys.argv[1]
    if command == "store":
        sys.stdin = None
        store()
    elif command == "copy":
        copy(sys.argv[2])
    elif command == "pin":
        entries = load()
        entry = find(entries, sys.argv[2])
        if entry:
            entry["pinned"] = not entry["pinned"]
            save(entries)
    elif command == "delete":
        entries = load()
        entry = find(entries, sys.argv[2])
        if entry:
            entries.remove(entry)
            remove_file(entry)
            save(entries)
    elif command == "clear":
        entries = load()
        for entry in [e for e in entries if not e["pinned"]]:
            entries.remove(entry)
            remove_file(entry)
        save(entries)
    elif command == "restore":
        current = subprocess.run(["wl-paste", "--list-types"], capture_output=True, text=True)
        entries = load()
        if current.returncode != 0 and entries:
            copy(entries[0]["id"])


if __name__ == "__main__":
    main()
