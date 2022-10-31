# Due to bandwidth limitation, we need to keep the base image into our
# Artifactory Docker Registry. Because we have more than one registry,
# we need to set during build time which Artifactory Docker Registry to use.
ARG DOCKER_REGISTRY
FROM ${DOCKER_REGISTRY}/ubuntu:focal

# install packages from official Ubuntu repo
ENV DEBIAN_FRONTEND=noninteractive
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        bc \
        build-essential \
        curl \
        dos2unix \
        git \
        lib32stdc++6 \
        mscgen \
        p7zip-full \
        python3 \
        python3-pip \
        tar \
        unzip \
        wget \
        libxml2-utils \
        zip && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    rm -rf /var/lib/apt/lists/*

# Create build ARGs for installer files & versions
ARG GCC=gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2

# Including dependency folder
ARG DEPENDENCIESFOLDER=dependenciesFiles
ARG TOOLS_PATH=/opt
ARG INSTALLER_PATH=/tmp/dependenciesFiles
RUN mkdir -p ${INSTALLER_PATH}
COPY dependenciesFiles/${GCC} ${INSTALLER_PATH}/${GCC}
COPY dependenciesFiles/buildtools ${TOOLS_PATH}/buildtools

# install & setup gcc
RUN mkdir -p ${TOOLS_PATH}
WORKDIR ${TOOLS_PATH}
RUN tar -xvf ${INSTALLER_PATH}/${GCC}
ENV PATH=${PATH}:${TOOLS_PATH}/gcc-arm-none-eabi-10-2020-q4-major/bin
ENV CI_GCC_TOOLCHAIN_ROOT=${TOOLS_PATH}/gcc-arm-none-eabi-10-2020-q4-major/bin
WORKDIR /

# install CMSIS-Toolbox
ENV CMSIS_PACK_ROOT=${HOME}/.packs
RUN wget https://github.com/Open-CMSIS-Pack/cmsis-toolbox/releases/download/1.2.0/cmsis-toolbox-linux64.tar.gz && \
    tar -xvf cmsis-toolbox-linux64.tar.gz && \
    sed -i -e 's/set(TOOLCHAIN_ROOT "[^"]*")/set(TOOLCHAIN_ROOT "")/' cmsis-toolbox-linux64/etc/AC5.5.6.7.cmake && \
    sed -i -e 's/set(TOOLCHAIN_ROOT "[^"]*")/set(TOOLCHAIN_ROOT "")/' cmsis-toolbox-linux64/etc/AC6.6.18.0.cmake && \
    sed -i -e 's/set(TOOLCHAIN_ROOT "[^"]*")/set(TOOLCHAIN_ROOT "${CI_GCC_TOOLCHAIN_ROOT}")/' cmsis-toolbox-linux64/etc/GCC.11.2.1.cmake && \
    sed -i -e 's/set(TOOLCHAIN_ROOT "[^"]*")/set(TOOLCHAIN_ROOT "")/' cmsis-toolbox-linux64/etc/IAR.8.50.6.cmake && \
    mv cmsis-toolbox-linux64 ${TOOLS_PATH}/cmsis-toolbox && \
    rm -f cmsis-toolbox-linux64.tar.gz
ENV PATH=${PATH}:${TOOLS_PATH}/cmsis-toolbox/bin

# install Python requirements
COPY requirements.txt ${INSTALLER_PATH}/
# hadolint ignore=DL3013
RUN python3 -m pip install -U --no-cache-dir pip && \
    python3 -m pip install -U --no-cache-dir -r ${INSTALLER_PATH}/requirements.txt

# install buildtools
RUN python3 -m pip install --no-cache-dir -r ${TOOLS_PATH}/buildtools/requirements.txt
COPY rtebuild /root/.rtebuild
ENV PATH=${PATH}:${TOOLS_PATH}/buildtools

# remove dependency folder
RUN rm -rf ${INSTALLER_PATH}

CMD ["bash"]