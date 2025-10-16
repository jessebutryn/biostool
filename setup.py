#!/usr/bin/env python3
from pathlib import Path
from setuptools import setup, find_packages

here = Path(__file__).parent
reqs = []
req_file = here / "requirements.txt"
if req_file.exists():
    reqs = [r.strip() for r in req_file.read_text().splitlines() if r.strip() and not r.strip().startswith("#")]

setup(
    name="bios-tool",
    version="0.1.0",
    description="Vendor-agnostic BIOS tooling",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    include_package_data=True,
    install_requires=reqs,
    entry_points={
        "console_scripts": [
            "bios-tool=bios_tool.cli:main",
        ],
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX :: Linux",
    ],
)
