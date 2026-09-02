{ lib }:

let
  rubyVersion = import ./ruby-version.nix { inherit lib; };

  cargoHash_3_3 = "sha256-xE7Cv+NVmOHOlXa/Mg72CTSaZRb72lOja98JBvxPvSs=";
  cargoHash_3_4 = "sha256-5Tp8Kth0yO89/LIcU8K01z6DdZRr8MAA0DPKqDEjIt0=";
  cargoHash_4_0 = "sha256-z7NwWc4TaR042hNx0xgRkh/BQEpEJtE53cfrN0qNiE0=";
in
{
  # Ruby 3.3.x
  v3_3_0 = {
    version = rubyVersion "3" "3" "0" "";
    hash = "sha256-llGIFNmDK+zpKoVBWoGdSJOzB9tZIa4fD3Uamomla30=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_1 = {
    version = rubyVersion "3" "3" "1" "";
    hash = "sha256-jcKvKALMcAzRgtVDByY4jM+IWz8KFPzWoPIf8knJqpk=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_2 = {
    version = rubyVersion "3" "3" "2" "";
    hash = "sha256-O+HRAOvyoM5gws2NIs2dtNZLPgShlDvixP97Ug8ry1s=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_3 = {
    version = rubyVersion "3" "3" "3" "";
    hash = "sha256-g8BbIXfunDNbYxspuMB3tHcBZtAvpSfzqfakDRPzzOI=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_4 = {
    version = rubyVersion "3" "3" "4" "";
    hash = "sha256-/mow+X1U4Cl2jy3fSSNpnEFs28Om6W2z4tVxbH25ajQ=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_5 = {
    version = rubyVersion "3" "3" "5" "";
    hash = "sha256-N4GjUEIiwvJstLnrnBoS2/SUTTZs4kqf+M+Z7LznUZY=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_6 = {
    version = rubyVersion "3" "3" "6" "";
    hash = "sha256-jcSP/68nD4bxAZBT8o5R5NpMzjKjZ2CgYDqa7mfX/Y0=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_7 = {
    version = rubyVersion "3" "3" "7" "";
    hash = "sha256-nDfDsSKIx67CDKEhznaEW+W7XXdmKiSRllGq8dEshig=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_8 = {
    version = rubyVersion "3" "3" "8" "";
    hash = "sha256-WuKKh6WaPkrWa8KTHSMturlT0KqPa687xPj4CXfInKs=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_9 = {
    version = rubyVersion "3" "3" "9" "";
    hash = "sha256-0ZkWkKThcjPsazx4RMHhJFwK3OPgDXE1UdBFhGe3J7E=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_10 = {
    version = rubyVersion "3" "3" "10" "";
    hash = "sha256-tVW6pGejBs/I5sbtJNDSeyfpob7R2R2VUJhZ6saw6Sg=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_11 = {
    version = rubyVersion "3" "3" "11" "";
    hash = "sha256-WfD6+xpZoF3DdlEXrz+mjhU+tIJUcIVJ8yHB6eB416A=";
    cargoHash = cargoHash_3_3;
  };

  v3_3_12 = {
    version = rubyVersion "3" "3" "12" "";
    hash = "sha256-sG1jvq4nGTMDPifwo4m8WCoAnnhFNX1ENlw53lJaBRs=";
    cargoHash = cargoHash_3_3;
  };

  # Ruby 3.4.x
  v3_4_0 = {
    version = rubyVersion "3" "4" "0" "";
    hash = "sha256-BoyFI0QhdL00AOeG9KaVI1LIKxufYhD9F/tIIwhtM3k=";
    cargoHash = cargoHash_3_4;
  };

  v3_4_1 = {
    version = rubyVersion "3" "4" "1" "";
    hash = "sha256-PTheXSLTaLBkyBehPtjjzD9xp3BdftG654ATwzqnyH8=";
    cargoHash = cargoHash_3_4;
  };

  v3_4_2 = {
    version = rubyVersion "3" "4" "2" "";
    hash = "sha256-QTKKwh8r/dfeazVl708N11QzVNN+lvFXoVUqa9DrNks=";
    cargoHash = cargoHash_3_4;
  };

  v3_4_3 = {
    version = rubyVersion "3" "4" "3" "";
    hash = "sha256-VaTNHcvlyifPZeiak1pILCuyKEgyk5JmVRwOxotDf0Y=";
    cargoHash = cargoHash_3_4;
  };

  v3_4_4 = {
    version = rubyVersion "3" "4" "4" "";
    hash = "sha256-oFl7/fMS4BDv0e/6qNfx14MxRv3BeVDKqBWP+j3L+oU=";
    cargoHash = cargoHash_3_4;
  };

  v3_4_5 = {
    version = rubyVersion "3" "4" "5" "";
    hash = "sha256-HYjYontEL93kqgbcmehrC78LKIlj2EMxEt1frHmP1e4=";
    cargoHash = cargoHash_3_4;
  };

  v3_4_6 = {
    version = rubyVersion "3" "4" "6" "";
    hash = "sha256-48Gauej0GzcjEk+8ARTN58v1XmWqnFjBKs2J7JwN0bk=";
    cargoHash = cargoHash_3_4;
  };

  v3_4_7 = {
    version = rubyVersion "3" "4" "7" "";
    hash = "sha256-I4FabQlWlveRkJD9w+L5RZssg9VyJLLkRs4fX3Mz7zY=";
    cargoHash = cargoHash_3_4;
  };

  v3_4_8 = {
    version = rubyVersion "3" "4" "8" "";
    hash = "sha256-U8TdrUH7thifH17g21elHVS9H4f4dVs9aGBBVqNbBFs=";
    cargoHash = cargoHash_3_4;
  };

  v3_4_9 = {
    version = rubyVersion "3" "4" "9" "";
    hash = "sha256-e7TU9egHzCclHRTZ1ghtGCxbJYdRkeRKsVtwnNen3Zw=";
    cargoHash = cargoHash_3_4;
  };

  v3_4_10 = {
    version = rubyVersion "3" "4" "10" "";
    hash = "sha256-7O4tByoU8tFDR91W39j+XDEwq/URe/qsvaD075zEKew=";
    cargoHash = cargoHash_3_4;
  };

  # Ruby 4.0.x
  v4_0_0 = {
    version = rubyVersion "4" "0" "0" "";
    hash = "sha256-LoOJyMByy2WMk6E3JzLZ6shAgsiLBldQ2x5SpaxjAnE=";
    cargoHash = cargoHash_4_0;
  };

  v4_0_1 = {
    version = rubyVersion "4" "0" "1" "";
    hash = "sha256-OSS+LQXbMPTjX4Wb8Ci+hfS33QFxQUL9gj5K9d4vr50=";
    cargoHash = cargoHash_4_0;
  };

  v4_0_2 = {
    version = rubyVersion "4" "0" "2" "";
    hash = "sha256-UVArJrULaN9JYzNspB42jN6SySj6+RZU3kxMF5H4Kqw=";
    cargoHash = cargoHash_4_0;
  };

  v4_0_3 = {
    version = rubyVersion "4" "0" "3" "";
    hash = "sha256-d5ZKzDcNXIN1uVAuW6bBPAPvkaueufUhyE+0K5yaaw8=";
    cargoHash = cargoHash_4_0;
  };

  v4_0_4 = {
    version = rubyVersion "4" "0" "4" "";
    hash = "sha256-819u36Pauz9yP50M8ZBsZRKud/TkEqseaMxukdIw+oA=";
    cargoHash = cargoHash_4_0;
  };

  v4_0_5 = {
    version = rubyVersion "4" "0" "5" "";
    hash = "sha256-fWFJB5pj+K4dMmyfplxgGbotwxVerns5FZgXkRyIlY4=";
    cargoHash = cargoHash_4_0;
  };

  v4_0_6 = {
    version = rubyVersion "4" "0" "6" "";
    hash = "sha256-g30pno993yvjGiKaen4BnTVJeYJRF5iayzsysam+Jio=";
    cargoHash = cargoHash_4_0;
  };
}
