{
  ffmpeg,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
}:

buildDotnetModule rec {
  pname = "WeddingShare";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "Cirx08";
    repo = pname;
    rev = version;
    sha256 = "sha256-8hzlzBQ5iOGC/L6Jg/3HQrFDYB4ZKyn4d5Orsx0hcrg=";
  };

  runtimeDeps = [ ffmpeg ];
  selfContainedBuild = true;

  postInstall = ''
    ln -s /var/lib/WeddingShare/thumbnails $out/lib/WeddingShare/wwwroot/thumbnails 
    ln -s /var/lib/WeddingShare/uploads $out/lib/WeddingShare/wwwroot/uploads
    ln -s /var/lib/WeddingShare/custom_resources $out/lib/WeddingShare/wwwroot/custom_resources
  '';

  projectFile = "WeddingShare/WeddingShare.csproj";
  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.runtime_8_0;
  nugetDeps = ./deps.json;
}
