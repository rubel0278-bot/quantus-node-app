.PHONY: all install update status logs clean uninstall test

INSTALL_DIR=/opt/quantus-node
SERVICE=quantus-node

all: install

install:
	@echo "Installing Quantus Node..."
	chmod +x install.sh
	./install.sh --full

update:
	@echo "Updating Quantus Node..."
	$(INSTALL_DIR)/update --update

status:
	$(INSTALL_DIR)/update --status

logs:
	journalctl -u $(SERVICE) -f

clean:
	rm -rf $(INSTALL_DIR)/data/chains/*

uninstall:
	$(INSTALL_DIR)/update --uninstall

test:
	@echo "Running tests..."
	@echo "Config file exists: $(shell test -f config && echo yes || echo no)"
	@echo "Install script exists: $(shell test -f install.sh && echo yes || echo no)"
	@echo "Update script exists: $(shell test -f update && echo yes || echo no)"
	@echo "Service file exists: $(shell test -f service/quantus-node.service && echo yes || echo no)"
