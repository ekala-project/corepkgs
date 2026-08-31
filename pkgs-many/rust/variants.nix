{
  v1_91 = {
    version = "1.91.1";
    rustcVersion = "1.91.1";
    rustcSha256 = "sha256-ONziBdOfYVcSYfBEQjehzp7+y5cOdg2OxNlXr1tEVyM=";
    selectRustPackage = pkgs: pkgs.rust.v1_91;
    bootstrapVersion = "1.91.1";
    bootstrapHashes = {
      i686-unknown-linux-gnu = "b596ac56c67cf893e58ecf3263e59ac10157e9f50047e8d3d84faf288273ea47";
      x86_64-unknown-linux-gnu = "1c955c040dd087e4751d15588ddec288b4208bea16f8ec5046c164877e55fff7";
      x86_64-unknown-linux-musl = "e690ea46a73b11268c0487a4bca440142d69de7c0ca062fcdf2b99ad0e42e8e5";
      arm-unknown-linux-gnueabihf = "4899619845a875b2e51825943fad66cf42dced0e1f66470222ff0653776bd59e";
      armv7-unknown-linux-gnueabihf = "c51a61f304c0019c57169b964ec26f7a7ff7dcefaf42b973237f96fb457b25c8";
      aarch64-unknown-linux-gnu = "50213385f288b8760b2efd54ac066ef9a76475e778cbe3b0fcbd3f898fc00674";
      aarch64-unknown-linux-musl = "d374258cd00b4069e44266ab58b321208187511606236ebcc791a5a2d86554e1";
      x86_64-apple-darwin = "05adbd08e6535ed22a9c3d8f11d90df51eb6393488cbbb0c81f2b18d56e4d1ee";
      aarch64-apple-darwin = "f6727c9ab64a5b2a15623f29a023faf0c6a6aeb1347d102b88d595e5c1d9beae";
      powerpc64-unknown-linux-gnu = "94d86d13af288c4a06c8ea8b563e3889d55cc6064a06defd3b612eeeda902b93";
      powerpc64le-unknown-linux-gnu = "355f8043cd506fa718892eeedeebc9d6cc3de1a7757fdb8385c7bdc4cbc853ac";
      powerpc64le-unknown-linux-musl = "c17d51f54c00a371fbab80519b454a901a4b36b9f5a3a692e8816480d8f87067";
      riscv64gc-unknown-linux-gnu = "08230d9c59105270b2e06c5e87078a2a478efcacef8a88aedcccca9f317fa492";
      s390x-unknown-linux-gnu = "fb87330d72636d30f0a9b4b640f994186fc3ad0c0f3c89b2e0f7f31cfd7885f6";
      loongarch64-unknown-linux-gnu = "be6f676ae2ad80d4242798429915f708e3ecae7c895936c5fee172a4f7f2eec8";
      loongarch64-unknown-linux-musl = "7b071bc98d1e42dd802cc5b5bb83a9467d02ad6621231363519c869d322dcd5f";
      x86_64-unknown-freebsd = "9e231fa573b6bb99654a689687aede2014d4c21ac3c8422534c990c859632f50";
    };
  };

  v1_92 = {
    version = "1.92.0";
    rustcVersion = "1.92.0";
    rustcSha256 = "sha256-ng0sp1x+J1/cdYJVv0sDr7PWXRVDYCdGkHyTO2kBw7g=";
    rustcPatches = [ ./patches/core-os-allow-missing-docs.patch ];
    selectRustPackage = pkgs: pkgs.rust.v1_92;
    bootstrapVersion = "1.92.0";
    bootstrapHashes = {
      i686-unknown-linux-gnu = "0028378e76fc10255677a5398886664f619c15757f3e830d7464f3c716bc3f7e";
      x86_64-unknown-linux-gnu = "6e5efd6c25953b2732d4e6b1842512536650c68cf72a8b99a0fc566012dd6ca5";
      x86_64-unknown-linux-musl = "1a257be51efac7bea14d5566e521777b85c473ee42524a38abb181c6443c38e4";
      arm-unknown-linux-gnueabihf = "e8d400cc169f858915f8c5bd23070d5b7f63ca8b1d14a5ef53423d952e33a794";
      armv7-unknown-linux-gnueabihf = "1c0f84532a91f3ce7223613565f15f8992a8e09859d699c163a7782d15d6beef";
      aarch64-unknown-linux-gnu = "c812028423c3d7dd7ba99f66101e9e1aa3f66eab44a1285f41c363825d49dca4";
      aarch64-unknown-linux-musl = "ad412daf7b31aadbeb12f836ed14983f5d1d0717bd444e305f94ee68ea822fcd";
      x86_64-apple-darwin = "fc6868991e61e9262272effbb8956b23428430f5f4300c1b48eaae3969f8af2a";
      aarch64-apple-darwin = "235a6cca2dd4881130a9ae61ad1149bbf28bba184dd4621700f0c98c97457716";
      powerpc64-unknown-linux-gnu = "189dd8a254202d32066f123b42497b88f809a11680842e67c68e48a4200b6caf";
      powerpc64le-unknown-linux-gnu = "e2fe00a3c91f21c52947ebf96b4da016c9def5ccfedd1c335f30746db58bbf35";
      powerpc64le-unknown-linux-musl = "4655468ef2ccc3d6eaf55015054970ab4a8fb79d853add830c9e4016551b7101";
      riscv64gc-unknown-linux-gnu = "c2d1b80d3c69edcca5c0d2b2042fad43fdb06fa614a8cd09063c1c259dca8a7e";
      s390x-unknown-linux-gnu = "1ca05b6bd892c358ae0a12acbb605560529d80633abebb43ec004142205d7bd2";
      loongarch64-unknown-linux-gnu = "2f9a85ff1816d6e28a96c1f5b9c9c5d9fe710a20a36f172c41bc289cc780956e";
      loongarch64-unknown-linux-musl = "4fe07780b1ac08baee71de2ddbd275ba14cc082df54ea5a95055514130152546";
      x86_64-unknown-freebsd = "f32b7d8d5ad5c186fa496dd0b7202899f89e93870940e41c37e576f324494189";
    };
  };

  v1_93 = {
    version = "1.93.1";
    rustcVersion = "1.93.1";
    rustcSha256 = "sha256-TCMKRLPZyfPO+VCUNxn4OABY0nyR/aXjapqUfvAT4B8=";
    rustcPatches = [ ./patches/core-os-allow-missing-docs.patch ];
    selectRustPackage = pkgs: pkgs.rust.v1_93;
    bootstrapVersion = "1.93.1";
    bootstrapHashes = {
      i686-unknown-linux-gnu = "ef2a03ba7b314c32c464f7d1f51053808b270fa46e0334c3962751e63c5a607a";
      x86_64-unknown-linux-gnu = "fa99eb4e823fdeb8ee25e486c7973b4803013ac68c64e8f74880da788db9739c";
      x86_64-unknown-linux-musl = "5a6c766ce05ad7229aadbb365bad2c9c809c9e378706f123c156821fe6ab2711";
      arm-unknown-linux-gnueabihf = "a33bb432cf0ff752a628be3d73670ae053be8675f39414af1f17ada62257449a";
      armv7-unknown-linux-gnueabihf = "0177f471c457b0a29ff81bf99d1078b676d652e6a7ebb31dfbeceb63a274e38c";
      aarch64-unknown-linux-gnu = "bbe822f0aae2c1d31fa950a78446d4749e07ed67e974f87bf0c69146df2a9d9c";
      aarch64-unknown-linux-musl = "859d2e973ba1b0106aaeb5df7db72673cb82b9de417339e28ae9b5074756db5b";
      x86_64-apple-darwin = "5d4bd3705d6cb005449a22aa74ac073886a0e6a6026d2fc24d53b0acaca60255";
      aarch64-apple-darwin = "6bafa3b5367019c576751741295e06717f8f28c9d0e6631dcb9496cd142a386a";
      powerpc64-unknown-linux-gnu = "1b7869988be45153d86703c9ef4c970053b251745ac1571831dcd5f52d512cbf";
      powerpc64le-unknown-linux-gnu = "59dfda4a3ba76113406ce80c802161ec669da49d5b7c0214abc5b99bff633e39";
      powerpc64le-unknown-linux-musl = "2164eec8312e07d5e696cd46c10b5e3bcee06418d9aec47135d81bda2fa0198d";
      riscv64gc-unknown-linux-gnu = "4c2e2697c4911d32bf16dc7361f4205a08aeb557a3843403de1c554cd09ae601";
      s390x-unknown-linux-gnu = "1fafb56fb2d006561d8683c3943d355090bd4350b6692c7643d6f69fee301fd0";
      loongarch64-unknown-linux-gnu = "b0ceb4393dddd0eb3567c4fc7aa4d8b46c21bdb7558289223ffd7336cbaac130";
      loongarch64-unknown-linux-musl = "234fc65d9ae378ce2f55d273cc71841d09d38d6a4c41d873468ed017230d17df";
      x86_64-unknown-freebsd = "61c78738716543c1e217c813bab3ac58d0524afbaeb5fbd40dfdcd3f2c3992a2";
    };
  };

  v1_94 = {
    version = "1.94.1";
    rustcVersion = "1.94.1";
    rustcSha256 = "sha256-TBQqYl8S4833FsaK4Z9PYNmK0UgmJ7CFebFYOOla1RQ=";
    rustcPatches = [ ./patches/core-os-allow-missing-docs.patch ];
    selectRustPackage = pkgs: pkgs.rust.v1_94;
    bootstrapVersion = "1.94.1";
    bootstrapHashes = {
      i686-unknown-linux-gnu = "b458db6cf8366fa9f830bf05b15e3866fbb2b7e0a1921b91fd52aff9accfb405";
      x86_64-unknown-linux-gnu = "ea7866c5cab0d8c99e7416bcc5f9ecf0e122d396b85c7e7dee5669f10ee80194";
      x86_64-unknown-linux-musl = "5568d1b7992dcb0cabc9936476a0569ff314a3f1322886b4f414eb2d07b0ffd6";
      arm-unknown-linux-gnueabihf = "0b5d43c00ef1a72352f7b08937018ab52f624047f1403e0d2c4d7c67456eff16";
      armv7-unknown-linux-gnueabihf = "31b7deb5f38a504e21865a8bd98ff546884e66910ee11ed55e51a976ac7a645a";
      aarch64-unknown-linux-gnu = "99dba6decb780158b2b94f0054ec15c8cd4a04a497c84349fb86fb7a70722c78";
      aarch64-unknown-linux-musl = "caa1d50676518532cc9b4c4c491f219edbdcb9ebf9e6624432b5b43b87d8cc0a";
      x86_64-apple-darwin = "6d9c5a4bf9962987d616417e2669a50b52cc7ecbfa682d56e9ce8244a57d7b60";
      aarch64-apple-darwin = "630349bd157632ff65aafd1b5753e6a09153278cdac8196e8678b40b30cf1ecb";
      powerpc64-unknown-linux-gnu = "ef5ece383b3b0c2e3b020b95420020b247d73e6885cc9d8b328456b84cfcb6e6";
      powerpc64le-unknown-linux-gnu = "e4375d9081ce229786849ac4cd1be56e3a4ff117371d557ebcdb832c5ec20a4e";
      powerpc64le-unknown-linux-musl = "80fc13d8a78427a7065208a8aac17f542a173efd73c217be11b75de83c2f661f";
      riscv64gc-unknown-linux-gnu = "58038bca429819cc4cd52b9c364983c2e8a4c1dade8beaa0e4edd767e952ebf8";
      s390x-unknown-linux-gnu = "9b1043df30e406bf87cd73be5e5472f0353313ea081bd2ab1feb3b3d45f03e76";
      loongarch64-unknown-linux-gnu = "462881b156c5bd838943c6074649ad296dc87162753010fd328c2b698655b6ec";
      loongarch64-unknown-linux-musl = "5100cd191031a9549b2689b774306e5f37902dcc259a99b9e2de502720c52c0c";
      x86_64-unknown-freebsd = "68b687b408a4b443faeb2c81e2cb1c51f8f738da30ce04b0584db81068d77229";
    };
  };

  v1_95 = {
    version = "1.95.0";
    rustcVersion = "1.95.0";
    rustcSha256 = "sha256-6puCqD5GlnU3w1ac6db6FoEcBDqW5lE3bDSecCQcpRU=";
    selectRustPackage = pkgs: pkgs.rust.v1_95;
    bootstrapVersion = "1.95.0";
    bootstrapHashes = {
      i686-unknown-linux-gnu = "3ef2320bdfa9b69b19c6ca42f950b6bfb9d2af3b925b0c43a6bfecc4d355a66e";
      x86_64-unknown-linux-gnu = "a47ac940abd12399d59ad15c877e7113fa35f2b9ec7e6a8a045d4fd8b9741dea";
      x86_64-unknown-linux-musl = "059086762ac6f4ebe15b5b10e629e4e33e96b372765e65741251f75c4fdfb4e0";
      arm-unknown-linux-gnueabihf = "7d742098e8bb0d10415775634eed83240ae88c1bae6bc73b470ccf0be4629b4c";
      armv7-unknown-linux-gnueabihf = "23a201e72c082c285e957a32b40e1c30805b15d344b84b984be3659e9aefadf6";
      aarch64-unknown-linux-gnu = "3b9385d3144ac57616befa0ccbac524f857ba1b4ab074226e73a24d43568a98e";
      aarch64-unknown-linux-musl = "ad35bcc6928ccb4fd8a12fe19ce88c8fb6e6e3690578a0cb4e0839008017484f";
      x86_64-apple-darwin = "3f3d9f29f8eb7aa821bd8531cb9b1c3c74c3976aa558dfabfcc15c2febb3cfb8";
      aarch64-apple-darwin = "ec23ad2e0e15a7397d2c3c232356149cc871b7df7f47e25c2acb1070157f5398";
      powerpc64-unknown-linux-gnu = "6d89e3739cfb7b3a05880734513361d5860492385217dcd166d033f3e974e823";
      powerpc64le-unknown-linux-gnu = "29e3430f38406c926ee24ff911357dba0c46ff1d3ea59e91625b03677bd51b30";
      powerpc64le-unknown-linux-musl = "b8856b651d64f4f4a2e2ee009366d99ea6135bdf88d15cf2134fc9e166745030";
      riscv64gc-unknown-linux-gnu = "8b527cb1a09f53f83aa3420b4e763c9ea64a54d89e6d7242da35c8aeaa325593";
      s390x-unknown-linux-gnu = "e9598bdd3bc1438d965208ef5186f0dd671826cddd4bcbb20e22a3cec14c111d";
      loongarch64-unknown-linux-gnu = "18038ce7a910930c6742cc76e06fdd4b21b879466a3e67d63a0b6cae955bb4dc";
      loongarch64-unknown-linux-musl = "eef910858c7e833b13c9cb32e79e59d89434999bc2a7d0b6447ab4046eb40461";
      x86_64-unknown-freebsd = "0ffb7aa1999ea12363bbfaea500e152565bb4918ad5a73e9713be40510d75e49";
    };
  };

  v1_96 = {
    version = "1.96.1";
    rustcVersion = "1.96.1";
    rustcSha256 = "sha256-0Km1GYxBhoU4rhKvKAZBY1UdBtzOqxHvCxvJqm6Yt6c=";
    selectRustPackage = pkgs: pkgs.rust.v1_96;
    bootstrapVersion = "1.96.1";
    bootstrapHashes = {
      i686-unknown-linux-gnu = "9a3ef03fa419d662fbaf9b152a81db96379781771e6853ca06e31215fb177449";
      x86_64-unknown-linux-gnu = "b177534946e6e5422d8a75398b39625c08eabad675c08bd3d6565d3ba90c8450";
      x86_64-unknown-linux-musl = "12404d68457d3344877fbba3fde2c68743cd200fc70475451568e18076cc2a3d";
      arm-unknown-linux-gnueabihf = "c0c4b52bf5614dfcf6b9e94876f97509c71831fc09b8f0f0e228e13ce896ea92";
      armv7-unknown-linux-gnueabihf = "59320d46850c750b0a0d3e49939c00c3eed9917fab9a633300fb4d04bd8cfebc";
      aarch64-unknown-linux-gnu = "212cebf45b0669b2176eb08ffa17c90b07f9de2689d6aae3604d78699fa4f5c2";
      aarch64-unknown-linux-musl = "9e936f24cfd76db8a45ab352919336978531c0fb4eab7a7bdecc76b9562fcbdb";
      x86_64-apple-darwin = "c19cc27b3387e2dfe7eb4b5becc75ab5acf348b2a7f2142ad3716d93a0abaa2a";
      aarch64-apple-darwin = "c080e506af9cba3ca9472c17d989c2d8d5bcfc818eb5e196c77beee982788b50";
      powerpc64-unknown-linux-gnu = "7133e2e1ccf0eb66c4feeca8a2bbf21ad3223904a3459b3f228ff7c8dfc76871";
      powerpc64le-unknown-linux-gnu = "4cde26acb968f98fdb2f7f52e7f78b75a24afdea38abed7217e1cd02c6acbe06";
      powerpc64le-unknown-linux-musl = "d20d271134a11b3ba74c1c54fb926ea09f1c629321dcf53fb5d510f1ac1125a6";
      riscv64gc-unknown-linux-gnu = "b4c54315491239d2a4816535cea22a57ad1021e2529812ccfc938e64c53da276";
      s390x-unknown-linux-gnu = "17cb4a74048429dc03be326f976b35500c96290af248ed212071bafb4e366762";
      loongarch64-unknown-linux-gnu = "7f646ab7f798e7258db25286cbaed4fb54cae90afe44efebc7ff6c6120e4d3d9";
      loongarch64-unknown-linux-musl = "fd8e5e02e5c4bf879a54a31ebc4c24bbd2feb353a54b4e690e1cd04a97c60354";
      x86_64-unknown-freebsd = "8f5f247b7195a8925c092949c4eea96a6228d67e643dc10d97b1ed7c17e4c433";
    };
  };

  v1_97 = {
    version = "1.97.1";
    rustcVersion = "1.97.1";
    rustcSha256 = "sha256-YiwrQpxTy/3A3TpR0DVU6RzWPr7BkSwfVwlkDN/vGp0=";
    selectRustPackage = pkgs: pkgs.rust.v1_97;
    bootstrapVersion = "1.97.1";
    bootstrapHashes = {
      i686-unknown-linux-gnu = "914c2702deada0b9cf1d64bb3495d76e55cb3eba07d508472dde8b55a93e3759";
      x86_64-unknown-linux-gnu = "b4cdbc7cc6b0ee0a2666b1872769fdb2ad8393b28b63952f6493b4b400e4832b";
      x86_64-unknown-linux-musl = "40dbea28193cf2b488cf3e4a89274ccfb60efa50883f19917a382f84fd05bdc4";
      arm-unknown-linux-gnueabihf = "ba62fe07ad85b507907705a14adc1e8bc258de5f6177ba41d77bbff9f469a4ce";
      armv7-unknown-linux-gnueabihf = "e89c5e33aaddc6ef56857000c9117875c2997e9a1a500bd7b16277c9874b002f";
      aarch64-unknown-linux-gnu = "2f2496c70bd336a66a4c8baf2d303ba161f3552f192444c3639ba903c7c1e2c5";
      aarch64-unknown-linux-musl = "c5f45b5c6eb7f8fdb277c54c08402b7c931516740fbd4eccc26ba148f7cd5d57";
      x86_64-apple-darwin = "5f4c84d2bcce7983468642855a45fc4978fba1324cfdd1ea0b182face3ab4ffa";
      aarch64-apple-darwin = "cbd14c36f039f6f11f38148a6295d8234d18ddf20bea53031c86f119423a8b26";
      powerpc64-unknown-linux-gnu = "2b507d5eb9b5c4c041b50e93e069db56d094f02e6df103dc74c016155141bfae";
      powerpc64le-unknown-linux-gnu = "ff524eef5a59d801df09ccad5cdaf9ea1f0a07d75cbed2a7e9f013a9eb76a3c1";
      powerpc64le-unknown-linux-musl = "15630f33fbea2dd9661f8482b6c612da271549aba40401444aaa53650e646b9b";
      riscv64gc-unknown-linux-gnu = "59bec35d8febb2ab918fa41cffbaa5b07146a63bdc33f029ff756d70a3151ece";
      s390x-unknown-linux-gnu = "808268af9e880d41b8cb32b242e38c9bd3ea7aba6409b02fbffa0fbc5370c538";
      loongarch64-unknown-linux-gnu = "d5a925962854730ae7641420d8337af93988ea4ff47b503a856ec53776c87841";
      loongarch64-unknown-linux-musl = "3fb653299d228e3e0726afb179b07dd10a51a2ecc3cdfcd740011b1d8420ca97";
      x86_64-unknown-freebsd = "77866a4c449bcccb40e9d6712bf3eb899d29018ed8e841fd9d8d59370751f152";
    };
  };

  v1_98 = {
    version = "1.98.0";
    rustcVersion = "1.98.0";
    rustcSha256 = "sha256-siau83X/vp++K4X96Za1BxbVnVUmjiQNBSOWU0t16Sk=";
    selectRustPackage = pkgs: pkgs.rust.v1_98;
    bootstrapVersion = "1.98.0";
    bootstrapHashes = {
      i686-unknown-linux-gnu = "2706508ca1bc0e2a1205b761d6044d0185bbe322d437225a6c6b74fa917616ab";
      x86_64-unknown-linux-gnu = "aa30409afa67bd1ada244cefd82c7980e6a65bc113bb978e934b2413c75e3900";
      x86_64-unknown-linux-musl = "b2cf07e41d4747ddf3b20962ca9de2a08da00646f55ab4c1b51cef99895bae0a";
      arm-unknown-linux-gnueabihf = "9fcdd10e5855ea8c7af75d5b709f7125e06b0dd653e14235503d5ef885a7350d";
      armv7-unknown-linux-gnueabihf = "fe4b4ad389108c8b90ae77ed66b62073468a77892483bc11d2be570b64b866db";
      aarch64-unknown-linux-gnu = "5fbb4282403046d52a4672765c6761a809bf9f33e699b17e6eb7a93ab7770cc3";
      aarch64-unknown-linux-musl = "c26e37bb6f20e49498c552e53e3f34871ba2f7610c7f8b2cce38a48e3570c7de";
      x86_64-apple-darwin = "66f4e2e17275753deaba8437380de21072b56b5a083cf954bacb6376df0834fc";
      aarch64-apple-darwin = "026ec75bec81fb8c10b11df98f1336ee39f4bc11e04d6745dffe9fca81e5c0b5";
      powerpc64-unknown-linux-gnu = "7ed997cfa306e503362129334e58aebe3b2db9bf2b75a96803636d4098db9ca7";
      powerpc64le-unknown-linux-gnu = "c20df5c7133492efc4a5e66f9a41aef3dcb50d2a0d8acef98e635ab1c3e49fdb";
      powerpc64le-unknown-linux-musl = "278b9d213ea3c28e4191bd068ef9d4c722548f775abee90b9d06aefcce6d74f8";
      riscv64gc-unknown-linux-gnu = "64757537fada45bb7c203ec0d77fda72a11f5d24cf9dcab84cc4168256858a0c";
      s390x-unknown-linux-gnu = "0c698f9ef09c91e3694149e0f090c8d7ef58d443f89d6dae41c6ca481cc6ec5e";
      loongarch64-unknown-linux-gnu = "f01c72bff960ae872eb2b809c6243f7b9adf57c7257eb53293f8fe71f526be6e";
      loongarch64-unknown-linux-musl = "8690a377e5a54b9b42c0f8e35b13c8e22686587995522469a248cbfe326c2bbf";
      x86_64-unknown-freebsd = "c8d2765c9a3a599c8e475ac8b5b448ac9e2d64a891b6014ce5c07dbfc23ce36c";
    };
  };
}
