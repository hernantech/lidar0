FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 AS builder

# Set environment variables for non-interactive installation and CUDA setup
ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# First, install all required dependencies including CUDA tools
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    gnupg2 \
    software-properties-common \
    cuda-command-line-tools-11-8 \
    cuda-compiler-11-8 \
    cuda-minimal-build-11-8 \
    cuda-nvcc-11-8 \
    cuda-cupti-11-8 \
    cuda-nvprune-11-8 \
    && rm -rf /var/lib/apt/lists/*

# Install TensorRT
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    apt-get update && \
    apt-get install -y tensorrt && \
    rm -rf /var/lib/apt/lists/*

# Verify CUDA installation
RUN nvcc --version

# Build PointPillars with explicit CUDA configuration
WORKDIR /opt
RUN git clone --depth 1 https://github.com/NVIDIA-AI-IOT/CUDA-PointPillars.git && \
    cd CUDA-PointPillars && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} \
          -DCMAKE_CUDA_COMPILER=${CUDA_HOME}/bin/nvcc \
          -DCUDA_CUDA_LIBRARY=${CUDA_HOME}/lib64/stubs/libcuda.so \
          .. && \
    make -j$(nproc)

# Create smaller runtime image
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04
ENV NVIDIA_VISIBLE_DEVICES=all

# Copy only necessary files from builder
COPY --from=builder /opt/CUDA-PointPillars/build /opt/pointpillars
COPY --from=builder /usr/lib/x86_64-linux-gnu/libnvinfer* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libnvonnxparser* /usr/lib/x86_64-linux-gnu/

WORKDIR /workspace
