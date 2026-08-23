{
  withoutXorg = {
    version = "12.2.1";
    src-hash = "sha256-Uxqg/7+LpSGX4lGH12uRBxukVw0IswFPfpb2EkLsaiI=";
    withXorg = false;
  };

  withXorg = {
    version = "12.2.1";
    src-hash = "sha256-Uxqg/7+LpSGX4lGH12uRBxukVw0IswFPfpb2EkLsaiI=";
    withXorg = true;
  };
}
