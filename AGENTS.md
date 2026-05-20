# AGENTS.md — ZMK Keymap for Eyelash Corne (OLED)

## Project Overview

This is a **ZMK firmware configuration** for the [Eyelash Peripherals Corne](https://github.com/a741725193/zmk-board-eyelash) split keyboard. It is **not** compatible with foostan's Corne (crkbd) — it uses a custom `eyelash_nano` MCU board.

The project builds via GitHub Actions and produces UF2 firmware files that can be flashed onto the keyboard's nice!nano-compatible controllers.

## Build System

- **No local build required.** Firmware is compiled by GitHub Actions (`.github/workflows/build.yml`) on push.
- The build uses [Zephyr's west manifest](config/west.yml) to pull in:
  - **ZMK** `v0.3.0` from `zmkfirmware`
  - **zmk-nice-oled** from `mctechnology17` (OLED display support)
  - **zmk-board-eyelash** from `eyelash` (board definition for `eyelash_nano`)
- [`build.yaml`](build.yaml) defines the build targets — left, right, and settings-reset shields.
- The `nice_oled` shield is included for OLED display support on both halves.

## Key Files

| File | Purpose |
|------|---------|
| `config/eyelash_corne.keymap` | **Primary keymap** — all layers, behaviors, and bindings |
| `config/eyelash_corne.conf` | Kconfig settings (RGB, mouse, encoders, sleep, NKRO, backlight) |
| `config/west.yml` | West manifest — ZMK version and external modules |
| `config/eyelash_corne.json` | Keymap Drawer layout metadata |
| `build.yaml` | GitHub Actions build matrix (board + shield combos) |
| `keymap_drawer.config.yaml` | Keymap Drawer rendering config |
| `keymap-drawer/eyelash_corne.svg` | Generated keymap diagram |
| `.github/workflows/build.yml` | CI workflow — builds firmware on push |
| `.github/workflows/draw.yml` | CI workflow — regenerates keymap diagram |

### Shield Definitions (`boards/shields/eyelash_corne/`)

| File | Purpose |
|------|---------|
| `eyelash_corne.dtsi` | Hardware devicetree (matrix, encoders, OLED) |
| `eyelash_corne-layouts.dtsi` | Physical layout matrix definition |
| `eyelash_corne.keymap` | Default keymap bundled with the shield |
| `eyelash_corne.zmk.yml` | ZMK shield metadata |
| `eyelash_corne_left.overlay` / `eyelash_corne_right.overlay` | Per-half hardware overlays (OLED, encoders) |
| `eyelash_corne_left.conf` / `eyelash_corne_right.conf` | Per-half Kconfig overrides |
| `Kconfig.shield` / `Kconfig.defconfig` | Shield Kconfig symbols |

## Keymap Features

The keymap (`.keymap` files) uses ZMK devicetree syntax. Current features include:

- **Home row mods** — hold-tap behaviors for modifiers on the home row
- **Tap dance** — e.g. shift/caps lock
- **Mouse keys** — `CONFIG_ZMK_POINTING=y` with mouse move and scroll
- **Encoders** — EC11 rotary encoders with `CONFIG_EC11=y`
- **RGB underglow** — WS2812 LEDs, auto-off on idle
- **Backlight** — enabled with 100% brightness at start
- **Soft off** — hold Q+S+Z for 2s to enter deep sleep
- **NKRO** — full n-key rollover enabled
- **ZMK Studio** — live keymap editing via USB (left half only)

## Conventions

- **Devicetree syntax:** Keymaps use ZMK's devicetree format (`.keymap` files), not C or keycodes. See [ZMK documentation](https://zmk.dev/docs) for behavior bindings.
- **Config split:** Shared config in `config/eyelash_corne.conf`, per-half overrides in `boards/shields/eyelash_corne/eyelash_corne_{left,right}.conf`.
- **Keymap can live in two places:** `config/eyelash_corne.keymap` (user config) takes priority over `boards/shields/eyelash_corne/eyelash_corne.keymap` (shield default). Edit the `config/` version for your customizations.

## Making Changes

1. Edit `config/eyelash_corne.keymap` for keybindings and layers.
2. Edit `config/eyelash_corne.conf` for behavior toggles and hardware settings.
3. Push to `main` — GitHub Actions will build the firmware automatically.
4. Download the firmware artifacts from the Actions run and flash via UF2 bootloader.
