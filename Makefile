SHELL := /bin/bash
.SHELLFLAGS := -eo pipefail -c

LIGATURIZER_DIR := Ligaturizer
NOTO_SANS_MONO_DIR := noto-sans-mono
OUTPUT_DIR := fonts
LIG_OUTPUT_DIR := $(LIGATURIZER_DIR)/fonts/output
NOTO_TARGET_DIR := $(LIGATURIZER_DIR)/fonts/noto-sans-mono

NOTO_SANS_MONO_URL_BASE := https://cdn.jsdelivr.net/gh/notofonts/notofonts.github.io/fonts/NotoSansMono/unhinted/otf
NOTO_SANS_MONO_FONTS := \
	$(NOTO_SANS_MONO_DIR)/NotoSansMono-Bold.otf \
	$(NOTO_SANS_MONO_DIR)/NotoSansMono-Medium.otf \
	$(NOTO_SANS_MONO_DIR)/NotoSansMono-Regular.otf \
	$(NOTO_SANS_MONO_DIR)/NotoSansMono-Light.otf

FINAL_FONTS := \
	$(OUTPUT_DIR)/LigaNotoSansMono-Bold.otf \
	$(OUTPUT_DIR)/LigaNotoSansMono-Medium.otf \
	$(OUTPUT_DIR)/LigaNotoSansMono-Regular.otf \
	$(OUTPUT_DIR)/LigaNotoSansMono-Light.otf

.DEFAULT_GOAL := all

.PHONY: all deps cleanup clean
.PRECIOUS: $(LIG_OUTPUT_DIR)/%.otf

all: cleanup

deps:
	@command -v fontforge >/dev/null 2>&1 || { \
		echo "fontforge is required (e.g., brew install fontforge)." >&2; \
		exit 1; \
	}
	@command -v curl >/dev/null 2>&1 || { \
		echo "curl is required to download Noto Sans Mono fonts." >&2; \
		exit 1; \
	}

cleanup: $(FINAL_FONTS)
	rm -rf $(LIGATURIZER_DIR)

$(OUTPUT_DIR):
	mkdir -p $@

$(NOTO_SANS_MONO_DIR):
	mkdir -p $@

$(NOTO_SANS_MONO_DIR)/NotoSansMono-%.otf: | $(NOTO_SANS_MONO_DIR)
	curl -fsSL -o $@ "$(NOTO_SANS_MONO_URL_BASE)/NotoSansMono-$*.otf"

$(NOTO_SANS_MONO_DIR)/.downloaded: $(NOTO_SANS_MONO_FONTS)
	touch $@

$(LIGATURIZER_DIR)/.git:
	git clone https://github.com/ToxicFrog/Ligaturizer.git $(LIGATURIZER_DIR)

$(LIGATURIZER_DIR)/fonts/fira/.git: $(LIGATURIZER_DIR)/.git
	git -C $(LIGATURIZER_DIR) submodule update --init --depth 1 fonts/fira

$(NOTO_TARGET_DIR)/.prepared: $(NOTO_SANS_MONO_DIR)/.downloaded $(LIGATURIZER_DIR)/.git
	rm -rf $(NOTO_TARGET_DIR)
	mkdir -p $(NOTO_TARGET_DIR)
	cp -f $(NOTO_SANS_MONO_FONTS) $(NOTO_TARGET_DIR)/
	touch $@

$(LIGATURIZER_DIR)/.patched: Makefile $(LIGATURIZER_DIR)/.git $(LIGATURIZER_DIR)/build.py $(LIGATURIZER_DIR)/ligatures.py
	@tmp=$$(mktemp) && \
	awk 'BEGIN { in_prefixed=0; in_renamed=0 } \
	/^prefixed_fonts[[:space:]]*=/ { \
		print "prefixed_fonts = []"; \
		in_prefixed=1; next; \
	} \
	in_prefixed { \
		if ($$0 ~ /^[[:space:]]*\]/) { in_prefixed=0 } \
		next; \
	} \
	/^renamed_fonts[[:space:]]*=/ { \
		print "renamed_fonts = {"; \
		print "    \"fonts/noto-sans-mono/NotoSansMono-Bold.otf\": \"Liga Noto Sans Mono\","; \
		print "    \"fonts/noto-sans-mono/NotoSansMono-Medium.otf\": \"Liga Noto Sans Mono\","; \
		print "    \"fonts/noto-sans-mono/NotoSansMono-Regular.otf\": \"Liga Noto Sans Mono\","; \
		print "    \"fonts/noto-sans-mono/NotoSansMono-Light.otf\": \"Liga Noto Sans Mono\""; \
		print "}"; \
		in_renamed=1; \
		if ($$0 ~ /}/) { in_renamed=0 } \
		next; \
	} \
	in_renamed { \
		if ($$0 ~ /^[[:space:]]*}/) { in_renamed=0 } \
		next; \
	} \
	{ print }' "$(LIGATURIZER_DIR)/build.py" > $$tmp && mv $$tmp "$(LIGATURIZER_DIR)/build.py"
	@tmp=$$(mktemp) && \
	awk 'BEGIN { \
		skip=0; \
		targets["    {   # &&"]=1;  \
		targets["    {   # ~@"]=1;  \
		targets["    {   # \\/"]=1; \
		targets["    {   # .?"]=1;  \
		targets["    {   # ?:"]=1;  \
		targets["    {   # ?="]=1;  \
		targets["    {   # ?."]=1;  \
		targets["    {   # ??"]=1;  \
		targets["    {   # ;;"]=1;  \
		targets["    {   # /\\"]=1; \
	} \
	targets[$$0] { skip=1; next } \
	skip && $$0 ~ /^[[:space:]]*},[[:space:]]*$$/ { skip=0; next } \
	skip { next } \
	{ print }' "$(LIGATURIZER_DIR)/ligatures.py" > $$tmp && mv $$tmp "$(LIGATURIZER_DIR)/ligatures.py"
	@touch $@

$(LIGATURIZER_DIR)/.built: deps $(LIGATURIZER_DIR)/.patched $(NOTO_TARGET_DIR)/.prepared $(LIGATURIZER_DIR)/fonts/fira/.git
	$(MAKE) -C $(LIGATURIZER_DIR)
	touch $@

$(LIG_OUTPUT_DIR)/%.otf: | $(LIGATURIZER_DIR)/.built
	@test -f $@

$(OUTPUT_DIR)/%.otf: $(LIG_OUTPUT_DIR)/%.otf | $(OUTPUT_DIR)
	cp $< $@

clean:
	rm -rf $(LIGATURIZER_DIR) $(OUTPUT_DIR)
