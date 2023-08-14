all: lint

.PHONY: lint
lint:
	@go build -o ./.bin/elint ./.elint/cmd/elint
	@./.bin/elint