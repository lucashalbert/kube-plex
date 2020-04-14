#!/bin/bash

kube_plex_ver=0.0.1
build_date=${build_date:-$(date +"%Y%m%dT%H%M%S")}

for docker_arch in amd64 arm32v6 arm64v8; do
    case ${docker_arch} in
        amd64   ) image_arch="amd64" go_arch="amd64" ;;
        arm32v6 ) image_arch="arm"   go_arch="arm"   ;;
        arm64v8 ) image_arch="arm64" go_arch="arm64" ;;
    esac
    cp Dockerfile.cross Dockerfile.${docker_arch}
    sed -i "s|__BASEIMAGE_ARCH__|${docker_arch}|g" Dockerfile.${docker_arch}
    sed -i "s|__BUILD_DATE__|${build_date}|g" Dockerfile.${docker_arch}
    sed -i "s|__GO_ARCH__|${go_arch}|g" Dockerfile.${docker_arch}


    # Build
    if [ "$EUID" -ne 0 ]; then
        # Build kube-plex
        sudo docker run -v $(pwd)/build:/go/build -e GOOS=linux -e GOARCH=${go_arch} golang /bin/bash -c "go get -d -v -u github.com/lucashalbert/kube-plex && go build -o build/kube-plex-linux-${go_arch} github.com/lucashalbert/kube-plex"
	
	# Build container
        sudo docker build -f Dockerfile.${docker_arch} -t lucashalbert/kube-plex:${docker_arch}-${kube_plex_ver} .
        sudo docker push lucashalbert/kube-plex:${docker_arch}-${kube_plex_ver}
    else
        # Build kube-plex
        docker run -v $(pwd)/build:/go/build -e GOOS=linux -e GOARCH=${go_arch} golang /bin/bash -c "go get -d -v -u github.com/lucashalbert/kube-plex && go build -o build/kube-plex-linux-${go_arch} github.com/lucashalbert/kube-plex"
	
	# Build container
        docker build -f Dockerfile.${docker_arch} -t lucashalbert/kube-plex:${docker_arch}-${kube_plex_ver} .
        docker push lucashalbert/kube-plex:${docker_arch}-${kube_plex_ver}

        # Create and annotate arch/ver docker manifest
        DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create lucashalbert/kube-plex:${docker_arch}-${kube_plex_ver} lucashalbert/kube-plex:${docker_arch}-${kube_plex_ver}
        DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate lucashalbert/kube-plex:${docker_arch}-${kube_plex_ver} lucashalbert/kube-plex:${docker_arch}-${kube_plex_ver} --os linux --arch ${image_arch}
        DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push lucashalbert/kube-plex:${docker_arch}-${kube_plex_ver}

    fi
done
