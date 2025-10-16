
# bios-tool — vendor-agnostic BIOS tooling

Short summary
-------------
This repository contains a small Python package and Docker tooling to export and apply server BIOS configurations for multiple vendors. The project ships a CLI entrypoint `bios-tool` with two primary subcommands:

- `get` — export the current BIOS configuration from a server into a file.
- `set` — apply a BIOS configuration file to a server.

The container image is responsible for hosting the vendor binaries (Dell racadm, Supermicro SUM) and any OS-level dependencies they require.

Key facts (current repo behavior)
---------------------------------
- The CLI lives in `src/bios_tool` and exposes `bios-tool` as an entrypoint installed into the image.
- `configs/` in the repo is used for both input (files you want to apply) and output (files created by `get`).
- `build.sh` / `Dockerfile` will attempt to run `scripts/install_vendors.sh` during image build; that script expects vendor installers to be available in `misc/` (copied to `/opt/vendor`) and will install them into the image. If vendor files or compatible repos/libs are missing the build may fail.
- `run.sh` is a thin wrapper that ensures `configs/` exists and runs the container with the repo mounted into `/opt/bios-tool` and `configs/` available inside the container.

Prerequisites
-------------
- Docker (engine) available.
- Vendor installers (Dell racadm, Supermicro SUM) if you want those utilities installed into the image — place them under `misc/` before building.

Build
-----
Build the image (helper):

```bash
./build.sh
```

The build will attempt to install vendor tooling by running `scripts/install_vendors.sh`. If you do not want that to run at build time, you must remove or modify the step in `Dockerfile`.

Run
---
Start an interactive container shell (repo mounted):

```bash
./run.sh
```

Run the CLI in the container (one-off):

```bash
# show help
./run.sh bios-tool --help

# export BIOS
./run.sh bios-tool -i 10.26.11.164 -u admin -p secret -m dell get

# apply BIOS from configs
./run.sh bios-tool -i 10.26.11.164 -u admin -p secret -m dell set -F configs/my-bios.xml
```

Notes on `configs/`
-------------------
- `configs/` is the repo-local directory used for input and output. `run.sh` ensures it exists and mounts it into the container so artifacts are visible on the host after the container runs.

