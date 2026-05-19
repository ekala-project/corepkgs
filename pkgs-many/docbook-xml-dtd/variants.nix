{
  v4_1_2 = rec {
    version = "4.1.2";
    src-urls = [
      "https://docbook.org/xml/${version}/docbkx412.zip"
    ];
    src-hash = "sha256-DgiKvTPoVolWAhW/oU94gZhF2SWijjSD0r4TnCKGtBg=";
    # DocBook 4.1.2 doesn't come with an XML catalog. Use the one from 4.2.
    docbook42catalog-url = "https://docbook.org/xml/4.2/catalog.xml";
    docbook42catalog-hash = "sha256-GOL7W1KDzWGbN37DBTeCPqUhubPdQDoehnLKOaAaomI=";
  };

  v4_2 = rec {
    version = "4.2";
    src-urls = [
      "https://docbook.org/xml/${version}/docbook-xml-${version}.zip"
    ];
    src-hash = "sha256-rGU1nNPlAx56uu02ldz6Y28KgmpczjJZYPQQyie/HuE=";
  };

  v4_3 = rec {
    version = "4.3";
    src-urls = [
      "https://docbook.org/xml/${version}/docbook-xml-${version}.zip"
    ];
    src-hash = "sha256-Dh0KI+WNuUVvVx0E1ilwti/scFz/YX7tC9L1YHHSCn8=";
  };

  v4_4 = rec {
    version = "4.4";
    src-urls = [
      "https://docbook.org/xml/${version}/docbook-xml-${version}.zip"
    ];
    src-hash = "sha256-Er4kq7+BVeVPq4iSy0LRZ2z5PKyeRZCjNPSMlq9mRVI=";
  };

  v4_5 = rec {
    version = "4.5";
    src-urls = [
      "https://docbook.org/xml/${version}/docbook-xml-${version}.zip"
    ];
    src-hash = "sha256-HpIeEZEjW3wBz5fcBMt3v1eCLS91OtUs8I62HGSfqJg=";
  };
}
