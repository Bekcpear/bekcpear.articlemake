SOURCES := $(wildcard *.md)
OBJECTS := $(patsubst %.md, %.html, $(wildcard *.md))
OBJECTS_PDF := $(patsubst %.md, %.pdf, $(wildcard *.md))

all: html pdf

html: $(OBJECTS)
pdf: $(OBJECTS_PDF)

$(OBJECTS): %.html: %.md
	pandoc $< -o $@

$(OBJECTS_PDF): %.pdf: %.md
	pandoc --template=./template.tex --latex-engine=xelatex  $< -o $@
