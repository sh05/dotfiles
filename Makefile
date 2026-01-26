# Nix-based dotfiles management
# Usage:
#   make bootstrap NIXNAME=sh05MacMini  # Initial setup
#   make switch                          # Apply changes
#   make update                          # Update flake and apply

HOST_FILE := $(HOME)/.config/nix/host
NIXNAME ?= $(shell cat $(HOST_FILE) 2>/dev/null)

.DEFAULT_GOAL := help

.PHONY: bootstrap switch update rollback check gc clean help

bootstrap: ## Initial Nix-darwin setup (requires NIXNAME)
	@if [ -z "$(NIXNAME)" ]; then \
		echo "Error: NIXNAME is required. Usage: make bootstrap NIXNAME=<hostname>"; \
		exit 1; \
	fi
	@echo "==> Bootstrapping nix-darwin for $(NIXNAME)..."
	nix run nix-darwin -- switch --flake '.#$(NIXNAME)'
	@mkdir -p $(dir $(HOST_FILE))
	@echo "$(NIXNAME)" > $(HOST_FILE)
	@echo "==> Bootstrap complete! Run 'make switch' for future updates."

switch: ## Apply configuration changes
	@if [ -z "$(NIXNAME)" ]; then \
		echo "Error: NIXNAME not set. Run 'make bootstrap NIXNAME=<hostname>' first or set in $(HOST_FILE)"; \
		exit 1; \
	fi
	@echo "==> Switching to configuration for $(NIXNAME)..."
	darwin-rebuild switch --flake '.#$(NIXNAME)'

update: ## Update flake inputs and apply
	@if [ -z "$(NIXNAME)" ]; then \
		echo "Error: NIXNAME not set. Run 'make bootstrap NIXNAME=<hostname>' first or set in $(HOST_FILE)"; \
		exit 1; \
	fi
	@echo "==> Updating flake inputs..."
	nix flake update
	@echo "==> Applying updated configuration..."
	darwin-rebuild switch --flake '.#$(NIXNAME)'

rollback: ## Rollback to previous generation
	@echo "==> Rolling back to previous generation..."
	darwin-rebuild switch --rollback

check: ## Check flake without applying
	@echo "==> Checking flake..."
	nix flake check

gc: ## Garbage collect old generations
	@echo "==> Running garbage collection..."
	nix-collect-garbage -d
	@echo "==> Optimizing Nix store..."
	nix store optimise

list-generations: ## List all generations
	darwin-rebuild --list-generations

switch-generation: ## Switch to specific generation (requires GEN=N)
	@if [ -z "$(GEN)" ]; then \
		echo "Error: GEN is required. Usage: make switch-generation GEN=<number>"; \
		exit 1; \
	fi
	darwin-rebuild switch --switch-generation $(GEN)

clean: ## Remove generated files (careful!)
	@echo "==> This will remove backup files created by home-manager"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	find $(HOME) -name "*.backup" -type f -delete 2>/dev/null || true

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
