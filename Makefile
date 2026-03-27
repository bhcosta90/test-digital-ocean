build:
	docker build -t project-test --target prod .

deploy:
	@build
	docker run -d \
		--name app \
		--network preview-net \
		--add-host=host.docker.internal:host-gateway \
		project-test