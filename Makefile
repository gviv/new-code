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
	rm -rf $(FONTS_DIR)

# Fonts rules
$(FONTS_DIR)%.otf: $(SRC_DIR)%.sfd
	@mkdir -p $(@D)
	@echo "Generating $@"
	@$(FF) -quiet -lang=py -script generate.py $< $@
