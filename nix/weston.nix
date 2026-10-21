{ lib, stdenv, fetchFromGitHub, meson, ninja, pkg-config, python3
, wayland-scanner, wayland, wayland-protocols, pixman, libxkbcommon
, libinput, libevdev, libdrm, libGL, libgbm, cairo, pango, libjpeg
, libwebp, lcms2, libxcb, libxcursor, xwayland, libudev-zero }:

stdenv.mkDerivation {
  pname = "weston-anland";
  version = "14.0.2-anland-5.13";
  src = fetchFromGitHub {
    owner = "lfdevs";
    repo = "weston";
    rev = "7db96561fb5fcbbe99132230bf73ed6988e92258";
    hash = "sha256-26TbdUusLhK9o/b8X4gLGst6p7SUFLSSj3YQDj+Hn3g=";
  };

  # Avoid GNU cp's unsupported directory-permission syscall under PRoot.
  unpackPhase = ''
    runHook preUnpack
    mkdir source
    tar -C "$src" -cf - . | tar -C source -xf -
    chmod -R u+w source
    sourceRoot=source
    runHook postUnpack
  '';

  # The stable upstream branch carries its Anland backend as a quilt series.
  postPatch = ''
    while IFS= read -r patch; do
      patch -p1 < "debian/patches/$patch"
    done < debian/patches/series
  '';
  nativeBuildInputs = [ meson ninja pkg-config python3 wayland-scanner ];
  buildInputs = [
    wayland wayland-protocols pixman libxkbcommon libinput libevdev libdrm
    libGL libgbm cairo pango libjpeg libwebp lcms2 libxcb libxcursor libudev-zero
  ];
  mesonFlags = [
    "-Dbackend-anland=true"
    "-Dbackend-default=auto"
    "-Dbackend-drm=false"
    "-Dbackend-headless=false"
    "-Dbackend-wayland=false"
    "-Dbackend-x11=false"
    "-Dbackend-rdp=false"
    "-Dbackend-vnc=false"
    "-Dbackend-pipewire=false"
    "-Dsystemd=false"
    "-Dremoting=false"
    "-Dpipewire=false"
    "-Danland-pipewire=disabled"
    "-Dshell-ivi=false"
    "-Dshell-fullscreen=false"
    "-Dsimple-clients=shm,egl"
    "-Ddemo-clients=false"
    "-Dtests=false"
    "-Dtest-junit-xml=false"
    "-Dxwayland=true"
    "-Dxwayland-path=${lib.getExe xwayland}"
  ];
  meta = {
    description = "Minimal Weston compositor with the Anland Android display backend";
    homepage = "https://github.com/lfdevs/weston";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "weston";
  };
}
