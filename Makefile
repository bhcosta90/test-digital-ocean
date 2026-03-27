build:
	docker build -t bhcosta90/laravel-base:php-apache-8.4 --target base .
	docker push bhcosta90/laravel-base:php-apache-8.4