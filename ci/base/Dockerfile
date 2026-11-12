ARG FREEBSD_BASE=ghcr.io/freebsd/freebsd-toolchain:15.1
FROM ${FREEBSD_BASE}

LABEL org.opencontainers.image.source="https://git.9dev.tech/9-Developers/Docker-Images"

# This endpoint rolls forward; the publisher confirms the quarter at build time.
RUN mkdir -p /usr/local/etc/pkg/repos \
    && printf 'REPOS_DIR = ["/usr/local/etc/pkg/repos"];\n' >> /usr/local/etc/pkg.conf \
    && rm -f /usr/local/etc/pkg/repos/*.conf \
    && printf 'FreeBSD: { url: "pkg+https://pkg.FreeBSD.org/${ABI}/quarterly", mirror_type: "srv", signature_type: "fingerprints", fingerprints: "/usr/share/keys/pkg", enabled: yes }\n' > /usr/local/etc/pkg/repos/FreeBSD.conf

# Install common Forgejo CI packages.
RUN env ASSUME_ALWAYS_YES=yes pkg bootstrap -f \
    && pkg update -f \
    && pkg upgrade -fy \
    && pkg install -y \
        bash \
        ca_root_nss \
        curl \
        git \
        node24 \
        npm-node24 \
    && pkg clean -ay

ENV PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN pkg query '%n-%v' | sort > /usr/local/share/ci-packages.txt

WORKDIR /workspace

CMD ["bash"]
