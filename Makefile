build:
	docker build -f DockerfileBuild -t bhcosta90/laravel-base:test-digital-ocean --target build .
	docker push bhcosta90/laravel-base:test-digital-ocean