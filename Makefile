# Makefile to automate the compiling process and free myself from memorizing commands

C = gcc
CPP = g++
CFLAGS := -Wall -std=c11
CPPFLAGS := -Wall -Wno-register -std=c++17

# If PROD (production) undefined then it's 0
PROD ?= 0
ifeq ($(PROD), 0)
CFLAGS += -g -O0
CPPFLAGS += -g -O0
else
CFLAGS += -O2
CPPFLAGS += -O2
endif

# Scanner and Parser
LEX = flex
YACC = bison

# Directories. Copied from the document.
NOW_DIR = $(shell pwd)
TARGET_EXEC = compiler
BUILD_DIR ?= $(NOW_DIR)/build
SOURCE_DIR = $(NOW_DIR)/source

# Generation rules. Mostly copied from the document.
$(BUILD_DIR)/lexer.lex.cpp: $(SOURCE_DIR)/lexer.l
	mkdir -p $(dir $@)
	$(LEX) -o $@ $<

# Phony file for clean
.PHONY: clean

clean:
	rm -f $(BUILD_DIR)/*