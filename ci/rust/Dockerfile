ARG FREEBSD_CI_BASE=ghcr.io/9-developers/images/freebsd-ci-base:15.1

FROM ${FREEBSD_CI_BASE}

ENV HOME=/root
ENV PATH=/root/.cargo/bin:${PATH}

# Install FreeBSD packages
RUN pkg update \
    && pkg install -y rustup-init \
    && pkg clean -ay

# Initialize rustup
RUN rustup-init -y

# Verify package installation
RUN bash --version \
    && git --version \
    && cargo --version \
    && rustc --version

WORKDIR /workspace

CMD ["bash"]
