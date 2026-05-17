{ pkgs }:

let
  inherit (pkgs)
    lib
    stdenv
    writeText
    writeScript
    runCommand
    ;

  # Helper to create a simple language test
  mkLanguageTest =
    {
      name,
      interpreter,
      code,
      expectedOutput ? "Hello, World!",
    }:
    runCommand "test-${name}"
      {
        nativeBuildInputs = [ interpreter ];
        passthru = {
          inherit interpreter;
        };
      }
      ''
        set -e
        output=$(${code})
        echo "Output: $output"
        if [ "$output" = "${expectedOutput}" ]; then
          echo "✓ ${name} test passed"
          touch $out
        else
          echo "✗ ${name} test failed: expected '${expectedOutput}', got '$output'"
          exit 1
        fi
      '';
in
rec {
  # Java tests
  java = mkLanguageTest {
    name = "java";
    interpreter = pkgs.java;
    code = ''
      cat > HelloWorld.java <<'EOF'
      public class HelloWorld {
          public static void main(String[] args) {
              System.out.print("Hello, World!");
          }
      }
      EOF
      javac HelloWorld.java
      java HelloWorld
    '';
  };

  # Node.js tests
  nodejs = mkLanguageTest {
    name = "nodejs";
    interpreter = pkgs.nodejs;
    code = ''node -e "process.stdout.write('Hello, World!')"'';
  };

  # PHP tests
  php = mkLanguageTest {
    name = "php";
    interpreter = pkgs.php;
    code = ''php -r "echo 'Hello, World!';"'';
  };

  # Julia test
  julia = mkLanguageTest {
    name = "julia";
    interpreter = pkgs.julia;
    code = ''julia -e 'print("Hello, World!")'  '';
  };

  # R test
  r = mkLanguageTest {
    name = "r";
    interpreter = pkgs.rLang;
    code = ''Rscript -e 'cat("Hello, World!")'  '';
  };

  # Zig test
  zig = mkLanguageTest {
    name = "zig";
    interpreter = pkgs.zig;
    code = ''
      cat > hello.zig <<'EOF'
      const std = @import("std");
      pub fn main() !void {
          const stdout = std.io.getStdOut().writer();
          try stdout.print("Hello, World!", .{});
      }
      EOF
      zig run hello.zig
    '';
  };

  # Nim test
  nim = mkLanguageTest {
    name = "nim";
    interpreter = pkgs.nim;
    code = ''
      cat > hello.nim <<'EOF'
      import std/io
      stdout.write("Hello, World!")
      EOF
      nim compile --run hello.nim
    '';
  };

  # Crystal test (might need adjustment based on binary availability)
  crystal = mkLanguageTest {
    name = "crystal";
    interpreter = pkgs.crystal;
    code = ''crystal eval 'print "Hello, World!"' '';
  };

  # Elixir test
  elixir = mkLanguageTest {
    name = "elixir";
    interpreter = pkgs.elixir;
    code = ''elixir -e 'IO.write("Hello, World!")'  '';
  };

  # Kotlin test
  kotlin = mkLanguageTest {
    name = "kotlin";
    interpreter = pkgs.kotlin;
    code = ''
      cat > hello.kt <<'EOF'
      fun main() {
          print("Hello, World!")
      }
      EOF
      kotlinc hello.kt -include-runtime -d hello.jar
      java -jar hello.jar
    '';
  };

  # Scala test
  scala = mkLanguageTest {
    name = "scala";
    interpreter = pkgs.scala;
    code = ''scala -e 'print("Hello, World!")'  '';
  };

  # Clojure test
  clojure = mkLanguageTest {
    name = "clojure";
    interpreter = pkgs.clojure;
    code = ''clojure -e '(print "Hello, World!")'  '';
  };

  # Meta-test that runs all language tests
  all =
    runCommand "test-all-languages"
      {
        tests = [
          java
          nodejs
          php
          julia
          r
          zig
          nim
          crystal
          elixir
          kotlin
          scala
          clojure
        ];
      }
      ''
        echo "Running all language tests..."
        for test in $tests; do
          if [ -f "$test" ]; then
            echo "✓ $(basename $test) passed"
          else
            echo "✗ $(basename $test) failed"
            exit 1
          fi
        done
        echo "All language tests passed!"
        touch $out
      '';
}
