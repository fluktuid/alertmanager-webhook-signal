REGISTRY=registry.gitlab.com
IMAGE=schlauerlauer/alertmanager-webhook-signal:latest
#RUNTIME=docker
RUNTIME=podman
NAME=alertmanager-signal
PORT=10000

# CONTAINER
pull:
	$(RUNTIME) pull $(REGISTRY)/$(IMAGE)
run:
	$(RUNTIME) run -d --name $(NAME) \
		-v $(CURDIR)/config.yaml:/root/config.yaml:Z \
		-p $(PORT):10000 \
		$(REGISTRY)/$(IMAGE)
logs:
	$(RUNTIME) logs -f --tail 100 $(NAME)
stop:
	$(RUNTIME) stop $(NAME)
rm:
	$(RUNTIME) container rm $(NAME)
rmi:
	$(RUNTIME) rmi $(REGISTRY)/$(IMAGE)
rebuild: stop rm run
restart: stop start
start:
	$(RUNTIME) start $(NAME)

# BUILD
build-all: go-main go-signal build-image
go-main:
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app ./
go-signal:
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o signal ./tests
build-image:
	$(RUNTIME) build -t $(REGISTRY)/$(IMAGE) -f Containerfile .

# TEST
test:
	curl -i -X POST -H "Content-Type: application/json" -d "$(CURDIR)/tests/alert.json" http://127.0.0.1:10000/api/v1/alert