{ lib, writeShellApplication, writeShellScript, writeText, symlinkJoin, anland, weston-anland
, mesa, coreutils, util-linux, dbus, makeFontsConf, dejavu_fonts, vanilla-dmz
, foot, nerd-fonts, xwayland-anland }:
let
  fonts = makeFontsConf { fontDirectories = [ dejavu_fonts nerd-fonts.jetbrains-mono ]; };
  terminal = writeShellScript "anland-terminal" ''
    exec ${foot}/bin/foot --maximized --font="JetBrainsMono Nerd Font:size=14"
  '';
  config = writeText "weston-anland.ini" ''
    [core]
    idle-time=0
    xwayland=true

    [xwayland]
    path=${xwayland-anland}/bin/Xwayland

    [shell]
    locking=false
    panel-position=none

    [autolaunch]
    path=${terminal}
  '';
  environment = ''
    XDG_RUNTIME_DIR="/tmp/anland-runtime-$(id -u)"
    export XDG_RUNTIME_DIR
    export WAYLAND_DISPLAY=wayland-anland
    export QT_QPA_PLATFORM=wayland
    export GDK_BACKEND=wayland
    export LIBGL_ALWAYS_SOFTWARE=1
    export __EGL_VENDOR_LIBRARY_FILENAMES=${mesa}/share/glvnd/egl_vendor.d/50_mesa.json
    export LIBGL_DRIVERS_PATH=${mesa}/lib/dri
    export FONTCONFIG_FILE=${fonts}
    export XCURSOR_PATH=${vanilla-dmz}/share/icons
    export XCURSOR_THEME=Vanilla-DMZ
  '';
  session = writeShellApplication {
    name = "anland-session";
    runtimeInputs = [ anland weston-anland coreutils util-linux dbus ];
    text = environment + ''
      umask 077
      mkdir -p "$XDG_RUNTIME_DIR" /tmp/anland /tmp/.X11-unix "$HOME/.local/state/anland"
      chmod 700 "$XDG_RUNTIME_DIR"
      chmod 1777 /tmp/.X11-unix
      if [[ -z "''${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        exec dbus-run-session --config-file=${dbus}/share/dbus-1/session.conf -- "$0" "$@"
      fi
      exec 9>"$XDG_RUNTIME_DIR/session.lock"
      flock -n 9 || { echo "An Anland session is already running." >&2; exit 1; }

      daemon_pid=""
      weston_pid=""
      cleanup() {
        if [[ -n "$weston_pid" ]]; then kill "$weston_pid" 2>/dev/null || true; fi
        if [[ -n "$daemon_pid" ]]; then kill "$daemon_pid" 2>/dev/null || true; fi
        wait || true
      }
      trap cleanup EXIT
      trap 'exit 130' INT
      trap 'exit 143' TERM

      log_dir="$HOME/.local/state/anland"
      if [[ -f "$log_dir/weston.log" ]]; then
        mv -f "$log_dir/weston.log" "$log_dir/weston.previous.log"
      fi
      anland --socket /tmp/anland/display_daemon.sock >"$log_dir/daemon.log" 2>&1 9>&- &
      daemon_pid=$!
      for ((i=0; i<50; i++)); do
        kill -0 "$daemon_pid" || { cat "$log_dir/daemon.log" >&2; exit 1; }
        [[ -S /tmp/anland/display_daemon.sock ]] && break
        sleep 0.1
      done
      [[ -S /tmp/anland/display_daemon.sock ]] || { cat "$log_dir/daemon.log" >&2; exit 1; }
      echo "Open Anland Nix on Android. Launch GUI apps from the terminal it displays."
      echo "Logs: $log_dir. Press Ctrl-C here to stop the session."
      weston --backend=anland --renderer=gl \
        --disp-sock=/tmp/anland/display_daemon.sock \
        --socket="$WAYLAND_DISPLAY" --config=${config} \
        --log="$log_dir/weston.log" "$@" 9>&- &
      weston_pid=$!
      wait "$weston_pid"
    '';
  };
  run = writeShellApplication {
    name = "anland-run";
    runtimeInputs = [ coreutils ];
    text = environment + ''
      if [[ ! -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]]; then
        echo "Start anland-session first." >&2
        exit 1
      fi
      if [[ $# -eq 0 ]]; then
        echo "Usage: anland-run COMMAND [ARGUMENTS...]" >&2
        exit 2
      fi
      exec "$@"
    '';
  };
in symlinkJoin {
  name = "anland-session";
  paths = [ session run ];
  meta = {
    description = "Minimal Nix-on-Droid GUI session and Wayland application launcher";
    mainProgram = "anland-session";
    platforms = lib.platforms.linux;
  };
}
