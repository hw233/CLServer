include platform.mk

# Use your path
SKYNET_PATH = ../skynet
LUA_INC = $(SKYNET_PATH)/3rd/lua 
TARGET = reload.so
LUA_CLIB_PATH ?= luaclib

CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS)

all : $(TARGET) MOVE

$(TARGET) : lua-reload.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -o $@ $^ -I$(SKYNET_PATH)/skynet-src 

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

MOVE :
	mv $(TARGET) $(LUA_CLIB_PATH)/$(TARGET)

clean :
	rm $(TARGET)
