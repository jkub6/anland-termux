# Nix-on-Droid

This fork supports a minimal, manually started GUI session for individual Linux applications. It does not require GNOME or KDE and does not add an Anland boot service.

## Android companion

From the parent Android workspace:

```sh
nix develop
just build-anland
just check-signing
just install-anland
```

The new `nixOnDroid` flavor installs as `com.anland.nix` (**Anland Nix**). Its components share both UID and process `com.termux.nix` with the main Nix app. Its socket is `/data/data/com.termux.nix/files/usr/tmp/anland/display_daemon.sock`, corresponding to `/tmp/anland/display_daemon.sock` inside Nix-on-Droid. The accessibility service and launcher shortcut use the flavor's application ID. The upstream `standard` and `compatible` flavors retain their Termux identity.

The flavor uses the main workspace app's development keystore, with a matching checked-in key for standalone builds. Android requires matching certificates for shared UIDs. An unrelated official/F-Droid Nix installation may have another certificate; an in-place install will then fail. Do not uninstall an existing Nix environment to fix a signing mismatch without a data backup.

The Nix flavor deliberately targets API 28, matching Nix-on-Droid, while requiring Android 11/API 30 or later for Anland's APIs. Android process compatibility depends on which package starts the shared process first. Using upstream's target 37 caused Nix's foreground service to crash on its legacy PendingIntent when Anland started first. Raising the Nix flavor's target requires updating the host's execution and service behavior together. Gradle's warning about this intentional min/target combination is expected.

Anland uses the pinned, checksum-verified Gradle 9.7.1 wrapper and JDK 21. The parent workspace retains JDK 17 for the older Termux apps and sets `ANLAND_JAVA_HOME` separately. Standalone build:

```sh
JAVA_HOME=/path/to/jdk21 ./gradlew -p app assembleNixOnDroidDebug lintNixOnDroidDebug
```

## Linux packages

`nix/default.nix` exposes `anland`, `weston-anland`, `xwayland-anland`, and `anland-session`. The daemon and compositor sources are pinned with hashes. Weston includes the upstream Anland 5.13 patch series; ordinary Nixpkgs Weston lacks this backend. The packages use a PRoot-compatible source-unpack step where needed.

For a Nix configuration, vendor the `nix/` recipes and import them with the tested Nixpkgs revision `b6c8664de9b6cc07fe5666a29f91884ba81197c4`. Add the resulting packages to `environment.packages`. The Android workspace also exposes these packages; Git-based flake builds need `?submodules=1` and the new files tracked in Git.

The Pixel session uses Mesa software rendering. The Android consumer explicitly requests CPU-accessible buffers before advertising linear DMA buffers; without this, the Pixel 10 displayed corrupted output. The session supplies Fontconfig, a cursor theme, session D-Bus, a private runtime directory, and the XWayland socket directory. XWayland has a narrow PRoot patch: its keyboard compiler skips unsupported identity-changing calls only when real, effective, and saved IDs already match. Audio/camera forwarding is not enabled in this minimal compositor build.

## Run applications

In Nix-on-Droid:

```sh
anland-session
```

Then open **Anland Nix** on Android. A maximized Foot terminal opens with JetBrains Mono Nerd Font, matching the Nix terminal's font family. Launch installed applications from that terminal; it inherits both the Wayland and XWayland display environment. The session continues until stopped with Ctrl-C in the original Nix terminal. If you restart the session while the viewer is open, return to the Android home screen and reopen the viewer to reconnect.

To start a Wayland application from another Nix shell:

```sh
anland-run weston-simple-shm
anland-run weston-simple-egl
```

`anland-run` accepts any installed command and its arguments. For X11 applications, launch from the GUI terminal so they inherit Weston's selected `DISPLAY`. Additional GUI applications can be installed through the usual Nix configuration. Hardware-specific GPU acceleration is not assumed.

Applications still run under PRoot and may need their own compatibility fixes. For example, stock `xterm` renders its window but fails its subprocess `setuid()` call on this phone; use the supplied Foot terminal. Clients without Weston's text-input-v1 support use the upstream keymap-based text fallback, which limits complex IME input.

Logs are in `~/.local/state/anland/{daemon,weston}.log`. Only one managed session runs at a time. Closing or hiding the Android viewer is distinct from stopping the Linux session. Shared-process foreground scheduling helps while the viewer is visible; it does not provide an unconditional Android background-execution exemption.

## Verification

On a Pixel 10 (2026-10-21), all three Android flavors built successfully and the Nix flavor passed lint. Its installed certificate and UID matched Nix-on-Droid. Starting Anland before the host service also worked. Native Nix builds and `nhh` activation succeeded; the manual session rendered Foot, `weston-simple-shm`, `weston-simple-egl`, and the X11 `xeyes` application. Android key events reached a Linux GUI terminal, duplicate sessions were rejected, and stopping the launcher stopped its managed processes. A subsequent reboot restored SSH after unlock without starting the Anland daemon or compositor.
