build:
	docker build -f DockerfileBuild -t bhcosta90/test-digital-ocean:0 --target build .
	docker push bhcosta90/test-digital-ocean:0