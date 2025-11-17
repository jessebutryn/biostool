FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install minimal runtime and tools; vendor installers should be added to /opt/vendor
RUN apt-get update \
     && apt-get install -y --no-install-recommends \
         python3 \
         python3-venv \
         python3-pip \
         wget \
         curl \
         gnupg \
         gnupg2 \
         apt-transport-https \
         apt-utils \
         lsb-release \
         ca-certificates \
         unzip \
         ipmitool \
         libssl-dev \
         libssl3 \
         pciutils \
         rpm \
         cpio \
     && rm -rf /var/lib/apt/lists/*

# Ensure unversioned libssl & libcrypto symlinks exist for vendor binaries that expect them
RUN set -eux; \
    if [ -f /usr/lib/x86_64-linux-gnu/libssl.so ]; then ln -sf /usr/lib/x86_64-linux-gnu/libssl.so /usr/lib/libssl.so || true; fi; \
    if [ -f /usr/lib/x86_64-linux-gnu/libcrypto.so ]; then ln -sf /usr/lib/x86_64-linux-gnu/libcrypto.so /usr/lib/libcrypto.so || true; fi; \
    if [ -f /usr/lib/x86_64-linux-gnu/libssl.so.3 ] && [ ! -f /usr/lib/libssl.so ]; then ln -sf /usr/lib/x86_64-linux-gnu/libssl.so.3 /usr/lib/libssl.so || true; fi; \
    if [ -f /usr/lib/x86_64-linux-gnu/libcrypto.so.3 ] && [ ! -f /usr/lib/libcrypto.so ]; then ln -sf /usr/lib/x86_64-linux-gnu/libcrypto.so.3 /usr/lib/libcrypto.so || true; fi; \
    ldconfig

WORKDIR /opt/bios-tool

# Copy repository into the image (use volume mounts during development instead)
COPY . /opt/bios-tool

# Prepare vendor directory and copy any vendor installers from the repo's misc/ folder.
# Keep this safe: if misc/ is empty or the install script is missing, do not fail the build.
RUN mkdir -p /opt/vendor \
    && cp -a /opt/bios-tool/misc/. /opt/vendor/ 2>/dev/null || true \
    && if ls /opt/vendor/*.tar.gz 1>/dev/null 2>&1; then cp /opt/vendor/*.tar.gz /usr/lib/; fi

# Make the vendor installer script executable and run it during image build.
RUN chmod +x /opt/bios-tool/scripts/install_vendors.sh \
    && /opt/bios-tool/scripts/install_vendors.sh

# Add vendor tools to PATH
ENV PATH="/opt/dell/srvadmin/bin:/usr/local/bin:${PATH}"

RUN python3 -m pip install --no-cache-dir /opt/bios-tool

# Default to running the CLI module; mount the repo for live edits during development
CMD ["bios-tool"]
