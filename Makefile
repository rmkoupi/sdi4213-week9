# Week 9 individual exercise — one entry point for every milestone command.
#
# Lives in the root of the week 9 repo. Targets are in milestone order;
# `make help` lists them. Each wraps the exact command the handout names.
#
#   make test up ps     # M1  baseline: pytest + stack running      -> 1
#   make env            # M2  .env exists and git ignores it         -> 2
#   make scan-before    # M4  build :week9-before, Scout CVE scan    -> 4
#   make recs sbom      # M5  Scout recommendations / package list   -> 5
#   make after          # M7  build :week9-after, print its UID      -> 7
#   make policy         # M8  run the security.yml checks locally
#   make smoke          # app still works as the non-root user

PY       ?= 3.13
VENV     := .venv
BIN      := $(VENV)/bin
COMPOSE  ?= docker compose
BEFORE   ?= helpdesk:week9-before
AFTER    ?= helpdesk:week9-after
MASTERS  ?= $(HOME)/dev/oupidevops/scripts/week9
TERMSHOT ?= $(HOME)/dev/oupidevops/scripts/termshot/render.py
SHOTS    ?= docs/screenshots

.PHONY: help venv test env up ps logs down nuke scan-before recs sbom after policy smoke shots clean

help: ## list targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

# ---- Milestone 1: working baseline -----------------------------------------

# uv fetches Python 3.13 itself (the system python3 here is 3.14).
$(BIN)/python:
	uv venv --python $(PY) $(VENV)
	uv pip install -q --python $(BIN)/python -r requirements.txt

venv: $(BIN)/python ## create .venv and install requirements

test: venv ## run the automated tests (same invocation as the handout)
	$(BIN)/python -m pytest -v

up: env ## build and start web + db + adminer in the background
	$(COMPOSE) up -d --build

ps: ## show service state (db should say healthy)
	$(COMPOSE) ps

logs: ## web-service logs
	$(COMPOSE) logs web

down: ## stop and remove containers, keep the database volume
	$(COMPOSE) down

nuke: ## down -v: also delete the database volume (needs CONFIRM=yes)
	@test "$(CONFIRM)" = yes || { echo "Deletes the database volume. Then: make nuke CONFIRM=yes"; exit 1; }
	$(COMPOSE) down -v

# ---- Milestone 2: secrets ---------------------------------------------------

.env:
	cp .env.example .env
	@echo ">> .env created. Replace POSTGRES_PASSWORD before 'make up'."

env: .env ## create .env if missing; prove git ignores it (never prints it)
	git check-ignore -v .env
	git status --short
	@! grep -q '^POSTGRES_PASSWORD=replace-with' .env \
	  || { echo "POSTGRES_PASSWORD is still the placeholder"; exit 1; }

# ---- Milestones 4-5: Docker Scout (needs `docker login` first) --------------

# The "before" image must be the starter's root-running Dockerfile, so refuse
# once a USER line exists: building it later would scan the wrong thing.
scan-before: ## build the root-running baseline image and scan it for CVEs
	@! grep -q '^USER ' Dockerfile \
	  || { echo "Dockerfile is already hardened; build $(BEFORE) from the starter commit (git stash / git show main:Dockerfile)"; exit 1; }
	docker build -t $(BEFORE) .
	docker scout cves $(BEFORE)

recs: ## Scout base-image recommendations for the baseline image
	docker scout recommendations $(BEFORE)

sbom: ## Scout package inventory (the SBOM it matches CVEs against)
	docker scout sbom --format list $(BEFORE)

# ---- Milestones 6-7: hardened image -----------------------------------------

after: ## build the hardened image and print its runtime UID (must not be 0)
	@grep -q '^USER ' Dockerfile || { echo "no USER instruction in Dockerfile yet"; exit 1; }
	docker build -t $(AFTER) .
	docker run --rm --entrypoint id $(AFTER) -u

smoke: ## write + read a row through app/db.py inside the running web container
	$(COMPOSE) exec -T -e PYTHONPATH=/app/app web python - < $(MASTERS)/check_app.py

# ---- Milestone 8: the CI policy, run locally --------------------------------

# Same two checks as .github/workflows/security.yml, so a red PR can be
# reproduced without pushing.
policy: ## run the security workflow's checks on this machine
	@if git ls-files --error-unmatch .env > /dev/null 2>&1; then \
	  echo "FAIL: .env is tracked by Git"; exit 1; fi; echo "ok: .env is not tracked"
	docker build -q -t helpdesk:security .
	@USER_ID=$$(docker run --rm --entrypoint id helpdesk:security -u); \
	  echo "Container UID: $$USER_ID"; test "$$USER_ID" -ne 0 && echo "ok: not root"

# ---- Evidence ---------------------------------------------------------------

shots: ## render terminal evidence for screenshots 2 and 7 to PNG
	@test -f "$(TERMSHOT)" || { echo "no renderer at $(TERMSHOT)"; exit 1; }
	@mkdir -p $(SHOTS)
	{ echo "$$ git check-ignore -v .env"; git check-ignore -v .env; echo "$$ git status"; git -c color.status=always status; } \
	  | /usr/bin/python3 $(TERMSHOT) --out $(SHOTS)/02-env-ignored.png --title "bash — .env is ignored"
	{ echo "$$ docker run --rm --entrypoint id $(AFTER) -u"; docker run --rm --entrypoint id $(AFTER) -u; } \
	  | /usr/bin/python3 $(TERMSHOT) --out $(SHOTS)/07-non-root-uid.png --title "bash — runtime UID"

clean: ## remove the venv, caches and the local SQLite file
	rm -rf $(VENV) .pytest_cache helpdesk.db
	find . -name __pycache__ -type d -prune -exec rm -rf {} +
