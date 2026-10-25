{
  v3_10 = {
    version = "3.10.22";
    src-hash = "sha256-xh/psaGn7CoLA4jmZBh8N4pTJaieNgbSIKv1vfzLJUM=";
  };

  v3_11 = {
    version = "3.11.17";
    src-hash = "sha256-v7dK05764nzaUQ8TSrQI4A+ZksVoUc/Asc21ZG2hFZk=";
  };

  v3_12 = {
    version = "3.12.15";
    src-hash = "sha256-wsQyGWH6sPuZnWbgzs9SHCqzmUx5koc+qZ4wbBCU/Vo=";
  };

  v3_13 = {
    version = "3.13.17";
    src-hash = "sha256-YCC9EK/zv0ghvhbwiOuxWRvre4EdzY+rHaj3wip7J+c=";
  };

  v3_14 = {
    version = "3.14.9";
    src-hash = "sha256-4C2awhzr2m5GQ1NpdEqSxlzHzYZpaXaUEiz5f/rNHlM=";
  };

  v3_15 = {
    version = "3.15.1";
    src-hash = "sha256-ZzrnIy2EyJRymILIJX0wDvLSZSORG/05F+yM5/Um+Zs=";
  };

  v3_16 = {
    version = "3.16.0a1";
    suffix = "a1";
    src-hash = "sha256-3KqQKUNrcj4zQSxoyhfwEwvnMFjkejp8BJy4zfYDTuk=";
  };

  minimal = {
    withMinimalDeps = true;
    pythonAttr = "python3Minimal";
  };
}
