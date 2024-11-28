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
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install TensorRT via apt
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:graphics-drivers && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/7fa2af80.pub && \
    apt-get update && \
    apt-get install -y tensorrt

WORKDIR /opt
RUN git clone https://github.com/NVIDIA-AI-IOT/CUDA-PointPillars.git && \
    cd CUDA-PointPillars && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
          .. && \
    make -j$(nproc)

ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"

FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04
COPY --from=builder /opt/CUDA-PointPillars/build /opt/pointpillars
COPY --from=builder /usr/lib/x86_64-linux-gnu/libnvinfer* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libcudnn* /usr/lib/x86_64-linux-gnu/

WORKDIR /workspace
