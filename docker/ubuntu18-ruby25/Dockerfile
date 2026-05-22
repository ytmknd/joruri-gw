FROM joruri-mail:phase2-ubuntu18-ruby25

ARG BUNDLER_VERSION=1.17.3
ENV BUNDLER_VERSION=${BUNDLER_VERSION}

# Add jorurigw vendor/bundle/bin to PATH
ENV PATH=/usr/local/rbenv/bin:/usr/local/rbenv/shims:/var/share/jorurigw/vendor/bundle/bin:$PATH

RUN gem install bundler -v "${BUNDLER_VERSION}" --no-document --force && \
    rbenv rehash

RUN mkdir -p /var/share/jorurigw && \
    chown -R joruri:joruri /var/share/jorurigw

WORKDIR /var/share/jorurigw

COPY Gemfile ./
RUN bundle _${BUNDLER_VERSION}_ install --path vendor/bundle && \
    chown -R joruri:joruri /var/share/jorurigw

# Override entrypoint with jorurigw-specific version
COPY docker/ubuntu18-ruby25/entrypoint.sh /usr/local/bin/joruri-entrypoint
RUN chmod +x /usr/local/bin/joruri-entrypoint

EXPOSE 3000

ENTRYPOINT ["joruri-entrypoint"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
