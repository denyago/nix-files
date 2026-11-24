{
  lib,
  stdenv,
  sources, # nvfetcher output, see ../github-distributed
  nodejs_22,
  pnpm,
  pnpmConfigHook,
  fetchPnpmDeps,
  makeWrapper,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dbhub";
  version = lib.removePrefix "v" sources.dbhub.version;
  inherit (sources.dbhub) src;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) version src;
    # fetchPnpmDeps names its output "<pname>-pnpm-deps". Embedding the version
    # makes a source bump produce a fresh derivation, so nix reports the stale
    # hash below as a mismatch instead of silently reusing the old deps from the
    # store. `my-nix upgrade` then rewrites it (my-nix/scripts/build-fix-hashes.sh).
    pname = "${finalAttrs.pname}-${finalAttrs.version}";
    inherit pnpm;
    fetcherVersion = 3;
    # Not tracked by nvfetcher; refreshed automatically by `my-nix upgrade`.
    hash = "sha256-+nLWL7Ys1vyQ4VSxTRreG/UwFUcXvIO+G1dWs0I5xjU=";
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm
    pnpmConfigHook
    makeWrapper
  ];

  # Backend only: stdio transport doesn't need the web workbench frontend.
  buildPhase = ''
    runHook preBuild
    pnpm run build:backend
    runHook postBuild
  '';

  # Native addons (ssh2, oracledb, ...) are optional; skip strip/patchelf noise.
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    # Drop devDependencies (and the unbuilt frontend workspace) before copying.
    rm -rf node_modules frontend/node_modules
    CI=true pnpm install --offline --frozen-lockfile --prod --ignore-scripts --filter dbhub
    mkdir -p $out/lib/dbhub
    cp -r dist node_modules package.json $out/lib/dbhub/
    # workspace link to the (unbuilt) frontend dangles outside the build dir
    find $out/lib/dbhub/node_modules -xtype l -delete
    makeWrapper ${lib.getExe nodejs_22} $out/bin/dbhub --add-flags $out/lib/dbhub/dist/index.js
    runHook postInstall
  '';

  meta = {
    description = "Token-efficient database MCP server (Postgres, MySQL, ...)";
    homepage = "https://github.com/bytebase/dbhub";
    license = lib.licenses.mit;
    mainProgram = "dbhub";
  };
})
