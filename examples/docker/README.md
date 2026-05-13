# Docker Examples with Runit Supervision

This directory contains examples of building Docker images with runit supervision for multi-process containers. These examples demonstrate various sidecar patterns and show how to run multiple services in a single container using runit as PID 1.

## Overview

All examples use the `buildRunitDockerImage` function from the services library to create Docker images where:

- **Runit acts as PID 1**: Provides proper signal handling and zombie reaping
- **Each service runs independently**: Supervised by runit, automatically restarted if it crashes
- **Clean shutdown**: Services receive SIGTERM and have time to clean up gracefully
- **Sidecar pattern support**: Perfect for running application + observability/logging/proxy sidecars

## Examples

### 1. Nginx with Prometheus Exporter (`nginx-with-exporter.nix`)

**Pattern**: Observability Sidecar

Demonstrates running an nginx web server alongside a Prometheus metrics exporter.

```bash
# Build the image
nix-build nginx-with-exporter.nix

# Load into Docker
docker load < result

# Run the container
docker run -d -p 8080:8080 -p 9113:9113 --name nginx-demo nginx-with-exporter:latest

# Test nginx
curl http://localhost:8080
curl http://localhost:8080/health

# Check Prometheus metrics
curl http://localhost:9113/metrics

# View logs
docker logs nginx-demo

# Check service status
docker exec nginx-demo sv status /service/*

# Stop container (graceful shutdown)
docker stop nginx-demo
```

**Services**:
- `nginx`: Web server on port 8080
- `nginx-exporter`: Prometheus exporter on port 9113

### 2. App with Log Shipping (`app-with-logging.nix`)

**Pattern**: Log Aggregation Sidecar

Demonstrates a Python application with a log shipping sidecar that collects and processes logs.

```bash
# Build the image
nix-build app-with-logging.nix

# Load into Docker
docker load < result

# Run the container
docker run -d -p 8080:8080 --name app-demo app-with-log-shipping:latest

# Test the application
curl http://localhost:8080
curl http://localhost:8080/health
curl http://localhost:8080/error  # Trigger error log

# View real-time logs (from Docker)
docker logs -f app-demo

# Check shipped logs (inside container)
docker exec app-demo cat /var/log/shipped/application-shipped.log

# Check service status
docker exec app-demo sv status /service/*
```

**Services**:
- `app`: Python web application writing structured JSON logs
- `log-shipper`: Sidecar that tails logs, enriches them, and ships to destination

### 3. Multi-Service Template (`multi-service.nix`)

**Pattern**: Generic Multi-Service

A template showing how to run multiple arbitrary services together.

```bash
# Build the image
nix-build multi-service.nix

# Load into Docker
docker load < result

# Run the container
docker run -d -p 8080:8080 --name multi-demo multi-service-example:latest

# Test HTTP server
curl http://localhost:8080

# View all service logs
docker logs multi-demo

# Check individual service status
docker exec multi-demo sv status /service/http-server
docker exec multi-demo sv status /service/worker
docker exec multi-demo sv status /service/health-check

# Restart a specific service
docker exec multi-demo sv restart /service/worker

# Stop a service (won't restart)
docker exec multi-demo sv stop /service/health-check

# Start it again
docker exec multi-demo sv start /service/health-check
```

**Services**:
- `http-server`: Simple HTTP server on port 8080
- `worker`: Background worker process
- `health-check`: Monitoring service that checks other services

## Building Your Own

### Basic Structure

```nix
{ pkgs ? import ../../. { } }:

let
  services = import ../../services { inherit pkgs; };
in

services.buildRunitDockerImage
  {
    # Service definitions
    my-service = {
      enable = true;
      description = "My service";
      command = "${pkgs.myapp}/bin/myapp";
      args = [ "--port" "8080" ];
      user = "myuser";
      group = "mygroup";
      environment = {
        MY_VAR = "value";
      };
      preStart = ''
        # Setup commands
      '';
    };

    my-sidecar = {
      enable = true;
      description = "My sidecar";
      command = "${pkgs.sidecar}/bin/sidecar";
      user = "sidecar";
    };
  }
  {
    # Docker image configuration
    name = "my-image";
    tag = "latest";
    extraContents = [ pkgs.curl ];
    exposedPorts = [ "8080/tcp" ];
    imageConfig = {
      Labels = {
        "description" = "My multi-service container";
      };
    };
  }
```

### Service Options

Each service supports all the common options from the services library:

