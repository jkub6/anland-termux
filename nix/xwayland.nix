{ xwayland }:

# PRoot may return ENOSYS for setuid/setgid even when no identity change is
# requested. Preserve privilege dropping when any real/effective/saved ID differs.
xwayland.overrideAttrs (old: {
  pname = "xwayland-anland";
  patches = (old.patches or []) ++ [ ./xwayland-proot-identity.patch ];
})
