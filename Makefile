IMAGE = joshuaspence/uxg-setup
SHELL = /bin/bash

check_defined = $(if $(value $1),$(value $1),$(error Undefined $1$(if $(value @), required by target `$@')))

.PHONY: image
image: cache/uxg-setup.tar
	docker load --input $^
	$(eval VERSION = $(shell docker image inspect --format '{{ .Config.Labels.version }}' localhost/uxg-setup))
	docker tag localhost/uxg-setup "$(IMAGE):$(VERSION)"

.PHONY: build
build: image
	$(eval VERSION = $(shell docker image inspect --format '{{ .Config.Labels.version }}' localhost/uxg-setup))
	docker build --build-arg VERSION=$(VERSION) --tag "$(IMAGE):$(VERSION)-1" .

.PHONY: push
push:
	docker push --all-tags "$(IMAGE)"

.PHONY: images
images:
	docker image ls "$(IMAGE)"

cache/uxg-setup.tar:
	mkdir --parents $(@D)
	ssh -o LogLevel=quiet $(call check_defined,DEVICE) $$'test -f /tmp/conmon || { curl --fail --location --no-progress-meter --output /tmp/conmon https://github.com/boostchicken-dev/udm-utilities/raw/master/podman-update/bin/conmon-2.0.29 && chmod +x /tmp/conmon; }'
	ssh -o LogLevel=quiet $(call check_defined,DEVICE) $$'test -f /tmp/podman || { curl --fail --location --no-progress-meter --output /tmp/podman https://github.com/boostchicken-dev/udm-utilities/raw/master/podman-update/bin/podman-3.3.0 && chmod +x /tmp/podman; }'
	ssh -o LogLevel=quiet $(call check_defined,DEVICE) /tmp/podman --conmon /tmp/conmon save localhost/uxg-setup > $@
