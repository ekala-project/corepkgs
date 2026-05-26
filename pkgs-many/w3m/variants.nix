{
  full = {
    version = "0.5.5";
    src-hash = "sha256-rz9tNkMg5xUqMpMdK2AQlKjCJlCjgLQOkj4A/eyPm0M=";
  };

  nox = {
    version = "0.5.5";
    src-hash = "sha256-rz9tNkMg5xUqMpMdK2AQlKjCJlCjgLQOkj4A/eyPm0M=";
    x11Support = false;
    useImlib2Nox = true;
  };

  nographics = {
    version = "0.5.5";
    src-hash = "sha256-rz9tNkMg5xUqMpMdK2AQlKjCJlCjgLQOkj4A/eyPm0M=";
    x11Support = false;
    graphicsSupport = false;
  };

  batch = {
    version = "0.5.5";
    src-hash = "sha256-rz9tNkMg5xUqMpMdK2AQlKjCJlCjgLQOkj4A/eyPm0M=";
    graphicsSupport = false;
    mouseSupport = false;
    x11Support = false;
    useImlib2Nox = true;
  };
}
