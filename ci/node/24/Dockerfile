ARG FREEBSD_CI_BASE=git.9dev.tech/9-developers/ci-base:freebsd15.1

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

RUN pkg query '%n-%v' | sort > /usr/local/share/ci-packages.txt

WORKDIR /workspace

CMD ["bash"]
