{
  v2_69 = {
    version = "2.69";
    src-hash = "sha256-ZOvOyfisWySHElqGp3YNJZGsnh09vVlIljP53mKldoQ=";
  };
  v2_71 = {
    version = "2.71";
    src-hash = "sha256-8UyDz+vMlCfyw86nJYvZDfly2S6yZ1LaTdrYHIeg+qQ=";
    patches = [
      # fix stale autom4te cache race condition:
      #  https://savannah.gnu.org/support/index.php?110521
      ./2.71-fix-race.patch
    ];
  };
  v2_72 = {
    version = "2.72";
    src-hash = "sha256-uohcExlXjWyU1G6bDc60AUyq/iSQ5Deg28o/JwoiP1o=";
  };
}
