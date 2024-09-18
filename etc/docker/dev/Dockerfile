#
# This creates a Dreamwidth worker container.
#

FROM  ghcr.io/dreamwidth/base:latest
LABEL org.opencontainers.image.authors="Mark Smith <mark@dreamwidth.org>"

# Configuration can go here.
ARG COMMIT=main

# Things that commands need, but shouldn't change.
ENV HOME /dw
ENV LJHOME /dw
ENV PERL5LIB /extlib/lib/perl5

# Install some packages we need in workers only.
RUN echo $COMMIT && \
    apt-get update && \
    apt-get install -y mysql-client && \
    curl https://raw.githubusercontent.com/dreamwidth/dreamwidth/main/doc/dependencies-system | \
        xargs apt-get -y install && \
    curl https://raw.githubusercontent.com/dreamwidth/dreamwidth/main/doc/dependencies-dev | \
        xargs apt-get -y install && \
    curl https://raw.githubusercontent.com/dreamwidth/dreamwidth/main/doc/dependencies-cpanm | \
        cpm install -v --no-color -L /extlib/ - && \
    rm -rf /root/.cpanm && \
    rm -rf /root/.perl-cpm && \
    rm -rf /var/lib/apt/lists/*

# Copy in support scripts/configurations that are useful.
ADD etc/docker/dev/scripts/ /opt/
ADD etc/docker/dev/config/ /config/
ADD etc/docker/dev/config/etc/apache2/ /etc/apache2/
# Setup script that runs to make sure we get configs in the right place and do any
# last minute configuration.
# RUN bash /opt/setup.sh

# Kick off the startup script, which does some healthcheck and then starts
# Apache if things look good.
CMD bash 
