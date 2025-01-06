# EcoCAR Y3 Lidar Detection

Real-time LiDAR point cloud detection system using NVIDIA's CUDA-PointPillars, optimized for autonomous vehicle applications.

## System Requirements
- Ubuntu (20 and higher, other distros likely supported, just check nvidia's support matrix for container toolkit requirements)
- NVIDIA GPU with compute capability 5.2 or higher (Tesla M60 or RTX A5000 supported...[email me if you need something else supported](mailto:ahern669@ucr.edu))
- NVIDIA Container Toolkit
- Docker and Docker Compose
- At least 8GB GPU memory recommended

## Features

- High-performance LiDAR point cloud detection (60-100 FPS target)
- CUDA-accelerated processing
- Containerized development environment
- TensorRT 8.6.3 optimization
- Support for both dev and prod environments

## Architecture

Built on NVIDIA's CUDA-PointPillars with the following optimizations:
- C++17 standard implementation
- CUDA architecture support for:
  - Tesla M60 (sm_52)
  - RTX A5000 (sm_86)
- TensorRT integration for inference acceleration
- WAY faster than python-based implementations

## Setup

0. Either use the script in "Fresh install scripts" or install manually from below (still check the script for the list of requirements, as it can change and installdeps.sh has the latest list)

1. Install NVIDIA Container Toolkit (this can get tricky sometimes):
   ```bash
   curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
   curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
     sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
     sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
   sudo apt-get update
   sudo apt-get install -y nvidia-container-toolkit
   ```

2. Clone repository:
   ```bash
   git clone https://github.com/hernantech/lidar0
   cd ecocar-y3-lidar
   ```

3. Build the container:
   ```bash
   docker compose build
   ```

4. Start development environment:
   ```bash
   docker compose run --rm pointpillars bash
   ```

## Development Workflow

1. Write code in the `./src` directory
2. Build changes:
   ```bash
   docker compose build
   ```
3. Run tests:
   ```bash
   docker compose run --rm pointpillars ./tests/run_tests.sh
   ```

## Container Details

The project uses a multi-stage build process:
- Base image: `nvcr.io/nvidia/tensorrt:24.03-py3`
    - the `py3-igpu` version is for jetsons and includes a lot of unnecessary BS for the AUTERA
- Development dependencies included in builder stage (I should probably point it to my fork... I'll do that later)
- Runtime image optimized for deployment
- Automatic GPU detection and utilization
- Shared volume mounting for data processing

## Data Management
- (optionally, we can route pcaps to udp outside of the container and then use shell scripts to eat/process the udp packets within the container)
- Place input data in the `./data` directory
- Data directory is mounted to `/workspace/data` in the container
- Data directory is git-ignored to prevent large files in the repo

## Performance Considerations

- Target performance: 60-100 FPS
- Optimized CUDA flags for both debug and release builds
- Memory limits configured in Docker Compose
- GPU memory management optimized through TensorRT

## Testing

- Test suite available in `./tests`
- Run tests through Docker Compose to ensure consistent environment
- Automated testing environment matches production configuration

## Deployment

- Production-ready container available after build
- Supports deployment to Autera system
- Runtime container includes only necessary artifacts
- Optimized for minimal image size and maximum performance

## Contributing

1. Fork the repository
2. Create a feature branch `username/feature_name`
3. Make changes in `./src`
4. Run tests to verify changes
5. Submit pull request
