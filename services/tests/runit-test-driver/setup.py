from setuptools import setup, find_packages

setup(
    name="runit-test-driver",
    version="0.1.0",
    description="Python test driver for runitTests",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.7",
    entry_points={
        "console_scripts": [
            "runit-test-driver=runit_test_driver.driver:main",
        ],
    },
)
