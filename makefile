ifeq "$(shell git status --porcelain=v1 2>/dev/null)" "" 
GIT_REVISION=$(shell git rev-parse --short HEAD)
BUILD_TIME=$(shell git show -s --format=%ci HEAD)
DOCKER_TAG=-t siacentral/sia-lite-wallet-web:latest
else
GIT_REVISION="$(shell git rev-parse --short HEAD)-devel"
BUILD_TIME=$(shell date)
endif

lint:
	GOOS=js GOARCH=wasm golangci-lint run
	npm run lint -- --fix

clean:
	rm -rf dist public/sia/wasm_exec.js

install-dependencies:
	npm i

build-wasm:
	mkdir -p public/sia
	cp "${shell go env GOROOT}/misc/wasm/wasm_exec.js" public/sia/wasm_exec.js
	GOARCH=wasm GOOS=js go build -trimpath -ldflags "-X 'github.com/siacentral/sia-lite-wallet-web/wasm/build.gitRevision=${GIT_REVISION}' -X 'github.com/siacentral/sia-lite-wallet-web/wasm/build.buildTime=${BUILD_TIME}' -buildid='' -s -w -extldflags '-static'" -o src/sia/sia.wasm wasm/main.go

build-vue:
	npm run build

run: clean install-dependencies build-wasm
	npm run serve

build: clean install-dependencies build-wasm build-vue

docker: clean
	docker build ${DOCKER_TAG} -t siacentral/sia-lite-wallet-web:sia -t siacentral/sia-lite-wallet-web:$(GIT_REVISION) .