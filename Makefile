FF = fontforge.exe
SRC_DIR = src/
FONTS_DIR = dist/
SRCS = $(shell find $(SRC_DIR) -name *.sfd)
FONTS = $(SRCS:$(SRC_DIR)%.sfd=$(FONTS_DIR)%.otf)

all: $(FONTS)

$(FONTS_DIR)%.otf: $(SRC_DIR)%.sfd
	@mkdir -p $(@D)
	@echo "Generating $@"
	@$(FF) -quiet -lang=py -script generate.py $< $@

.PHONY: mrproper

mrproper:
	rm -rf $(FONTS_DIR)
