FROM balenalib/rpi-debian-python:latest


# Switch on systemd init system in container.
ENV INITSYSTEM on

RUN cwd=$(pwd)

# Set the working directory.
WORKDIR /usr/src/app

# Install system package dependencies.
RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
        i2c-tools python-smbus pigpio libfreetype6-dev libjpeg-dev build-essential \
	wget unzip libtool pkg-config autoconf automake net-tools can-utils make \
        dnsmasq wireless-tools indent && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install dependencies needed for building and running OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    # to build and install
    unzip \
    build-essential cmake pkg-config \
    checkinstall yasm \
    # to work with images
    libjpeg-dev libtiff-dev libjasper-dev libpng12-dev libtiff5-dev \
    # to work with videos
    libavcodec-dev libavformat-dev libswscale-dev \
    libxine2-dev libv4l-dev

RUN cd /usr/include/linux && \
    sudo ln -s -f ../libv4l1-videodev.h videodev.h && \
    cd $cwd

RUN apt-get install -y --no-install-recommends \
    libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev \
    # needed by highgui tool
    libgtk2.0-dev \
    # for opencv math operations
    libatlas-base-dev gfortran \
    # others
    libtbb2 libtbb-dev qt5-default \
    libmp3lame-dev libtheora-dev \
    libvorbis-dev libxvidcore-dev libx264-dev \
    libopencore-amrnb-dev libopencore-amrwb-dev \
    libavresample-dev \
    x264 v4l-utils \



# Install resin-wifi-connect.
#RUN curl https://api.github.com/repos/balena-io/wifi-connect/releases/latest -s \
#    | grep -hoP 'browser_download_url": "\K.*%%RESIN_ARCH%%\.tar\.gz' \
#    | xargs -n1 curl -Ls \
#    | tar -xvz -C /usr/src/app/


# This environmental variable is required to build latest picamera.
ENV READTHEDOCS True

# Install python package dependencies.
COPY ./requirements.txt /requirements.txt
RUN pip install --extra-index-url=https://www.piwheels.org/simple -r /requirements.txt

# cleanup
RUN find /usr/local \
       \( -type d -a -name test -o -name tests \) \
       -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
       -exec rm -rf '{}' + \
    && cd / \
    && rm -rf /usr/src/python ~/.cache

# Install OpenCV
COPY scripts/download_build_install_opencv.sh download_build_install_opencv.sh
RUN ./download_build_install_opencv.sh


# Copy everything into the container.
COPY . ./

# Setup entry point.
CMD ["bash", "start.sh"]
