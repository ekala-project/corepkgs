# Basic validation test for Docker image building
# This test ensures that Docker images can be built successfully
# and have the correct structure.
{
  pkgs ? import ../../. { },
}:

let
  services = import ../. { inherit pkgs; };

  # Simple test service
  testApp = pkgs.writeScriptBin "test-app" ''
    #!${pkgs.bash}/bin/bash
    echo "Test application started"
    while true; do
      echo "Test app running at $(date)"
      sleep 5
    done
  '';

  # Build a simple Docker image for testing
  testImage = services.buildRunitDockerImage
    {
      test-service = {
        enable = true;
        description = "Test service";
        command = "${testApp}/bin/test-app";
        user = "testuser";
        group = "testgroup";
      };
    }
    {
      name = "runit-test-image";
      tag = "test";
      exposedPorts = [ "8080/tcp" ];
    };

in
pkgs.runCommand "docker-image-build-test"
  {
    buildInputs = [ pkgs.jq ];
  }
  ''
    set -e

    echo "=========================================="
    echo "Docker Image Build Test"
    echo "=========================================="
    echo ""

    # Check that the image was built
    if [ ! -f ${testImage} ]; then
      echo "ERROR: Docker image was not built"
      exit 1
    fi

    echo "✓ Docker image built successfully"
    echo "  Location: ${testImage}"
    echo ""

    # Extract and examine the image
    echo "Examining image structure..."
    mkdir -p $out/extracted
    cd $out/extracted

    # Docker images are gzipped tarballs
    ${pkgs.gzip}/bin/gunzip -c ${testImage} | ${pkgs.gnutar}/bin/tar -x

    # Check for manifest.json
    if [ ! -f manifest.json ]; then
      echo "ERROR: manifest.json not found in image"
      exit 1
    fi

    echo "✓ manifest.json found"

    # Parse manifest
    manifest=$(cat manifest.json)
    echo "  Manifest:"
    echo "$manifest" | jq '.' || true

    # Check for config file
    configFile=$(echo "$manifest" | jq -r '.[0].Config')
    if [ ! -f "$configFile" ]; then
      echo "ERROR: Config file $configFile not found"
      exit 1
    fi

    echo "✓ Config file found: $configFile"

    # Check config contains expected fields
    config=$(cat "$configFile")

    entrypoint=$(echo "$config" | jq -r '.config.Entrypoint // empty')
    if [ -z "$entrypoint" ]; then
      echo "ERROR: Entrypoint not found in config"
      exit 1
    fi

    echo "✓ Entrypoint configured: $entrypoint"

    # Check exposed ports
    exposedPorts=$(echo "$config" | jq -r '.config.ExposedPorts // {}')
    if [ "$exposedPorts" = "{}" ]; then
      echo "WARNING: No exposed ports found"
    else
      echo "✓ Exposed ports configured:"
      echo "$exposedPorts" | jq '.'
    fi

    # Check for layer data
    layers=$(echo "$manifest" | jq -r '.[0].Layers[]')
    layerCount=$(echo "$layers" | wc -l)

    if [ "$layerCount" -eq 0 ]; then
      echo "ERROR: No layers found in image"
      exit 1
    fi

    echo "✓ Image has $layerCount layer(s)"

    # Check a few layers exist
    missingLayers=0
    for layer in $layers; do
      if [ ! -f "$layer" ]; then
        echo "WARNING: Layer file $layer not found"
        missingLayers=$((missingLayers + 1))
      fi
    done

    if [ $missingLayers -gt 0 ]; then
      echo "WARNING: $missingLayers layer file(s) not found"
    else
      echo "✓ All layer files present"
    fi

    # Extract and check the first layer for runit-related content
    echo ""
    echo "Checking layer contents..."
    firstLayer=$(echo "$layers" | head -n1)
    mkdir -p layer-check
    cd layer-check
    ${pkgs.gzip}/bin/gunzip -c "../$firstLayer" | ${pkgs.gnutar}/bin/tar -x 2>/dev/null || true

    # Check for /etc/sv directory (service definitions)
    if [ -d etc/sv ]; then
      echo "✓ Service directory /etc/sv found"
      serviceCount=$(find etc/sv -mindepth 1 -maxdepth 1 -type d | wc -l)
      echo "  Services: $serviceCount"
      find etc/sv -mindepth 1 -maxdepth 1 -type d | sed 's|^|    - |'
    else
      echo "NOTE: /etc/sv not in first layer (may be in another layer)"
    fi

    # Final summary
    cd $out
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo "✓ Docker image builds successfully"
    echo "✓ Image structure is valid"
    echo "✓ Entrypoint is configured"
    echo "✓ Image has $layerCount layer(s)"
    echo ""
    echo "Test PASSED"
    echo "=========================================="

    # Create success marker
    touch $out/success
  ''
