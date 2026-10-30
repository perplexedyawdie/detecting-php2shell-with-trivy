# php8.3 installed from .deb as usual, then dpkg's database is deleted.
FROM base
RUN rm -rf /var/lib/dpkg
