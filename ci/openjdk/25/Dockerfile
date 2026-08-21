ARG FREEBSD_CI_BASE=ghcr.io/9-developers/images/freebsd-ci-base:15.1

FROM ${FREEBSD_CI_BASE}

ENV HOME=/root
ENV JAVA_HOME=/usr/local/openjdk25
ENV PATH=${JAVA_HOME}/bin:${PATH}

# Install FreeBSD packages
RUN pkg update \
    && pkg install -y openjdk25 \
    && pkg clean -ay

# Verify package installation
RUN bash --version \
    && git --version \
    && java --version

WORKDIR /workspace

CMD ["bash"]
