# 🪨 Pebble

**Every pebble, a remembrance.**

Pebble is a lightweight macOS menu bar app for counting your dhikr at your desk. Inspired by the early Muslims who counted their remembrance on pebbles and fingertips, Pebble brings that same quiet practice to your modern workflow — one keystroke at a time.

Press your chosen key, and Pebble silently ticks your count without breaking your focus. No windows to open, no apps to switch to. Just you, your intention, and a number in the corner of your screen.

## Features

- Lives quietly in your menu bar — always there, never in the way
- Set any key as your global counter shortcut
- Count persists across sessions so you never lose your place
- Simple, distraction-free design built for focus and presence

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Ramad96/Pebble/main/install.sh | bash
```

This will download the latest release, install it to `/Applications`, and offer to launch it for you.

After launching, grant **Accessibility** access when prompted:

- **System Settings → Privacy & Security → Accessibility → Toggle Pebble on**

Then press **F13** (default) from anywhere to start counting.

### Manual install

1. Download the latest `Pebble.app` from [Releases](https://github.com/Ramad96/Pebble/releases)
2. Move it to your **Applications** folder
3. Open **Pebble** and grant Accessibility access as described above

## Building from Source

1. Clone the repository
2. Open `Pebble.xcodeproj` in Xcode 15 or later
3. Select the **Pebble** scheme and click **Run**

> Requires macOS 13 or later.

---

A product of [AmanahDigital](https://github.com/Ramad96) — building thoughtful tools for the Muslim community.
