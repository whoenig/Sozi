
# The version number is obtained from the current date and time
VERSION := $(shell date +%y.%m-%d%H%M%S)

# All source files of the Inkscape extensions
EDITOR_SRC := \
	$(wildcard editors/inkscape/*.py) \
	$(wildcard editors/inkscape/*.inx) \
	$(wildcard editors/inkscape/sozi/*.*)

# The translation files for the Inkscape extensions
EDITOR_PO := $(wildcard editors/inkscape/sozi/lang/*.po)

# The translatable source files of the Inkscape extensions
GETTEXT_SRC := \
	$(wildcard editors/inkscape/*.py) \
	$(wildcard editors/inkscape/sozi/*.py) \
	editors/inkscape/sozi/ui.glade

# The list of Javascript source files in the player and Sozi extras
PLAYER_JS := $(wildcard player/js/*.js)
EXTRAS_JS := $(wildcard player/js/extras/*.js)

# Files of the player to be compiled
PLAYER_SRC := \
	player/js/sozi.js \
	player/css/sozi.css \
	$(EXTRAS_JS)

# The documentation files
DOC := \
	$(wildcard doc/*license.txt)

# The list of files in the installation tree
TARGET := \
    $(subst editors/inkscape/,,$(EDITOR_SRC)) \
    $(patsubst editors/inkscape/sozi/lang/%.po,sozi/lang/%/LC_MESSAGES/sozi.mo,$(EDITOR_PO)) \
    $(addprefix sozi/,$(notdir $(PLAYER_SRC) $(DOC)))

# The list of files in the release tree
TARGET_RELEASE := $(addprefix release/, $(TARGET))

# The path of the installation folder for the current user
INSTALL_DIR := $(HOME)/.config/inkscape/extensions

# The release bundle
ZIP := release/sozi-release-$(VERSION).zip

# The minifier command line and options

#MINIFY_OPT += --nomunge

JUICER_OPT += --force
JUICER_OPT += --skip-verification
#JUICER_OPT += --minifyer none

MINIFY := juicer merge $(JUICER_OPT) --arguments "$(MINIFY_OPT)"

# The Javascript linter command
LINT := ./node_modules/autolint/bin/autolint

# The message compiler command
MSGFMT := /usr/lib/python2.7/Tools/i18n/msgfmt.py


.PHONY: all verify install doc clean

# Default rule: create a zip archive for installation
all: $(ZIP)

# Verify Javascript source files of the player
verify: $(PLAYER_JS) $(EXTRAS_JS)
	$(LINT) --once

# Install Sozi
install: $(TARGET_RELEASE)
	cd release ; cp --parents $(TARGET) $(INSTALL_DIR)

# Generate API documentation
doc: $(PLAYER_JS) $(EXTRAS_JS)
	jsdoc --directory=web/api --recurse=1 \
		--allfunctions --private \
		--template=jsdoc-templates \
		player/js

# Generate a template file for translation
pot: $(GETTEXT_SRC)
	xgettext --package-name=Sozi --package-version=$(VERSION) --output=editors/inkscape/sozi/lang/sozi.pot $^

# Create a zip archive for installation
$(ZIP): $(TARGET_RELEASE)
	cd release ; zip $(notdir $@) $(TARGET)

# Concatenate and minify the Javascript source files of the player
release/sozi/sozi.js: $(PLAYER_JS)
	$(MINIFY) --output $@ player/js/sozi.js

# Minify a CSS stylesheet of the player
release/sozi/%.css: player/css/%.css
	$(MINIFY) --output $@ $<

# Minify a Javascript source file from Sozi-extras
release/sozi/%.js: player/js/extras/%.js
	$(MINIFY) --output $@ $<

# Compile a translation file for a given language
release/sozi/lang/%/LC_MESSAGES/sozi.mo: editors/inkscape/sozi/lang/%.po
	mkdir -p $(dir $@) ; $(MSGFMT) -o $@ $<

# Fill the version number in the Inkscape extensions
release/sozi/version.py:
	mkdir -p $(dir $@) ; sed "s/@SOZI_VERSION@/$(VERSION)/g" editors/inkscape/sozi/version.py > $@

# Copy a file from the Inkscape extensions
release/%: editors/inkscape/%
	mkdir -p $(dir $@) ; cp $< $@

# Copy a file from the documents folder
release/sozi/%: doc/%
	mkdir -p $(dir $@) ; cp $< $@

# Remove all temporary files from the release folder
clean:
	rm -f $(TARGET_RELEASE)

