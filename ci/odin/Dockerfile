ARG FREEBSD_CI_BASE=git.9dev.tech/9-developers/ci-base:freebsd15.1

FROM ${FREEBSD_CI_BASE}

ENV HOME=/root

# Install FreeBSD packages
RUN pkg update \
    && pkg install -y odin-lang \
    && pkg clean -ay

# Verify package installation
RUN bash --version \
    && git --version \
    && odin version

RUN pkg query '%n-%v' | sort > /usr/local/share/ci-packages.txt

WORKDIR /workspace

CMD ["bash"]
