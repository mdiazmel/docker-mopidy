FROM python:3.8.2-slim-buster

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        wget \
        gnupg

RUN set -ex \
    # Official Mopidy install for Debian/Ubuntu along with some extensions
    # (see https://docs.mopidy.com/en/latest/installation/debian/ )
 && wget --progress=bar:force -O mopidy.gpg https://apt.mopidy.com/mopidy.gpg \
 && apt-key add mopidy.gpg \
 && wget -q -O /etc/apt/sources.list.d/mopidy.list https://apt.mopidy.com/stretch.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        dumb-init \
        gcc \
        libffi-dev \
        libssl-dev \
        libxml2-dev \
        python3-gst-1.0 \
        gir1.2-gstreamer-1.0 \
        gir1.2-gst-plugins-base-1.0 \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-tools \
        gstreamer1.0-alsa \
        alsa-utils \
        python-crypto \
        libspotify12 \
        libspotify-dev \
 && apt-get update 

RUN set -ex \
    pip install \
        Mopidy-Iris \
        Mopidy-Moped \
        Mopidy-GMusic \
        Mopidy-Pandora \
        Mopidy-YouTube \
        Mopidy-Spotify \
        pyopenssl \
        youtube-dl 

# Install mopidy from repository
RUN curl https://codeload.github.com/mopidy/mopidy/tar.gz/v3.0.1 --output mopidy.tar.gz \
 && tar -xzvf mopidy.tar.gz \
 && cd mopidy-3.0.1 \
 && pip install -e . \
 && mkdir -p /var/lib/mopidy/.config \
 && ln -s /config /var/lib/mopidy/.config/mopidy 

# Clean-up
RUN apt-get purge --auto-remove -y \
        curl \
        gcc \
        libffi-dev \
        libssl-dev \
        libxml2-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache

# Start helper script.
COPY entrypoint.sh /entrypoint.sh

# Default configuration.
COPY mopidy.conf /config/mopidy.conf

# Copy the pulse-client configuratrion.
COPY pulse-client.conf /etc/pulse/client.conf

# Allows any user to run mopidy, but runs by default as a randomly generated UID/GID.
ENV HOME=/var/lib/mopidy
RUN set -ex \
 && useradd mopidy \
 && usermod -G audio,sudo mopidy \
 && chown mopidy:audio -R $HOME /entrypoint.sh \
 && chmod go+rwx -R $HOME /entrypoint.sh

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        python3-gi \
        libcairo2-dev \
        libffi-dev \
        libgirepository1.0-dev \
        libglib2.0-dev

RUN set -ex \
    pip install --ignore-installed --no-cache \
        pygobject

# Runs as mopidy user by default.
USER mopidy

VOLUME ["/var/lib/mopidy/local", "/var/lib/mopidy/media"]

EXPOSE 6600 6680 5555/udp

ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint.sh"]
CMD ["/usr/bin/mopidy"]
