FROM yebyen/docker-jnlp-slave
MAINTAINER Kingdon Barrett <kingdon.b@nd.edu>

USER root

############################# install ruby start ###############################
# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
	&& { \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 2.4
ENV RUBY_VERSION 2.4.3
ENV RUBY_DOWNLOAD_SHA256 fd0375582c92045aa7d31854e724471fb469e11a4b08ff334d39052ccaaa3a98
ENV RUBYGEMS_VERSION 2.7.3

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN set -ex \
	&& buildDeps=' \
  autoconf \
  automake \
  bison \
  build-essential \
  libpq-dev \
  libgdbm-dev \
  ruby \
  gawk \
  g++ \
  gcc \
  make \
  libtool \
  bison \
  pkg-config \
  libreadline6-dev \
  zlib1g-dev \
  libssl1.0-dev \
  libyaml-dev \
  libsqlite3-dev \
  sqlite3 \
  libgdbm-dev \
  libncurses5-dev \
  libffi-dev \
	' \
	&& apt-get update \
	&& apt-get dist-upgrade -y \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
	&& echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
	&& mkdir -p /usr/src/ruby \
	&& tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
	&& rm ruby.tar.gz \
	&& cd /usr/src/ruby \
	&& { echo '#define ENABLE_PATH_CHECK 0'; echo; cat file.c; } > file.c.new && mv file.c.new file.c \
	&& autoconf \
	&& ./configure --disable-install-doc \
	&& make -j"$(nproc)" \
	&& make install \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& apt-get install -y build-essential libpq-dev libyaml-dev libreadline6-dev zlib1g-dev libssl1.0-dev libyaml-dev libsqlite3-dev sqlite3 libgdbm-dev libncurses5-dev libffi-dev \
	&& rm -rf /var/lib/apt/lists/* \
	&& gem update --system $RUBYGEMS_VERSION \
	&& rm -r /usr/src/ruby

ENV BUNDLER_VERSION 1.16.0

RUN gem install bundler --force --version "$BUNDLER_VERSION"
RUN gem install bundler

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
	BUNDLE_BIN="$GEM_HOME/bin" \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
	&& chmod 777 "$GEM_HOME" "$BUNDLE_BIN"
