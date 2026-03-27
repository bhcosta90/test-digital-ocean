IMAGE=project-test
CONTAINER=project-test
NETWORK=project-test

build:
	docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)
	docker build -t $(IMAGE) --target prod .

deploy: build
	-docker rm -f $(CONTAINER)
	docker run -d \
		--name $(CONTAINER) \
		--network $(NETWORK) \
		--add-host=host.docker.internal:host-gateway \
		$(IMAGE)