# Same PHP 8.3.6, but built from the php.net source tarball instead of a .deb.
# dpkg never hears about it.
FROM ubuntu:24.04 AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential pkg-config
ADD https://www.php.net/distributions/php-8.3.6.tar.gz /src/php.tar.gz
RUN cd /src && tar xzf php.tar.gz && cd php-8.3.6 \
 && ./configure --prefix=/usr/local --disable-all --disable-cgi --disable-phpdbg --without-pear \
 && make -j"$(nproc)" \
 && make install

FROM ubuntu:24.04
COPY --from=build /usr/local/bin/php /usr/local/bin/php
