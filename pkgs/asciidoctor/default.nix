{
  lib,
  bundlerApp,
  bundlerUpdateScript,
  asciidoctor,
  runCommand,
  testers,
}:

bundlerApp {
  pname = "asciidoctor";
  gemdir = ./.;

  exes = [
    "asciidoctor"
    "asciidoctor-pdf"
  ];

  passthru = {
    updateScript = bundlerUpdateScript "asciidoctor";
    tests = {
      version = testers.testVersion {
        package = asciidoctor;
        command = "asciidoctor --version";
      };
      simple = runCommand "asciidoctor-test" { } ''
        echo "= Test" > input.adoc
        ${asciidoctor}/bin/asciidoctor -o output.html input.adoc
        grep -q "<h1>Test</h1>" output.html
        touch $out
      '';
    };
  };

  meta = {
    description = "Faster Asciidoc processor written in Ruby";
    homepage = "https://asciidoctor.org/";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
