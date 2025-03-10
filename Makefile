.PHONY: install_deps install_script install_systemd install_config uninstall run install venv

# Set variables
SCRIPT_PATH = /usr/local/bin/gandi-dns-update.py
SERVICE_PATH = /etc/systemd/system/gandi-dns-update.service
TIMER_PATH = /etc/systemd/system/gandi-dns-update.timer
CONFIG_PATH = ~/.config/gandi-dns-update/config.toml
USER = $(shell whoami)
VENV_PATH = $(shell echo $$HOME)/.local/gandi-dns-update-venv
PYTHON = $(VENV_PATH)/bin/python
PIP = $(VENV_PATH)/bin/pip
WORKING_DIR = $(shell pwd)

# Default target (requires sudo for system-wide installs)
install: no_sudo install_deps install_script install_systemd install_config

no_sudo:
	@if [ -n "$$SUDO_USER" ]; then \
		echo "Do not run with sudo."; \
		exit 1; \
	fi

# Install the Python dependencies in a virtual environment
install_deps: venv
	@echo "Installing Python dependencies..."
	$(PIP) install -r requirements.txt

# Install the script (requires sudo)
install_script:
	@echo "Installing the script..."
	@sudo cp gandi-dns-update.py $(SCRIPT_PATH)
	@sudo chmod +x $(SCRIPT_PATH)

# Install systemd service and timer (requires sudo)
install_systemd:
	@echo "Installing systemd service and timer..."
	@sudo sed \
		-e "s|@PYTHON@|$(PYTHON)|g" \
		-e "s|@SCRIPT_PATH@|$(SCRIPT_PATH)|g" \
		-e "s|@USER@|$(USER)|g" \
		-e "s|@VENV_PATH@|$(VENV_PATH)|g" \
		-e "s|@WORKING_DIR@|$(WORKING_DIR)|g" \
		systemd/gandi-dns-update.service | sudo tee $(SERVICE_PATH) > /dev/null
	@sudo sed \
		-e "s|@PYTHON@|$(PYTHON)|g" \
		-e "s|@SCRIPT_PATH@|$(SCRIPT_PATH)|g" \
		systemd/gandi-dns-update.timer | sudo tee $(TIMER_PATH) > /dev/null
	@sudo systemctl daemon-reload
	@sudo systemctl enable gandi-dns-update.timer
	@sudo systemctl start gandi-dns-update.timer

# Install configuration (does not require sudo)
install_config:
	@echo "Installing default config file..."
	@if [ ! -f $(CONFIG_PATH) ]; then \
		mkdir -p ~/.config/gandi-dns-update && \
		cp systemd/config.toml $(CONFIG_PATH); \
	fi

# Uninstall the script and systemd configuration (requires sudo)
uninstall:
	@echo "Uninstalling the script and systemd configuration..."
	@sudo rm -f $(SCRIPT_PATH)
	@sudo rm -f $(SERVICE_PATH)
	@sudo rm -f $(TIMER_PATH)
	@sudo systemctl daemon-reload
	@sudo systemctl stop gandi-dns-update.timer
	@sudo systemctl disable gandi-dns-update.timer
	@rm -rf ~/.config/gandi-dns-update
	@rm -rf $(VENV_PATH)

# Create a virtual environment (does not require sudo)
venv:
	@echo "Creating virtual environment..."
	@python3 -m venv $(VENV_PATH)
	@echo "Virtual environment created at $(VENV_PATH)"

# Run the script manually (for testing purposes, uses virtualenv Python)
run:
	@$(PYTHON) $(SCRIPT_PATH)
