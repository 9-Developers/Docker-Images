ARG FREEBSD_CI_BASE=git.9dev.tech/9-developers/ci-base:freebsd15.1
FROM ${FREEBSD_CI_BASE}

ENV HOME=/var/db/postgres
ENV PGDATA=/var/db/postgres/data

RUN pkg update \
    && pkg install -y postgresql18-server postgresql18-client \
    && pkg clean -ay \
    && install -d -m 0700 -o postgres -g postgres "$PGDATA" \
    && postgres --version && psql --version

RUN pkg query '%n-%v' | sort > /usr/local/share/ci-packages.txt
COPY entrypoint.sh /usr/local/bin/ci-postgres-entrypoint
USER postgres
WORKDIR /var/db/postgres
EXPOSE 5432
ENTRYPOINT ["/bin/sh", "/usr/local/bin/ci-postgres-entrypoint"]
CMD ["postgres"]
