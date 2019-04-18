# Path to FontForge
FF := fontforge.exe
# Source directory
SRC_DIR := src/
# Fonts directory
FONTS_DIR := dist/

# Finds the source files
SRCS := $(shell find $(SRC_DIR) -name *.sfd)
# Infers the font files
FONTS := $(SRCS:$(SRC_DIR)%.sfd=$(FONTS_DIR)%.otf)

# Main rule, generates the fonts
.PHONY: all
all: $(FONTS)

# Removes all generated files and fonts
.PHONY: clean
clean:
	rm -rf $(FONTS_DIR) calt.fea

# Generates the calt file
.PHONY: calt
calt: calt.fea

# Fonts rules
$(FONTS_DIR)%.otf: $(SRC_DIR)%.sfd calt.fea gen_font.py
	@echo "Generating $@"
	@$(FF) -quiet -lang=py -script gen_font.py $< $@

# Adds, for each font, its directory as an order-only prerequisite (avoids
# redundant calls to mkdir)
$(foreach FONT, $(FONTS), $(eval $(FONT): | $(dir $(FONT))))

# Fonts' directory rules
$(FONTS_DIR)%/:
	@mkdir -p $@

# .fea files rules
calt.fea: gen_calt.ml
	@echo "Generating $@"
	@ocaml $<
