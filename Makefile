# Copyright Toby Davis
# See LICENSE for details

all: build

# Environment variables
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

# defines SOURCE_BASENAME
BASE_FILE = my_paper

TARGET   = $(BASE_FILE)
SOURCES  = $(TARGET:=.tex)

# Include tikz externalize Makefile. Ignore if not available
-include $(TARGET).makefile

.PHONY: build clean distclean predepend

### Build target ###
# build: build-stage0
# 	$(MAKE) build-stage1

build:  build-stage0
	$(MAKE) build-stage1

build-target: $(TARGET).pdf

build-stage0:
	if [ ! -d tikz_figures ] && [ ! -f no_externalize.flag ]; then mkdir tikz_figures; fi

deps-stage1: $(SOURCES)

build-stage1: build-target
	test ! -s $(TARGET).makefile || $(MAKE) -q deps-stage2 || $(MAKE) build-stage2

deps-stage2: $(ALL_FIGURES)

build-stage2: LATEXMK_FORCE_REBUILD = yes
build-stage2: build-target

.PHONY: $(TARGET).pdf
$(TARGET).pdf: deps-stage1
$(TARGET).pdf: deps-stage2
$(TARGET).pdf:
	$(LATEXMK) $(LATEXMK_FLAGS) --deps-out=$(TARGET).dep $(SOURCES)


### Build target (draft mode) ###
draft:
	touch draft.flag
	$(MAKE) $(if $(shell grep -s draft.flag $(TARGET).fdb_latexmk),,LATEXMK_FORCE_REBUILD=yes)
	$(RM) draft.flag

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

# for switching back from draft to normal builds
draft.flag:
	$(RM) $(TARGET).pdf

### Clean target ###
# Remove generated files, but not everything
clean::
	$(LATEXMK_CLEAN)
	$(RM) *.aux *.bbl *.blg
	$(RM) *.synctex.gz
	$(RM) *.pgf-plot.gnuplot *.pgf-plot.table *.pgf-plot.vrs
	$(RM) *.dep
	$(RM) draft.flag
	$(RM) *.unkwrd Tutorial/*.unkwrd
	$(RM) *.chktex Tutorial/*.chktex
	$(RM) spellcheck-report.txt
	$(RM) *contour*.dat
	$(RM) *contour*.lua
	$(RM) *contour*.table

# Remove pretty much everything -- especially tikz externalize images
distclean:: clean
	$(LATEXMK_DISTCLEAN)
	$(RM) $(TARGET).pdf
	$(RM) $(TARGET).figlist
	$(RM) $(TARGET).makefile
	$(RM) *.fls
	$(RM) *.auxlock
	$(RM) *.script
	if [ -d cache ]; then $(MAKE) -C cache clean; fi
	if [ -d tikz_figures ]; then $(RM) -r tikz_figures; fi

# dummy file, may be requested erroneously by bibunits
bu.aux:
	touch $@

-include Makefile.local
-include *.dep

ifneq (,$(IGNORE_MISSING))
	%::
	@echo "Ignoring missing '$@'"
endif
