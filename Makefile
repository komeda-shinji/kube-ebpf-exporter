RELEASE := $(shell git describe --tags --always --dirty=-dev | sed s'/^v//g')

RELEASES_DIR := release

RELEASE_AMD64_DIR := kube-ebpf-exporter-$(RELEASE)
RELEASE_AMD64_BINARY := $(RELEASES_DIR)/$(RELEASE_AMD64_DIR)/kube-ebpf-exporter

DOCKERFILE = Dockerfile.ubuntu

.PHONY: release-binaries dev

release-binaries:
	rm -rf $(RELEASES_DIR)/*
	mkdir -p $(RELEASES_DIR)/$(RELEASE_AMD64_DIR)
	docker build -t kube-ebpf-exporter-build -f $(DOCKERFILE) .
	docker run --rm --entrypoint cat kube-ebpf-exporter-build /root/go/bin/kube-ebpf-exporter > $(RELEASE_AMD64_BINARY)
	chmod +x $(RELEASE_AMD64_BINARY)
	cd $(RELEASES_DIR) && tar -czf $(RELEASE_AMD64_DIR).tar.gz $(RELEASE_AMD64_DIR)
	cd $(RELEASES_DIR) && shasum -a 256 *.tar.gz > sha256sums.txt
	[ $(DOCKERFILE) = "Dockerfile.ubuntu" ] || docker run --rm kube-ebpf-exporter-build sh -c "cd /bcc && tar cf - *.rpm" | tar xvf - -C $(RELEASES_DIR)

dev:
	 GOFLAGS="-mod=vendor" go build  -v ./cmd/kube-ebpf-exporter
