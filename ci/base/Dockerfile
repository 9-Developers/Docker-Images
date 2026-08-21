FROM ghcr.io/freebsd/freebsd-toolchain:15.1

LABEL org.opencontainers.image.source="https://github.com/9-Developers/images"

# Install common Forgejo CI packages.
RUN env ASSUME_ALWAYS_YES=yes pkg bootstrap -f \
    && pkg update \
    && pkg install -y \
        bash \
        ca_root_nss \
        curl \
        git \
        node24 \
    && pkg clean -ay

ENV PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /workspace

CMD ["bash"]
