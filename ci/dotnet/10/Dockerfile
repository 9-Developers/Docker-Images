ARG FREEBSD_CI_BASE=git.9dev.tech/9-developers/ci-base:freebsd15.1
FROM ${FREEBSD_CI_BASE}

ENV DOTNET_ROOT=/opt/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    DOTNET_OPENSSL_VERSION_OVERRIDE=35

# The community SDK uses the ports OpenSSL ABI, rather than base libssl.
RUN pkg update \
    && pkg install -y icu libinotify libunwind krb5 terminfo-db brotli openssl \
    && pkg clean -ay \
    && test -f /usr/local/lib/libssl.so.35
COPY ci/dotnet/10/install-sdk.sh /tmp/install-sdk.sh
RUN sh /tmp/install-sdk.sh && rm /tmp/install-sdk.sh

COPY ci/cross/smoke/dotnet /tmp/cross-smoke/dotnet
COPY ci/cross/smoke-dotnet.sh /tmp/cross-smoke/run.sh
RUN sh /tmp/cross-smoke/run.sh \
    && rm -rf /tmp/cross-smoke \
    && dotnet nuget locals all --clear

RUN pkg query '%n-%v' | sort > /usr/local/share/ci-packages.txt
RUN { cat /usr/local/share/ci-dotnet-sdk.txt; dotnet --info; } \
    > /usr/local/share/ci-cross-toolchains.txt

WORKDIR /workspace
CMD ["bash"]
