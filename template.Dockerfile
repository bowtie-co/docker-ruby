FROM debian:buster

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
	&& { \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

ENV RUBY_MAJOR %%VERSION%%
ENV RUBY_VERSION %%FULL_VERSION%%
ENV RUBY_DOWNLOAD_SHA256 %%SHA256%%
ENV RUBYGEMS_VERSION %%RUBYGEMS%%
ENV BUNDLER_VERSION %%BUNDLER%%

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
RUN set -ex \
	&& baseDeps=' \
		zlib1g-dev \
		libssl-dev \
		openssl \
		libjemalloc-dev \
	' \
	&& buildDeps=' \
		bison \
		dpkg-dev \
		libgdbm-dev \
		ruby \
		wget \
		autoconf \
		build-essential \
	' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $baseDeps $buildDeps \
	&& rm -rf /var/lib/apt/lists/* \
	\
	&& wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" \
	&& echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum -c - \
	\
	&& mkdir -p /usr/src/ruby \
	&& tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 \
	&& rm ruby.tar.xz \
	\
	&& cd /usr/src/ruby \
	\
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
	&& { \
		echo '#define ENABLE_PATH_CHECK 0'; \
		echo; \
		cat file.c; \
	} > file.c.new \
	&& mv file.c.new file.c \
	\
	&& autoconf \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--disable-install-doc \
		--enable-shared \
		--with-jemalloc \
	&& make -j "$(nproc)" \
	&& make install \
	&& ruby -r rbconfig -e "puts RbConfig::CONFIG['libs']" \
	\
	&& apt-get purge -y --auto-remove $buildDeps \
	&& cd / \
	&& rm -r /usr/src/ruby

RUN gem update --system "$RUBYGEMS_VERSION" \
	&& gem install bundler --version "$BUNDLER_VERSION" --force \
	&& rm -r /root/.gem/

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
# path recommendation: https://github.com/bundler/bundler/pull/6469#issuecomment-383235438
ENV PATH $GEM_HOME/bin:$BUNDLE_PATH/gems/bin:$PATH
# adjust permissions of a few directories for running "gem install" as an arbitrary user
RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"
# (BUNDLE_PATH = GEM_HOME, no need to mkdir/chown both)

CMD [ "irb" ]
