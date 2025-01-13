# Copyright Toby Davis
# See LICENSE for details

########################################
# PHONY TARGETS
########################################
.PHONY: all build build-stage0 build-stage1 build-stage2 build-target \
        draft tectonic tectonic-draft init clean distclean predepend \
        deps-stage1 deps-stage2

########################################
# DEFAULT TARGET
########################################
all: build

########################################
# ENVIRONMENT VARIABLES
########################################
LATEXMK                  = $(or $(wildcard $(TEXHOME)/bin/latexmk), latexmk)
LATEXMK_LATEXOPTION      = --interaction=nonstopmode
LATEXMK_LATEXOPTION     += --synctex=1
LATEXMK_LATEXOPTION     += --shell-escape
LATEXMK_FLAGS            = --lualatex --latexoption="$(LATEXMK_LATEXOPTION)" --bibtex --use-make
LATEXMK_FLAGS           += $(if $(LATEXMK_FORCE_REBUILD),-g)
LATEXMK_FORCE_REBUILD   ?=
LATEXMK_CLEAN            = $(LATEXMK) -c
LATEXMK_DISTCLEAN        = $(LATEXMK) -C

HAS_TECTONIC    = $(shell which tectonic > /dev/null && echo true || echo false)
TECTONIC_BUILD  = tectonic -X compile

GIT    ?= git
GITDIR := $(shell $(GIT) rev-parse --git-dir)

# Pull in project name variables
include project_name
include .oldname

# Defines SOURCE_BASENAME
BASE_FILE = $(PROJECT_NAME)
TARGET    = $(BASE_FILE)
SOURCES   = $(TARGET).tex

# Include TikZ externalize makefile if available
-include $(TARGET).makefile

########################################
# BUILD TARGETS
########################################

## Stage 0: Ensure externalization directory is present if needed
build-stage0:
	if [ ! -d tikz_figures ] && [ ! -f no_externalize.flag ]; then \
		mkdir tikz_figures; \
	fi

## Stage 1: Main build; check if we need stage2
build-stage1: build-target
	test ! -s $(TARGET).makefile || \
	  $(MAKE) -q deps-stage2 || \
	  $(MAKE) build-stage2

## Stage 2: Force rebuild for TikZ externalization if needed
build-stage2: LATEXMK_FORCE_REBUILD = yes
build-stage2: build-target

## Actual build target using latexmk
build-target: $(TARGET).pdf
	@true

## Dependencies for stage1 and stage2
deps-stage1: $(SOURCES)
deps-stage2: $(ALL_FIGURES)  # If you define ALL_FIGURES

## Combined build pipeline
build: build-stage0
	$(MAKE) build-stage1

########################################
# PDF RULE
########################################
$(TARGET).pdf: deps-stage1 deps-stage2
	$(LATEXMK) $(LATEXMK_FLAGS) --deps-out=$(TARGET).dep $(SOURCES)

########################################
# DRAFT MODE
########################################
draft:
	touch draft.flag
	# If the fdb_latexmk file doesn't reference draft.flag, force a rebuild
	$(MAKE) $(if $(shell grep -s draft.flag $(TARGET).fdb_latexmk),,LATEXMK_FORCE_REBUILD=yes)
	$(RM) draft.flag

draft.flag:
	$(RM) $(TARGET).pdf

########################################
# TECTONIC BUILD
########################################
tectonic:
	if [ "$(HAS_TECTONIC)" = "false" ]; then \
		echo "tectonic is not installed, aborting"; \
		exit 1; \
	fi
	if [ -f no_externalize.flag ]; then \
		$(TECTONIC_BUILD) $(SOURCES); \
	else \
		touch no_externalize.flag; \
		$(TECTONIC_BUILD) $(SOURCES); \
		rm no_externalize.flag; \
	fi

tectonic-draft:
	touch draft.flag
	$(MAKE) tectonic
	$(RM) draft.flag

########################################
# INIT TARGET
########################################
init:
	# Temporarily write out the old project name
	echo "# This is the name of your project and determines the output PDF."    >  project_name
	echo "# Run 'make init' to configure this."                                >> project_name
	echo "PROJECT_NAME = $(OLD_PROJECT_NAME)"                                  >> project_name
	
	# Clean out everything with the old name
	$(MAKE) distclean
	
	# Now rewrite project_name with the new name
	echo "# This is the name of your project and determines the output PDF."    >  project_name
	echo "# Run 'make init' to configure this."                                >> project_name
	echo "PROJECT_NAME = $(PROJECT_NAME)"                                       >> project_name

	# Rename the main .tex file
	mv $(OLD_PROJECT_NAME).tex $(PROJECT_NAME).tex

	# Update the old name for future re-inits
	echo "# DO NOT CHANGE THIS. This is required for 'make init' to work."      >  .oldname
	echo "OLD_PROJECT_NAME = $(PROJECT_NAME)"                                   >> .oldname

	# Build with the new name
	$(MAKE)

########################################
# CLEAN & DISTCLEAN TARGETS
########################################
clean:
	$(LATEXMK_CLEAN)
	$(RM) *.aux *.bbl *.blg
	$(RM) *.synctex.gz
	$(RM) *.pgf-plot.gnuplot *.pgf-plot.table *.pgf-plot.vrs
	$(RM) *.dep
	$(RM) draft.flag
	$(RM) *.unkwrd Tutorial/*.unkwrd 2>/dev/null || true
	$(RM) *.chktex Tutorial/*.chktex 2>/dev/null || true
	$(RM) spellcheck-report.txt
	$(RM) *contour*.dat
	$(RM) *contour*.lua
	$(RM) *contour*.table

distclean: clean
	$(LATEXMK_DISTCLEAN)
	$(RM) $(TARGET).pdf
	$(RM) $(TARGET).figlist
	$(RM) $(TARGET).makefile
	$(RM) *.fls
	$(RM) *.auxlock
	$(RM) *.script
	if [ -d cache ]; then $(MAKE) -C cache clean; fi
	if [ -d tikz_figures ]; then $(RM) -r tikz_figures; fi

########################################
# BIBUNITS DUMMY
########################################
bu.aux:
	touch $@

########################################
# LOCAL INCLUDES & DEPENDENCIES
########################################
-include Makefile.local
-include *.dep

########################################
# IGNORE MISSING TARGETS
########################################
ifneq (,$(IGNORE_MISSING))
%::
	@echo "Ignoring missing '$@'"
endif
