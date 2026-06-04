let
  allKernels = builtins.fromJSON (
    builtins.readFile ../../pkgs/linux-support/kernel/kernels-org.json
  );
in
{
  v5_10 = {
    branch = "5.10";
    version = allKernels."5.10".version;
    isLTS = allKernels."5.10".lts;
  };
  v5_15 = {
    branch = "5.15";
    version = allKernels."5.15".version;
    isLTS = allKernels."5.15".lts;
  };
  v6_1 = {
    branch = "6.1";
    version = allKernels."6.1".version;
    isLTS = allKernels."6.1".lts;
  };
  v6_6 = {
    branch = "6.6";
    version = allKernels."6.6".version;
    isLTS = allKernels."6.6".lts;
  };
  v6_12 = {
    branch = "6.12";
    version = allKernels."6.12".version;
    isLTS = allKernels."6.12".lts;
  };
  v6_17 = {
    branch = "6.17";
    version = allKernels."6.17".version;
    isLTS = allKernels."6.17".lts;
  };
  v6_18 = {
    branch = "6.18";
    version = allKernels."6.18".version;
    isLTS = allKernels."6.18".lts;
  };
}
