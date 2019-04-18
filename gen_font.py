import sys
import fontforge as ff

# Version of the generated font
VERSION = "1.001"

if len(sys.argv) != 3:
    sys.stderr.write("Usage: {} source_file font_name\n".format(sys.argv[0]))
    sys.exit(1)

# Opens the font source file
font = ff.open(sys.argv[1])

if font.validate() != 0:
    # The font is invalid, skip the generation
    sys.stderr.write("The font contains errors, generation cancelled.\n")
    sys.exit(2)

# Adds calt feature
font.mergeFeature("calt.fea")

# Updates the font version
font.version = VERSION

# Generates the font
font.generate(sys.argv[2])
