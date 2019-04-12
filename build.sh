#!/bin/bash

SRC_DIR=src
FONTS_DIR=dist
FF_PATH=fontforge.exe

# Checks whether a source file has been modified
isModified() {
    # Retrieves the font name and removes extension
    local font_name=$(basename "$1")
    local font_name=${font_name%.*}
    local last_modified=$(ls -1t "$SRC_DIR"/*/* "$FONTS_DIR"/*/* | grep "$font_name\." | head -n 1)
    [ "${last_modified: -3}" = 'sfd' ]
}

# Generates the fonts
for style in "$SRC_DIR"/*
do
    # Creates font style directory
    mkdir -p ${style/"$SRC_DIR"/"$FONTS_DIR"}

    for font_src in "$style"/*
    do
        font_path=${font_src/"$SRC_DIR"/"$FONTS_DIR"}
        font_path=${font_path/sfd/otf}
        # Skip if the current font source hasn't been modified
        isModified ${font_path} || continue

        echo "Generating $font_path"
        "$FF_PATH" -quiet -lang=py -script generate.py "$font_src" "$font_path"
    done
done

exit 0
