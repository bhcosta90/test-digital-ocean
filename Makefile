build:
	docker build -t project-test --target prod .

make deploy:
	docker build -t project-test --target deploy .docker run -d \
		--name app \
		--network preview-net \
		--add-host=host.docker.internal:host-gateway \
		project-test