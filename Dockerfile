# WORK IN PROGRESS: DO NOT BUILD!
FROM alpine:edge as builder

ENV GIT https://github.com
ENV PKG_CONFIG_PATH /usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig
ENV QT 5_15_2
ENV QT_TAG v5.15.2
ENV QT_PREFIX /usr/local/desktop-app/Qt-5.15.2
ENV OPENSSL_VER 1_1_1
ENV OPENSSL_PREFIX /usr/local/desktop-app/openssl-1.1.1
ENV PATH ${PATH}:${QT_PREFIX}/bin
ENV Qt5_DIR ${QT_PREFIX}

# Notes: I attempt to look for compartible Alpine packages as much as possible.
# Some notable changes over here:
#   * samurai - ninja-compatible build tool written in C
#   * libudev-zero-dev - libudev replacement to use whatever device manager (development files)
#   * webkit2gtk-dev - same as webkit2gtk4-devel for CentOS users
#   * util-macros - same as xorg-x11-util-macros
#   * *-dev - same as *-devel for CentOS users
# TODO: Use built binaries fo GCC, among other stuff from https://github.com/just-containers/musl-cross-make
RUN apk add --no-cache git cmake meson samurai autoconf automake libtool \
	zlib-dev gtk+2.0-dev gtk+3.0-dev libdrm-dev fontconfig-dev \
	freetype-dev libx11 at-spi2-core-dev alsa-lib-dev \
	pulseaudio-dev mesa-gl mesa-egl mesa-dev libudev-zero-dev \
	webkitgtk-dev pkgconf bison yasm util-macros \
  make gcc gcc coreutils bash 
  
SHELL [ "bash", "-c" ]
RUN ln -s cmake /usr/bin/cmake3

ENV LibrariesPath /usr/src/Libraries
WORKDIR $LibrariesPath

FROM builder AS patches
RUN git clone $GIT/desktop-app/patches.git && cd patches && git checkout d58ce6b2b0

FROM builder AS extra-cmake-modules

RUN git clone -b v5.77.0 --depth=1 $GIT/KDE/extra-cmake-modules.git

WORKDIR extra-cmake-modules
RUN cmake -B build . -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF &&
    \ cmake3 --build build -j$(nproc) && 
    \ DESTDIR="$LibrariesPath/extra-cmake-modules-cache" cmake3 --install build

WORKDIR ..
RUN rm -rf extra-cmake-modules

FROM builder AS libffi
RUN git clone -b v3.3 --depth=1 $GIT/libffi/libffi.git

WORKDIR libffi
RUN ./autogen.sh
RUN ./configure --enable-static --disable-docs
RUN make -j$(nproc)
RUN make DESTDIR="$LibrariesPath/libffi-cache" install

WORKDIR ..
RUN rm -rf libffi
