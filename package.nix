{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  buildDotnetModule,
  dotnetCorePackages,
  sqlite,
  fetchYarnDeps,
  yarn,
  fixup-yarn-lock,
  prefetch-yarn-deps,
  nodejs,
}:
let
  version = "0-unstable-2026-02-04";
  src = fetchFromGitHub {
    owner = "pennydreadful";
    repo = "bookshelf";
    rev = "c21c4134fdb710481ed69db05bf943b0acdbbf60";
    hash = "sha256-dHQLZVFKvOz7BD6C7qxmlns0eDgLD/+K6CLMWF1f+cQ=";
  };
  rid = dotnetCorePackages.systemToDotnetRid stdenvNoCC.hostPlatform.system;
in
buildDotnetModule {
  pname = "bookshelf";
  inherit version src;

  strictDeps = true;
  nativeBuildInputs = [
    nodejs
    yarn
    prefetch-yarn-deps
    fixup-yarn-lock
  ];

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-lmtvDXf745fQN67MtZ5muIFyT3e41XYQELHHStgLauQ=";
  };

  patches = [ ./nuget-config.patch ];

  postConfigure = ''
    yarn config --offline set yarn-offline-mirror "$yarnOfflineCache"
    fixup-yarn-lock yarn.lock
    yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive
    patchShebangs --build node_modules
  '';

  postBuild = ''
    yarn --offline run build --env production
  '';

  postInstall = ''
    cp -a -- _output/UI "$out/lib/bookshelf/UI"
  '';

  nugetDeps = ./deps.json;

  runtimeDeps = [ sqlite ];

  dotnet-sdk = dotnetCorePackages.sdk_6_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_6_0;

  executables = [ "Readarr" ];

  projectFile = [
    "src/NzbDrone.Console/Readarr.Console.csproj"
    "src/NzbDrone.Mono/Readarr.Mono.csproj"
  ];

  dotnetFlags = [
    "--property:TargetFramework=net6.0"
    "--property:EnableAnalyzers=false"
    "--property:AssemblyVersion=10.0.0.0"
    "--property:AssemblyConfiguration=main"
    "--property:RuntimeIdentifier=${rid}"
  ];

  __structuredAttrs = true;

  meta = {
    description = "Book manager and automation (Readarr fork)";
    homepage = "https://github.com/pennydreadful/bookshelf";
    license = lib.licenses.gpl3Only;
    mainProgram = "Readarr";
  };
}
