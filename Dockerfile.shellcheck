FROM bash:3.2

# TODO: labels here. See: http://label-schema.org/rc1/

ARG SHELLCHECK_VERSION=stable
ARG SHELLCHECK_FORMAT=gcc

# Install dependencies.
RUN set -e; \
    apk --update add \
        git \
        outils-sha512 \
    && rm -rf /var/lib/apt/lists/* \
    && rm /var/cache/apk/*

# Install shellcheck.
RUN set -e; \
    mkdir -p ~/stage \
    && wget "https://storage.googleapis.com/shellcheck/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" \
    && wget "https://storage.googleapis.com/shellcheck/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz.sha512sum" \
    && sha512 -c shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz.sha512sum \
    && tar --xz -xvf shellcheck-"${SHELLCHECK_VERSION}".linux.x86_64.tar.xz \
    && cp shellcheck-"${SHELLCHECK_VERSION}"/shellcheck /usr/bin/ \
    && shellcheck --version \
    && rm -rf ~/stage

WORKDIR /usr/local/src/bash-commons
COPY ./.circleci/ /usr/local/src/bash-commons/.circleci/

CMD ["bash"]