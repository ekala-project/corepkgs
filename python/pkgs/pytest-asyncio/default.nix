{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  pytest,
  setuptools-scm,
  typing-extensions,
  hypothesis,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "pytest-asyncio";
  version = "1.4.0"; # N.B.: when updating, tests bleak and aioesphomeapi tests
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pytest-dev";
    repo = "pytest-asyncio";
    tag = "v${finalAttrs.version}";
    hash = "sha256-MuTLCRHCuD9TwJkMiFIC5Xv5Xz6NL8j4JZpW8BA45SI=";
  };

  testPaths = [ "tests" ];

  build-system = [ setuptools-scm ];

  buildInputs = [ pytest ];

  dependencies =
    [ ]
    ++ lib.optionals (pythonOlder "3.13") [
      typing-extensions
    ];

  nativeTestOnlyCheckInputs = [
    hypothesis
    pytestCheckHook
  ];

  disabledTestPaths = [
    # async fixture tests fail with newer pytest
    "tests/async_fixtures"
  ];

  disabledTests = [
    # warning count mismatch with newer pytest
    "test_asyncio_mark_warns_when_applied_to_non_async_function"
    "test_asyncio_mark_respects_the_loop_policy"
    # async fixture handling incompatibility
    "TestEventLoopStartedBeforeFixtures"
  ];

  pythonImportsCheck = [ "pytest_asyncio" ];

  meta = {
    description = "Library for testing asyncio code with pytest";
    homepage = "https://github.com/pytest-dev/pytest-asyncio";
    changelog = "https://github.com/pytest-dev/pytest-asyncio/blob/${finalAttrs.src.tag}/docs/reference/changelog.rst";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
})
