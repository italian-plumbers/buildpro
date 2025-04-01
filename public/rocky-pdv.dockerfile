ARG BPROTAG=latest
FROM ghcr.io/externpro/buildpro/rocky-pro:${BPROTAG}
LABEL maintainer="smanders"
LABEL org.opencontainers.image.source=https://github.com/externpro/buildpro
SHELL ["/bin/bash", "-c"]
USER 0
# https://rockylinux.pkgs.org https://rhel.pkgs.org
# AppStream, BaseOS Repositories
RUN dnf -y update \
  && dnf clean all \
  && dnf -y install --setopt=tsflags=nodocs \
     ghostscript `#LaTeX` \
     iproute \
     libSM-devel \
     perf \
     postgresql-devel \
     rpm-build \
     rpm-sign \
     Xvfb \
  && dnf clean all
# PowerTools, EPEL Repositories
RUN dnf -y update \
  && dnf clean all \
  && dnf -y install --setopt=tsflags=nodocs \
     dnf-plugins-core \
     epel-release \
  && dnf config-manager --set-enabled powertools \
  && dnf -y update \
  && dnf -y install --setopt=tsflags=nodocs \
     cppcheck \
     gperftools \
     xeyes \
  && dnf clean all
# lcov deps
RUN dnf -y update \
  && dnf clean all \
  && dnf -y install --setopt=tsflags=nodocs \
     perl-IO-Compress \
     perl-JSON-XS \
     perl-Module-Load-Conditional \
  && dnf clean all
# lcov
RUN export LCOV_VER=1.16 \
  && wget -qO- "https://github.com/linux-test-project/lcov/releases/download/v${LCOV_VER}/lcov-${LCOV_VER}.tar.gz" \
  | tar -xz -C /usr/local/src \
  && (cd /usr/local/src/lcov-${LCOV_VER} && make install > /dev/null) \
  && rm -rf /usr/local/src/lcov-${LCOV_VER} \
  && unset LCOV_VER
# git-lfs
RUN export LFS_VER=2.12.1 \
  && mkdir /usr/local/src/lfs \
  && wget -qO- "https://github.com/git-lfs/git-lfs/releases/download/v${LFS_VER}/git-lfs-linux-amd64-v${LFS_VER}.tar.gz" \
  | tar -xz -C /usr/local/src/lfs \
  && /usr/local/src/lfs/install.sh \
  && rm -rf /usr/local/src/lfs/ \
  && unset LFS_VER \
  && git lfs install --system
# doxygen
RUN export DXY_VER=1.8.13 \
  && wget -qO- --no-check-certificate \
  "https://downloads.sourceforge.net/project/doxygen/rel-${DXY_VER}/doxygen-${DXY_VER}.linux.bin.tar.gz" \
  | tar --no-same-owner -xz -C /usr/local/ \
  && mv /usr/local/doxygen-${DXY_VER}/bin/doxygen /usr/local/bin/ \
  && rm -rf /usr/local/doxygen-${DXY_VER}/ \
  && unset DXY_VER
# CUDA https://developer.nvidia.com/cuda-toolkit-archive
RUN export CUDA_VER=12-6 \
  && export CUDA_DL=https://developer.download.nvidia.com/compute/cuda/repos/rhel8/$(uname -m) \
  && dnf config-manager --add-repo ${CUDA_DL}/cuda-rhel8.repo \
  && dnf clean all \
  && wget -O /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA ${CUDA_DL}/D42D0685.pub \
  && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA \
  && dnf -y install \
     cuda-toolkit-${CUDA_VER} \
  && dnf clean all \
  && unset CUDA_DL && unset CUDA_VER
RUN dnf clean all \
  && dnf -y install \
  `# https://developer.nvidia.com/cudnn` \
     cudnn \
  `# https://developer.nvidia.com/cudss` \
     cudss \
  `# https://developer.nvidia.com/cutensor` \
     libcutensor2 \
     libcutensor-devel \
     libcutensor-doc \
  `# https://developer.nvidia.com/nvjpeg` \
     nvjpeg2k \
  && dnf clean all
ENV PATH=$PATH:/usr/local/cuda/bin
# externpro
ENV XP_VER=24.05
ENV EXTERNPRO_PATH=${EXTERN_DIR}/externpro-${XP_VER}-${GCC_VER}-64-Linux
RUN mkdir ${EXTERN_DIR} \
  && export XP_DL=releases/download/${XP_VER}/externpro-${XP_VER}-${GCC_VER}-64-$(uname -s).tar.xz \
  && wget -qO- "https://github.com/smanders/externpro/${XP_DL}" | tar --no-same-owner -xJ -C ${EXTERN_DIR} \
  && unset XP_DL
ENTRYPOINT ["/bin/bash", "/usr/local/bpbin/entry.sh"]
