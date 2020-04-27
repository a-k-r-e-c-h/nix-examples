{
  # dependencies
  stdenv, fetchurl, nix-gitignore, jdk11, adoptopenjdk-jre-hotspot-bin-11, maven, makeWrapper,

  # args
  localFiles ? false
}:

let
  pname = "spring-boot";
  version = "1.0";
  url = "https://example.com";
  sha256 = stdenv.lib.fakeSha256;

  mavenJdk11 = maven.overrideAttrs (oldAttrs: {
    jdk = jdk11;
  });

  deps = stdenv.mkDerivation rec {
    name = "${pname}-${version}-deps";

    buildInputs = [ mavenJdk11 ];

    src = (
      if localFiles then
        builtins.filterSource (path: type: baseNameOf path == "pom.xml") ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    installPhase =
      ''
        mvn dependency:go-offline -Dmaven.repo.local="$out"
        # download surefire-junit-platform which is not explicitly defined as dependency
        mvn dependency:get -Dmaven.repo.local="$out" -Dartifact=org.apache.maven.surefire:surefire-junit-platform:2.22.2
      '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    #outputHash = stdenv.lib.fakeSha256;
    outputHash = "0wa2kxjgszskxhwk02i0azd810bi6limdmh50ima8b5z5cfm9zp7";
  };
in
  stdenv.mkDerivation rec {
    inherit pname version;

    nativeBuildInputs = [ jdk11 makeWrapper mavenJdk11 deps ];
    buildInputs = [ adoptopenjdk-jre-hotspot-bin-11 ];

    src = (
      if localFiles then
        nix-gitignore.gitignoreSource [ "result" ] ./.
      else
        fetchurl {
          inherit url sha256;
        }
    );

    # TODO update example to spring boot 2.2.3 or 2.2:4 or 2.2.5 where maven-jar-plugin is updated to 3.2.0 and check that jar contains files with right timestamps
    buildPhase =
      ''
        # property project.build.outputTimestamp is supported in maven-jar-plugin as of 3.2.0,
        # in older versions produced JAR contains timestamps and therefore is not reproducible
        # morover we must update timestamp of pom.xml, because jre cannot load jar files where the modified day or month is 0
        touch pom.xml
        mvn package -Dmaven.repo.local="${deps}" -Dproject.build.outputTimestamp=1970-01-01T00:00:00Z
      '';

    installPhase =
      ''
        mkdir -p $out/share/java
        cp target/demo-0.0.1-SNAPSHOT.jar $out/share/java/demo-0.0.1-SNAPSHOT.jar
        mkdir -p $out/bin
        makeWrapper ${adoptopenjdk-jre-hotspot-bin-11}/bin/java $out/bin/${pname} --add-flags "-jar $out/share/java/demo-0.0.1-SNAPSHOT.jar"
      '';

    passthru = {
      inherit deps;
      executable = pname;
    };

    meta = with stdenv.lib; {
      description = "Java Maven example";
      longDescription = ''
        The spring-boot program which demonstrate building Java project with Maven
      '';
      homepage = https://example.com/;
      license = licenses.gpl3Plus;
      maintainers = [];
      platforms = platforms.all;
    };
  }

