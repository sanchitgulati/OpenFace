# ==================== Building Model Layer ===========================
# This is a little trick to improve caching and minimize rebuild time
# and bandwidth. Note that RUN commands only cache-miss if the prior layers
# miss, or the dockerfile changes prior to this step.
# To update these patch files, be sure to run build with --no-cache
FROM alpine as model_data
RUN apk --no-cache --update-cache add wget
WORKDIR /data/patch_experts

RUN wget -q https://www.dropbox.com/s/7na5qsjzz8yfoer/cen_patches_0.25_of.dat &&\
    wget -q https://www.dropbox.com/s/k7bj804cyiu474t/cen_patches_0.35_of.dat &&\
    wget -q https://www.dropbox.com/s/ixt4vkbmxgab1iu/cen_patches_0.50_of.dat &&\
    wget -q https://www.dropbox.com/s/2t5t1sdpshzfhpj/cen_patches_1.00_of.dat

## ==================== Install Ubuntu Base libs ===========================
## This will be our base image for OpenFace, and also the base for the compiler
## image. We only need packages which are linked

FROM ubuntu:22.10 as ubuntu_base

LABEL maintainer="Sanchit Gulati <sanchit.gulati@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive

# todo: minimize this even more
RUN apt-get update -qq &&\
    apt-get install -qq curl &&\
    apt-get install -qq --no-install-recommends \
        libopenblas-dev liblapack-dev \
        libavcodec-dev libavformat-dev libswscale-dev \
        libtbb2 libtbb-dev libjpeg-dev \
        libpng-dev libtiff-dev &&\
    rm -rf /var/lib/apt/lists/*

## ==================== Build-time dependency libs ======================
## This will build and install opencv and dlib into an additional dummy
## directory, /root/diff, so we can later copy in these artifacts,
## minimizing docker layer size
## Protip: ninja is faster than `make -j` and less likely to lock up system
FROM ubuntu_base as cv_deps

WORKDIR /root/build-dep
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && apt-get install -qq -y \
        cmake ninja-build pkg-config build-essential checkinstall 

## ==================== dlib libopencv openblas  ===========================

RUN apt-get install -qq -y build-essential cmake git pkg-config 
RUN apt-get install -qq -y libopenblas-dev
RUN apt-get install -qq -y libdlib-dev
RUN apt-get install -qq -y libopencv-dev


## ==================== Installing Python ===========================
# Update the package index and install Python 3
RUN apt-get update && \
    apt-get install -qq -y python3 python3-pip
# Set Python 3 as the default version
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

RUN pip3 install --upgrade pip
RUN pip3 install numpy pandas matplotlib seaborn scikit-learn tensorflow keras torch opencv-contrib-python dlib mediapipe


## ==================== Debuggin Tools ===========================

Run apt-get install -qq -y vim
Run apt-get install -qq -y htop

## ==================== Building OpenFace ===========================
FROM cv_deps as openface
WORKDIR /root/openface

COPY . /root/openface

COPY --from=model_data /data/patch_experts/* \
    /root/openface/lib/local/LandmarkDetector/model/patch_experts/

RUN mkdir -p build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE -G Ninja .. && \
    ninja &&\
    ninja install

RUN apt-get update && apt-get install -y openssh-server
RUN useradd -m -d /home/dev -s /bin/bash dev
RUN echo "dev:root" | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN service ssh restart
EXPOSE 22