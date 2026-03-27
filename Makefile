build:
	docker build -f DockerfileBuild -t bhcosta90/laravel-base:php-nginx-8.4 --target build .
	docker push bhcosta90/laravel-base:php-nginx-8.4