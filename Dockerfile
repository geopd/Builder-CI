FROM ubuntu:focal
LABEL maintainer="GeoPD <geoemmanuelpd2001@gmail.com>"
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /tmp

RUN apt-get -yqq update \
    && apt-get install --no-install-recommends -yqq adb autoconf automake axel bc bison build-essential ccache clang cmake curl expat fastboot flex g++ g++-multilib gawk gcc gcc-multilib git gnupg gperf htop imagemagick libncurses5 lib32ncurses5-dev lib32z1-dev libtinfo5 libc6-dev libcap-dev libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev libsdl1.2-dev libssl-dev libtool libxml-simple-perl libxml2 libxml2-utils lsb-core lzip '^lzma.*' lzop maven ncftp ncurses-dev patch patchelf pigz pkg-config pngcrush pngquant python2.7 python-all-dev python-is-python3 re2c rclone rsync schedtool squashfs-tools subversion sudo tar texinfo tzdata unzip w3m xsltproc zip zlib1g-dev zram-config \
    && curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo \
    && chmod a+rx /usr/local/bin/repo \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ENV TZ=Asia/Kolkata
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

VOLUME ["/tmp/ccache", "/tmp/rom"]
ENTRYPOINT ["/bin/bash"]
