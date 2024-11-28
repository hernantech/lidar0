# EcoCAR Y3 Lidar Detection

## Notes
* We're using containers to standardize dev env's
* Can also test locally (on my server) and push to the Autera
* Code will be C++ and CUDA
* Expected performance is at least 60fps, aiming for 100fps (low latency)

## Setup
1. Install nvidia-container-toolkit
2. Clone repository
3. Run: docker compose build
4. Start development: docker compose run --rm pointpillars bash

## Development Workflow 
1. Code in ./src
2. Build: docker compose build
3. Test: docker compose run --rm pointpillars ./tests/run_tests.sh
