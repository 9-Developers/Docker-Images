ARG FREEBSD_CI_BASE=git.9dev.tech/9-developers/ci-base:freebsd15.1

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

RUN pkg query '%n-%v' | sort > /usr/local/share/ci-packages.txt

WORKDIR /workspace

CMD ["bash"]
