docker-build:
	docker build -t zmk-build .

docker-run: docker-build
	docker run --rm -v "$${PWD}":/workspace zmk-build
