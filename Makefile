build:
	docker build -f DockerfileBuild -t bhcosta90/test-digital-ocean:base .
	docker push bhcosta90/test-digital-ocean:base