build:
	docker network create preview-net
	docker build -t project-test --target prod .

deploy:
	make build
	docker run -d \
		--name project-test \
		--network preview-net \
		--add-host=host.docker.internal:host-gateway \
		project-test