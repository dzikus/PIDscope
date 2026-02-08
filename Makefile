PREFIX ?= /usr/local
INSTALL_DIR = $(PREFIX)/share/pidtoolbox
BIN_DIR = $(PREFIX)/bin
OCTAVE ?= octave

.PHONY: run install install-deps fetch-blackbox test clean

run:
	$(OCTAVE) --gui --persist --eval "cd('$(CURDIR)'); PIDtoolbox"

install-deps:
	@echo "Installing Octave and required packages..."
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get install -y octave octave-signal octave-statistics octave-control octave-image build-essential; \
	elif command -v dnf >/dev/null 2>&1; then \
		sudo dnf install -y octave octave-signal octave-statistics octave-control octave-image gcc make; \
	elif command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S --noconfirm octave base-devel; \
	else \
		echo "Unknown package manager. Install octave and a C compiler manually."; exit 1; \
	fi

fetch-blackbox: blackbox_decode blackbox_decode_INAV

blackbox_decode:
	@echo "Building blackbox_decode (betaflight)..."
	@rm -rf /tmp/bf-blackbox-tools
	git clone --depth 1 https://github.com/betaflight/blackbox-tools.git /tmp/bf-blackbox-tools
	make -C /tmp/bf-blackbox-tools obj/blackbox_decode
	cp /tmp/bf-blackbox-tools/obj/blackbox_decode .
	chmod +x blackbox_decode
	rm -rf /tmp/bf-blackbox-tools
	@echo "blackbox_decode ready."

blackbox_decode_INAV:
	@echo "Building blackbox_decode_INAV (inav)..."
	@rm -rf /tmp/inav-blackbox-tools
	git clone --depth 1 https://github.com/iNavFlight/blackbox-tools.git /tmp/inav-blackbox-tools
	make -C /tmp/inav-blackbox-tools obj/blackbox_decode
	cp /tmp/inav-blackbox-tools/obj/blackbox_decode blackbox_decode_INAV
	chmod +x blackbox_decode_INAV
	rm -rf /tmp/inav-blackbox-tools
	@echo "blackbox_decode_INAV ready."

install: fetch-blackbox
	install -d $(INSTALL_DIR)
	install -d $(BIN_DIR)
	cp -r *.m compat/ blackbox_decode blackbox_decode_INAV $(INSTALL_DIR)/
	@printf '#!/bin/sh\nexec $(OCTAVE) --gui --eval "cd(\\\"$(INSTALL_DIR)\\\"); PIDtoolbox"\n' > $(BIN_DIR)/pidtoolbox
	chmod +x $(BIN_DIR)/pidtoolbox
	@echo "Installed. Run with: pidtoolbox"

test:
	$(OCTAVE) --no-gui --eval "addpath('compat'); addpath('tests'); run_tests"

clean:
	rm -f blackbox_decode blackbox_decode_INAV
	rm -f *.csv *.bbl *.bfl
