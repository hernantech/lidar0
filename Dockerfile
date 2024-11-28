FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libboost-all-dev \
    libeigen3-dev \
    libpcl-dev \
    libprotobuf-dev \
    protobuf-compiler \
    wget \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN wget https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.6.1/local_repo/nv-tensorrt-local-repo-ubuntu2204-8.6.1-cuda-11.8_1.0-1_amd64.deb && \
    dpkg -i nv-tensorrt-local-repo-ubuntu2204-8.6.1-cuda-11.8_1.0-1_amd64.deb && \
    cp /var/nv-tensorrt-local-repo-ubuntu2204-8.6.1-cuda-11.8/nv-tensorrt-local-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update && \
    apt-get install -y tensorrt

WORKDIR /opt
RUN git clone https://github.com/NVIDIA-AI-IOT/CUDA-PointPillars.git && \
    cd CUDA-PointPillars && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DTENSORRT_ROOT=/usr/local/tensorrt \
          -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
          .. && \
    make -j$(nproc)

ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/tensorrt/lib:${LD_LIBRARY_PATH}"

FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04
COPY --from=builder /opt/CUDA-PointPillars/build /opt/pointpillars
COPY --from=builder /usr/local/tensorrt /usr/local/tensorrt

WORKDIR /workspace
