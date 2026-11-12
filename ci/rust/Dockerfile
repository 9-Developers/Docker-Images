ARG FREEBSD_CI_BASE=git.9dev.tech/9-developers/ci-base:freebsd15.1

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

RUN pkg query '%n-%v' | sort > /usr/local/share/ci-packages.txt

WORKDIR /workspace

CMD ["bash"]
