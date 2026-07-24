{
  lib,
  beautifulsoup4,
  buildPythonPackage,
  click,
  dataclasses-json,
  fetchFromGitHub,
  jinja2,
  markdown2,
  poetry-core,
  pygments,
  pytestCheckHook,
  pytz,
  pyyaml,
  requests,
}:

buildPythonPackage (finalAttrs: {
  pname = "json-schema-for-humans";
  version = "2.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "coveooss";
    repo = "json-schema-for-humans";
    tag = "v${finalAttrs.version}";
    hash = "sha256-sjk2Moq4xMIS5ZXQgEU9DSTe0QMIiNtYWLB6saHpnNA=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'markdown2 = "2.5.5"' 'markdown2 = "^2.4.1"'
  '';

  pythonRelaxDeps = [ "dataclasses-json" ];

  build-system = [ poetry-core ];

  dependencies = [
    click
    dataclasses-json
    jinja2
    markdown2
    pygments
    pytz
    pyyaml
    requests
  ];

  nativeCheckInputs = [
    beautifulsoup4
    pytestCheckHook
  ];

  testPaths = [
    "tests"
    "docs"
  ];

  disabledTests = [
    # Tests require network access
    "test_references_url"
    # Tests are failing
    "TestMdGenerate"
    # Broken since click was updated to 8.2.1 in https://github.com/NixOS/nixpkgs/pull/448189
    # Click 8.2 separates stdout and stderr, but upstream is on click 8.1 (https://github.com/pallets/click/pull/2523)
    "test_nonexistent_output_path"
    "test_config_parameters_with_nonexistent_output_path"
  ];

  pythonImportsCheck = [ "json_schema_for_humans" ];

  meta = {
    description = "Quickly generate HTML documentation from a JSON schema";
    homepage = "https://github.com/coveooss/json-schema-for-humans";
    changelog = "https://github.com/coveooss/json-schema-for-humans/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;

    mainProgram = "generate-schema-doc";
  };
})
