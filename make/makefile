dockerfile: *.m4
	m4 Dockerfile.m4 > ../Dockerfile

build: dockerfile
	docker build --rm -t eugenmayer/apacheds ../
	rm ../Dockerfile