- `enable`: Whether to enable the service
- `description`: Human-readable description
- `command`: Path to the executable
- `args`: Command-line arguments
- `user`, `group`: User/group to run as (created automatically)
- `environment`: Environment variables
- `path`: Packages to add to PATH
- `workingDirectory`: Working directory
- `preStart`: Shell commands to run before starting service
- `postStop`: Cleanup commands after service stops

Plus runit-specific options:

- `runit.logScript`: Custom logging script (default: logs to stdout)
- `runit.extraRunScript`: Additional shell code in run script
- `runit.extraFinishScript`: Additional cleanup code
- `runit.extraConfig.checkScript`: Health check script

### Docker Image Options

- `name`: Image name (required)
- `tag`: Image tag (default: "latest")
- `extraContents`: Additional packages to include
- `exposedPorts`: List of ports to expose (e.g., `["8080/tcp" "9090/tcp"]`)
- `imageConfig`: Additional Docker config (Labels, Env, etc.)
- `preStartCommands`: Shell commands to run before starting runit

## Managing Services at Runtime

### View Service Status

```bash
docker exec <container> sv status /service/*
```

Shows the status of all services (running, uptime, PID).

### Control Individual Services

```bash
# Start a service
docker exec <container> sv start /service/my-service

# Stop a service (won't auto-restart)
docker exec <container> sv stop /service/my-service

# Restart a service
docker exec <container> sv restart /service/my-service

# Send signal to a service
docker exec <container> sv kill /service/my-service

# Wait for service to be up
docker exec <container> sv check /service/my-service
```

### Viewing Logs

If services log to stdout/stderr:

```bash
docker logs <container>
docker logs -f <container>  # Follow
```

If using runit's svlogd:

```bash
docker exec <container> cat /var/log/my-service/current
docker exec <container> tail -f /var/log/my-service/current
```

## Best Practices

### 1. Service Dependencies

Use `preStart` to wait for dependencies:

```nix
sidecar = {
  preStart = ''
    for i in {1..30}; do
      if curl -sf http://localhost:8080/health; then
        break
      fi
      sleep 1
    done
  '';
};
```

### 2. Health Checks

Add Docker health checks in `imageConfig`:

```nix
imageConfig = {
  Healthcheck = {
    Test = [ "CMD-SHELL" "curl -f http://localhost:8080/health" ];
    Interval = 30000000000;  # 30s in nanoseconds
    Timeout = 10000000000;   # 10s
    Retries = 3;
  };
};
```

### 3. Logging Strategy

**Option A**: Log to stdout (Docker-native)
```nix
my-service = {
  # Just let the service log to stdout/stderr
  # No runit.logScript needed
};
```

**Option B**: Use svlogd for rotation
```nix
my-service = {
  runit.logScript = ''
    #!/bin/sh
    exec svlogd -tt /var/log/my-service
  '';
};
```

### 4. Graceful Shutdown

Ensure services handle SIGTERM:

```nix
my-service = {
  runit.timeoutFinish = 30;  # Seconds to wait before SIGKILL

  postStop = ''
    # Cleanup code
  '';
};
```

### 5. Security

Always run services as non-root users:

```nix
my-service = {
  user = "appuser";
  group = "appgroup";
  # Users are created automatically
};
```

## Common Sidecar Patterns

### Observability Sidecar
- Application + Prometheus exporter
- Application + StatsD agent
- Application + OpenTelemetry collector

### Log Aggregation
- Application + Fluent Bit
- Application + Fluentd
- Application + Vector

### Service Mesh
- Application + Envoy proxy
- Application + Linkerd proxy

### Database + Backup
- Database + WAL archiver
- Database + backup agent

### Cache Warmer
- Application + cache warming service

## Troubleshooting

### Container Exits Immediately

Check if services are crashing:
```bash
docker logs <container>
```

Check runit logs:
```bash
docker run --rm -it <image> /bin/sh
# Inside container:
/nix/store/.../bin/runsvdir /service
```

### Service Won't Start

Check service-specific logs and permissions:
```bash
docker exec <container> sv status /service/my-service
docker exec <container> cat /var/log/my-service/current
```

### Permission Denied

Ensure directories are writable and owned by the service user:
```nix
imageConfig = {
  extraFakeRootCommands = ''
    mkdir -p var/myapp
    chown 1000:1000 var/myapp
  '';
};
```

## Additional Resources

- [Runit documentation](http://smarden.org/runit/)
- [Service library documentation](../../services/README.md)
- [Docker best practices](https://docs.docker.com/develop/dev-best-practices/)

## Contributing

When adding new examples:

1. Follow the existing naming convention
2. Include comprehensive comments
3. Document the sidecar pattern being demonstrated
4. Add usage examples to this README
5. Test building and running the image
