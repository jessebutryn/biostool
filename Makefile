# Convenience make targets for developing and testing inside Docker

.PHONY: build up shell test

build:
	docker build -t bios-tool:dev .

up:
	docker-compose up --build

shell:
	docker run --rm -it -v $(PWD):/opt/bios-tool bios-tool:dev /bin/bash

test:
	docker run --rm -v $(PWD):/opt/bios-tool bios-tool:dev python3 -c "import sys; sys.path.insert(0,'/opt/bios-tool'); import bios_tool.cli as m; assert m.list_devices()==[]; print('OK')"
