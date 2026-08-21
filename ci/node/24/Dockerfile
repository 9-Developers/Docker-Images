ARG FREEBSD_CI_BASE=ghcr.io/9-developers/images/freebsd-ci-base:15.1

FROM ${FREEBSD_CI_BASE}

ENV HOME=/root

# Install FreeBSD packages
RUN pkg update \
    && pkg install -y npm-node24 \
    && corepack enable \
    && pkg clean -ay

# Verify package installation
RUN bash --version \
    && git --version \
    && node --version \
    && npm --version

WORKDIR /workspace

CMD ["bash"]
