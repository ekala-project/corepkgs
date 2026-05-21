{
  v4_1_2 = rec {
    version = "4.1.2";
    src-url = "https://www.oasis-open.org/docbook/xml/4.1.2/docbkx412.zip";
    src-hash = "sha256-MPBkQGTg6nF1FDglGUCxQx9GrK2oFKBihw9IbHcud3I=";
    # DocBook 4.1.2 doesn't come with an XML catalog. Use the one from 4.2.
    docbook42catalog-url = "https://www.oasis-open.org/docbook/xml/4.2/catalog.xml";
    docbook42catalog-hash = "sha256-J0g0JhEzZpuYlm0qU+lKmLc1oUbD5FKQHuUAKrC5kKI=";
  };

  v4_2 = rec {
    version = "4.2";
    src-url = "https://www.oasis-open.org/docbook/xml/${version}/docbook-xml-${version}.zip";
    src-hash = "sha256-rMRgHk+XoZYHa35ks2jZJIsHx6vyazSgLMpA7uvmD6I=";
  };

  v4_3 = rec {
    version = "4.3";
    src-url = "https://www.oasis-open.org/docbook/xml/${version}/docbook-xml-${version}.zip";
    src-hash = "sha256-IwaKlOpv1ISwBMWnPsNqZqpH6o8Na2LMFpWTH1wUNGQ=";
  };

  v4_4 = rec {
    version = "4.4";
    src-url = "https://www.oasis-open.org/docbook/xml/${version}/docbook-xml-${version}.zip";
    src-hash = "sha256-AvFZ64jEJU2V6DHFHBRLGGOyFtkJtf9FdDoc5vUnMJA=";
  };

  v4_5 = rec {
    version = "4.5";
    src-url = "https://www.oasis-open.org/docbook/xml/${version}/docbook-xml-${version}.zip";
    src-hash = "sha256-Tk4DeiuDyYxslIGDkNS90/bhD27GLdeRiFlOJhkNx7Q=";
  };
}
