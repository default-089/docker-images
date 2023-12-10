# docker-images

## Docker Image Build and Push Script
This script facilitates the rebuilding and pushing of Docker images located in the same directory as the script. Each image directory should contain a bash script. The script can be executed with the following options:

### Usage:
```bash
./build.sh [OPTIONS]
```
### Options:
- **No options**:
Builds the Docker image without pushing.

- **-a:**
Builds the Docker image after building its parent image (if available).
Example: ./build.sh -a

- **-p:**
Pushes the Docker image(s) to the repository after building.
Example: ./build.sh -p

## Detailed Explanation:
### 1. Building the Image:
Execute the script without any options to build the Docker image:

```bash
./build.sh
```
### 2. Building with Parent Image:
Use the `-a` option to build the Docker image after building its parent image. This is applicable when the image has a parent-child relationship, such as `php-dev/8.1.0` depending on `php/8.1.0`:

```bash
./build.sh -a
```
### 3. Pushing the Image:
To push the Docker image(s) to the repository after building, use the -p option:

```bash
./build.sh -p
```
### Note:
- The script assumes that each image directory contains a bash script for building the Docker image.
- The `-a` option is not available for all images; it depends on the specific setup.
Feel free to customize the script and documentation based on your specific requirements.