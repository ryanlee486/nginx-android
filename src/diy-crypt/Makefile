# Simple Makefile for DIY crypt library

CC ?= gcc
AR ?= ar
CFLAGS ?= -O2 -Wall
PREFIX ?= /usr/local

SOURCES = crypt.c
OBJECTS = $(SOURCES:.c=.o)
LIBRARY = libcrypt.a
SHARED_LIB = libcrypt.so

.PHONY: all clean install static shared

all: static

static: $(LIBRARY)

shared: $(SHARED_LIB)

$(LIBRARY): $(OBJECTS)
	$(AR) rcs $@ $^

$(SHARED_LIB): $(OBJECTS)
	$(CC) -shared -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -fPIC -c $< -o $@

clean:
	rm -f $(OBJECTS) $(LIBRARY) $(SHARED_LIB)

install: $(LIBRARY)
	mkdir -p $(PREFIX)/lib $(PREFIX)/include
	cp $(LIBRARY) $(PREFIX)/lib/
	cp crypt.h $(PREFIX)/include/

.SUFFIXES: .c .o
