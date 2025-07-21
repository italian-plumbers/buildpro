FROM ghcr.io/italian-plumbers/rockylinux:8.9
LABEL maintainer="italian-plumbers"
LABEL org.opencontainers.image.source=https://github.com/italian-plumbers/buildpro
SHELL ["/bin/bash", "-c"]
USER 0
VOLUME /bpvol
ENV DNF=dnf
ENV DNFOPT="--setopt=tsflags=nodocs --setopt=install_weak_deps=0"
# initial dnf update
RUN ${DNF} -y update \
  && ${DNF} clean all
# dnf repositories
RUN ${DNF} -y update \
  && ${DNF} clean all \
  && ${DNF} -y install ${DNFOPT} \
     coreutils-common \
     git \
     graphviz \
     gtk3-devel \
     mesa-libGL-devel \
     mesa-libGLU-devel \
     python39-devel \
     redhat-lsb-core \
     sudo \
     vim \
     wget \
     xz \
  && ${DNF} clean all \
  && alternatives --set python3 $(command -v python3.9)
# gcc-toolset
RUN ${DNF} -y update \
  && ${DNF} clean all \
  && ${DNF} -y install ${DNFOPT} \
     gcc-toolset-9-binutils \
     gcc-toolset-9-gcc \
     gcc-toolset-9-gcc-c++ \
     gcc-toolset-9-gdb \
     gcc-toolset-9-libasan-devel \
     gcc-toolset-9-libtsan-devel \
     gcc-toolset-9-make \
  && ${DNF} clean all
# ninja-build
RUN ${DNF} -y update \
  && ${DNF} -y install --enablerepo=powertools ${DNFOPT} \
     ninja-build \
  && ${DNF} clean all
# cmake
RUN export CMK_VER=3.31.7 \
  && export CMK_DL=releases/download/v${CMK_VER}/cmake-${CMK_VER}-$(uname -s)-$(uname -m).tar.gz \
  && wget -qO- "https://github.com/Kitware/CMake/${CMK_DL}" \
  | tar --strip-components=1 -xz -C /usr/local/ \
  && unset CMK_DL && unset CMK_VER
# copy from local into image
COPY scripts/ /usr/local/bpbin
COPY git-prompt.sh /etc/profile.d/
# environment: gcc version, enable scl binaries
ENV GCC_VER=gcc921 \
    PATH="/opt/rh/gcc-toolset-9/root/usr/bin:${PATH}" \
    EXTERN_DIR=/opt/extern \
    BASH_ENV="/usr/local/bpbin/scl_enable" \
    ENV="/usr/local/bpbin/scl_enable" \
    PROMPT_COMMAND=". /usr/local/bpbin/scl_enable"
ENTRYPOINT ["/bin/bash", "/usr/local/bpbin/entry.sh"]
