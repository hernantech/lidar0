# Start with TensorRT 24.03 container which includes TensorRT 8.6.3
FROM nvcr.io/nvidia/tensorrt:24.03-py3 AS builder

# Set up environment variables for better reproducibility and convenience
# DEBIAN_FRONTEND prevents interactive prompts during package installation
# NVIDIA_VISIBLE_DEVICES ensures GPU access
# CUDA paths help tools find CUDA installations
ENV DEBIAN_FRONTEND=noninteractive \
    NVIDIA_VISIBLE_DEVICES=all \
    CUDA_HOME=/usr/local/cuda \
    PATH=${CUDA_HOME}/bin:${PATH} \
    LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Install dependencies needed for building PointPillars
# We group these installations to minimize Docker layers and cleanup apt cache
# to reduce image size
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
    && rm -rf /var/lib/apt/lists/*

# Set up the build directory
WORKDIR /opt

# Clone and build PointPillars
# We modify the CMake configuration to:
# 1. Use C++17 standard
# 2. Enable specific CUDA architectures (Tesla M60 - sm_52, RTX A5000 - sm_86)
# 3. Set appropriate compiler flags
RUN git clone --depth 1 https://github.com/NVIDIA-AI-IOT/CUDA-PointPillars.git && \
    cd CUDA-PointPillars && \
    # Configure C++ and CUDA flags for better compatibility and optimization
    sed -i 's/set(CMAKE_CXX_FLAGS_RELEASE.*/set(CMAKE_CXX_FLAGS_RELEASE "-std=c++17 -Wextra -Wall -Wno-missing-field-initializers -Wno-deprecated-declarations -O3")/' CMakeLists.txt && \
    sed -i 's/set(CMAKE_CXX_FLAGS_DEBUG.*/set(CMAKE_CXX_FLAGS_DEBUG "-std=c++17 -O0 -g")/' CMakeLists.txt && \
    sed -i 's/set(CUDA_NVCC_FLAGS_RELEASE.*/set(CUDA_NVCC_FLAGS_RELEASE "--std=c++17 -Xcompiler -std=c++17,-Wextra,-Wall,-Wno-deprecated-declarations,-O3")/' CMakeLists.txt && \
    sed -i 's/set(CUDA_NVCC_FLAGS_DEBUG.*/set(CUDA_NVCC_FLAGS_DEBUG "--std=c++17 -Xcompiler -std=c++17 -O0 -g")/' CMakeLists.txt && \
    # Set specific CUDA architectures for our target GPUs
    sed -i 's/-gencode arch=compute_$ENV{CUDASM},code=compute_$ENV{CUDASM}/-gencode=arch=compute_52,code=sm_52 -gencode=arch=compute_86,code=sm_86/' CMakeLists.txt && \
    # Create build directory and compile
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} \
          -DCUDA_CUDA_LIBRARY=${CUDA_HOME}/lib64/libcuda.so \
          -DCUDA_CUDART_LIBRARY=${CUDA_HOME}/lib64/libcudart.so \
          .. && \
    make -j$(nproc)

# Create the final runtime image
# We use the same base image to ensure TensorRT compatibility
FROM nvcr.io/nvidia/tensorrt:24.03-py3

# Maintain GPU access in runtime container
ENV NVIDIA_VISIBLE_DEVICES=all

# Copy only the necessary artifacts from the builder stage
# This reduces the final image size by excluding build tools and intermediate files
COPY --from=builder /opt/CUDA-PointPillars/build /opt/pointpillars

# Set up the working directory for user applications
WORKDIR /workspace

# Add runtime library path to ensure libraries can be found
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}
