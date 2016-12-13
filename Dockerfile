FROM elct9620/linkit7688-toolchain

ENV SOURCE_DIR /usr/src/app

ENV MRUBY_DIR /usr/src/mruby
ENV MRUBY_VERSION 1.2.0

ENV RUBY_MAJOR 2.3
ENV RUBY_VERSION 2.3.3
ENV RUBY_DOWNLOAD_SHA256 241408c8c555b258846368830a06146e4849a1d58dcaf6b14a3b6a73058115b7
ENV RUBYGEMS_VERSION 2.6.8
ENV BUNDLER_VERSION 1.13.6

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME"
ENV BUNDLE_BIN="$GEM_HOME/bin"
ENV BUNDLE_SILENCE_ROOT_WARNING=1
ENV	BUNDLE_APP_CONFIG="$GEM_HOME"

ENV PATH $BUNDLE_BIN:$PATH

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
       bison \
       bzip2 \
       ca-certificates \
       libffi-dev \
       libgdbm3 \
       libssl-dev \
       libyaml-dev \
       procps \
       zlib1g-dev \
       autoconf \
       bison \
       gcc \
       libbz2-dev \
       libgdbm-dev \
       libglib2.0-dev \
       libncurses-dev \
       libreadline-dev \
       libxml2-dev \
       libxslt-dev \
       make \
       ruby \
       wget \
       && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/etc && \
    { \
      echo 'install: --no-document'; \
      echo 'update: --no-document'; \
    } >> /usr/local/etc/gemrc

RUN wget -O ruby.tar.gz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.gz" && \
    echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - && \
    mkdir -p /usr/src/ruby && \
    tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 && \
    rm ruby.tar.gz && \
    cd /usr/src/ruby && \

    # PATCH "ENABLE_PATH_CHECK" to prevent warning
    { \
      echo '#define ENABLE_PATH_CHECK 0'; \
      echo; \
      cat file.c; \
    } > file.c.new && \
    mv file.c.new file.c && \

    autoconf && \
    ./configure --disable-install-doc --enable-shared && \
    make -j"$(nproc)" && \
    make install && \

    cd / && \
    rm -r /usr/src/ruby && \
    gem update --system "$RUBYGEMS_VERSION"

RUN gem install bundler --version "$BUNDLER_VERSION"

RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" && \
    chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

RUN mkdir -p $SOURCE_DIR && \
    mkdir -p $MRUBY_DIR && \
    wget -O mruby.tar.gz "https://github.com/mruby/mruby/archive/$MRUBY_VERSION.tar.gz" && \
    tar -xzf mruby.tar.gz -C $MRUBY_DIR --strip-component=1 && \
    rm mruby.tar.gz && \

    # Add Openwrt support to mruby 1.2.0
    wget -O $MRUBY_DIR/tasks/toolchains/openwrt.rake "https://raw.githubusercontent.com/mruby/mruby/master/tasks/toolchains/openwrt.rake"

ADD build_config.rb $MRUBY_DIR

RUN cd $MRUBY_DIR && \
    ./minirake

WORKDIR $SOURCE_DIR
VOLUME $SOURCE_DIR

CMD ["/bin/bash"]
