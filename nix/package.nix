{ lib, stdenv, source ? ../termux/anland }:
stdenv.mkDerivation {
  pname = "anland";
  version = "5.13.4.1";
  src = lib.cleanSource source;

  # PRoot cannot emulate recent GNU cp's directory-permission syscall.
  # A tar round-trip also preserves the executable bits in the source.
  unpackPhase = ''
    runHook preUnpack
    mkdir source
    tar -C "$src" -cf - . | tar -C source -xf -
    chmod -R u+w source
    sourceRoot=source
    runHook postUnpack
  '';

  # Nix-on-Droid binds its Android-visible usr/tmp directory at /tmp.
  postPatch = ''
    substituteInPlace anland.c \
      --replace-fail /data/data/com.termux/files/usr/tmp /tmp
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 anland "$out/bin/anland"
    runHook postInstall
  '';

  meta = {
    description = "Anland display relay for Nix-on-Droid";
    homepage = "https://github.com/jkub6/anland-termux";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "anland";
  };
}
