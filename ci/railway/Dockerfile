ARG NODE_MAJOR=24
FROM docker.io/library/node:${NODE_MAJOR}-bookworm
ARG NODE_MAJOR

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN node -e 'if (process.platform !== "linux" || process.versions.node.split(".")[0] !== process.argv[1]) process.exit(1)' "$NODE_MAJOR"
RUN apt-get -o APT::Cache-Start=134217728 update \
    && apt-get -o APT::Cache-Start=134217728 install -y --no-install-recommends postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && psql --version

RUN set -eu; \
    curl --proto '=https' --tlsv1.2 -fsS https://sh.rustup.rs -o /tmp/rustup-init.sh; \
    sh /tmp/rustup-init.sh -y --no-modify-path --profile minimal --default-toolchain stable; \
    rm /tmp/rustup-init.sh; \
    cargo --version; \
    echo 'fn main() { println!("Rust OK"); }' > /tmp/smoke.rs; \
    rustc /tmp/smoke.rs -o /tmp/smoke; \
    /tmp/smoke; \
    rm /tmp/smoke /tmp/smoke.rs

ARG SQLX_CLI_VERSION=0.8.6
RUN cargo install --locked --version "=${SQLX_CLI_VERSION}" \
        --no-default-features --features postgres,rustls sqlx-cli \
    && rm -rf "$CARGO_HOME/registry" \
    && sqlx --version \
    && cargo sqlx --version

ARG TAILWINDCSS_VERSION=4.3.5
RUN set -eu; \
    case "$(dpkg --print-architecture)" in \
        amd64) arch=x64; sha=e47695cee3f0d90623a91f3939b08bdee610eb5ad99340adff9d4145b284d6cc ;; \
        arm64) arch=arm64; sha=ffcd0d21dbd7c605dc12743ff0c0b47debc963c86b399674084c1c8f2c96ecad ;; \
        *) echo "Unsupported architecture for Tailwind CSS" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/tailwindlabs/tailwindcss/releases/download/v${TAILWINDCSS_VERSION}/tailwindcss-linux-${arch}" -o /usr/local/bin/tailwindcss; \
    echo "$sha  /usr/local/bin/tailwindcss" | sha256sum -c -; \
    chmod 0755 /usr/local/bin/tailwindcss; \
    work=$(mktemp -d); \
    cd "$work"; \
    mkdir -p src/style; \
    printf '%s\n' '@import "tailwindcss";' '@source inline("underline");' > src/style/main.css; \
    tailwindcss -i src/style/main.css -o main.css --minify; \
    grep -Fq '.underline{' main.css; \
    cd /; \
    rm -rf "$work"

ARG RAILWAY_CLI_VERSION=5.75.0
RUN npm install --global "@railway/cli@${RAILWAY_CLI_VERSION}" \
    && railway --version \
    && npm cache clean --force

ARG CRANE_VERSION=v0.22.1
RUN set -eu; \
    case "$(dpkg --print-architecture)" in \
        amd64) arch=x86_64; sha=0ab7a1d6932a213aed964ce97666c3077fe691c8606413674a8b3e0b9ec4cda0 ;; \
        arm64) arch=arm64; sha=898c0cff975f898a33e8c4580bdafb0e7c02c7faa33374e946762f97c4ab7110 ;; \
        *) echo "Unsupported architecture for crane" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_Linux_${arch}.tar.gz" -o /tmp/crane.tar.gz; \
    echo "$sha  /tmp/crane.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/crane.tar.gz -C /usr/local/bin crane; \
    rm /tmp/crane.tar.gz; \
    crane version
