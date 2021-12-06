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
BUILD_DIR ?= $(NOW_DIR)/build
SOURCE_DIR = $(NOW_DIR)/source
TARGET_EXEC = compiler
TARGET_DIR = $(BUILD_DIR)/$(TARGET_EXEC)

# YACC OUTPUT
YACC_OUT = $(BUILD_DIR)/parser.tab.h $(BUILD_DIR)/parser.tab.c

# Token class
TOKEN_SOURCE = $(SOURCE_DIR)/tokenclass.cpp $(SOURCE_DIR)/tokenclass.h
TOKEN_CLASS = $(BUILD_DIR)/tokenclass.o

# Generation rules
$(TARGET_DIR): $(BUILD_DIR)/scanner.cpp $(BUILD_DIR)/parser.tab.c $(TOKEN_CLASS)
	$(CPP) $(CPPFLAGS) -o $@ -I $(SOURCE_DIR) $^

$(TOKEN_CLASS): $(TOKEN_SOURCE)
	$(CPP) $(CPPFLAGS) -c -o $@ -I $(SOURCE_DIR) $<

$(BUILD_DIR)/scanner.cpp: $(SOURCE_DIR)/scanner.l $(YACC_OUT)
	mkdir -p $(dir $@)
	$(LEX) -o $@ $<

$(YACC_OUT): $(SOURCE_DIR)/parser.y
	$(YACC) -v --defines=$(BUILD_DIR)/parser.tab.h --output=$(BUILD_DIR)/parser.tab.c $<

# Phony file for clean
.PHONY: clean

clean:
	rm -f $(BUILD_DIR)/*