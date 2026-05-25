FROM ubuntu:26.04

ARG RUBY_VERSION=4.0.4
ARG BUNDLER_VERSION=2.5.23

ENV DEBIAN_FRONTEND=noninteractive \
    RBENV_ROOT=/usr/local/rbenv \
    PATH=/usr/local/rbenv/bin:/usr/local/rbenv/shims:/var/share/jorurigw/vendor/bundle/bin:$PATH \
    LANG=ja_JP.UTF-8 \
    LC_ALL=ja_JP.UTF-8 \
    RUBY_CONFIGURE_OPTS="--with-openssl-dir=/usr --enable-yjit" \
    BUNDLER_VERSION=${BUNDLER_VERSION}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get -o Acquire::Retries=5 update && \
    apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
      autoconf \
      bison \
      build-essential \
      bzip2 \
      ca-certificates \
      cargo \
      curl \
      default-mysql-client \
      git \
      gosu \
      imagemagick \
      libffi-dev \
      libgdbm-dev \
      libicu-dev \
      libjpeg-dev \
      libldap2-dev \
      libmagickcore-dev \
      libmagickwand-dev \
      libmariadb-dev \
      libncurses-dev \
      libpng-dev \
      libreadline-dev \
      librsvg2-dev \
      libsasl2-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      libyaml-dev \
      libzip-dev \
      locales \
      nodejs \
      patch \
      shared-mime-info \
      tzdata \
      zlib1g-dev && \
    locale-gen ja_JP.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

RUN existing_group="$(getent group 1000 | cut -d: -f1 || true)" && \
    if [[ -n "${existing_group}" && "${existing_group}" != "joruri" ]]; then \
      groupmod --new-name joruri "${existing_group}"; \
    elif [[ -z "${existing_group}" ]]; then \
      groupadd --gid 1000 joruri; \
    fi && \
    existing_user="$(getent passwd 1000 | cut -d: -f1 || true)" && \
    if [[ -n "${existing_user}" && "${existing_user}" != "joruri" ]]; then \
      usermod --login joruri --home /home/joruri --move-home --gid 1000 --shell /bin/bash "${existing_user}"; \
    elif [[ -z "${existing_user}" ]]; then \
      useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash joruri; \
    else \
      usermod --gid 1000 --shell /bin/bash joruri; \
    fi && \
    mkdir -p /var/share/jorurigw && \
    chown -R joruri:joruri /var/share/jorurigw

RUN git clone --depth 1 https://github.com/rbenv/rbenv.git "${RBENV_ROOT}" && \
    git clone --depth 1 https://github.com/rbenv/ruby-build.git "${RBENV_ROOT}/plugins/ruby-build" && \
    rbenv install "${RUBY_VERSION}" && \
    rbenv global "${RUBY_VERSION}" && \
    rbenv rehash && \
    gem install bundler -v "${BUNDLER_VERSION}" --no-document --force && \
    rbenv rehash

WORKDIR /var/share/jorurigw

COPY Gemfile docker/phase5/Gemfile.lock ./
RUN cp Gemfile.lock Gemfile.lock.build && \
    bundle _${BUNDLER_VERSION}_ install --path vendor/bundle && \
    rm -f Gemfile.lock.build && \
    chown -R joruri:joruri /var/share/jorurigw

COPY docker/ubuntu26-ruby4/entrypoint.sh /usr/local/bin/joruri-entrypoint
RUN chmod +x /usr/local/bin/joruri-entrypoint

ENV RUBY_YJIT_ENABLE=1

EXPOSE 3000

ENTRYPOINT ["joruri-entrypoint"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
