INFOPLIST_FILE=Info.plist
SOURCES=\
	main.m \
	GuitarApp.m \
	Guitar.mm \
	GuitarView.m \
	AudioOutput.m \
	SettingsView.m \
	InstrumentFactory.mm

STK_HOME=/Users/shinya/src/stk-4.3.1
RAWWAVES_SRC=rawwaves
CC=/usr/local/bin/arm-apple-darwin-gcc
CPP=/usr/local/bin/arm-apple-darwin-cpp
CFLAGS=-g -O2 -mfpu=vfp -Wall -D__IPHONE__ -I$(STK_HOME)/include -I/usr/local/arm-apple-darwin/include
LD=$(CC)
LDFLAGS=-Wl -L. -lstdc++ -lobjc -ObjC -framework CoreFoundation -framework Foundation -framework CoreGraphics -framework GraphicsServices -framework UIKit -framework LayerKit -framework CoreAudio -framework AudioToolbox -framework Celestial -lstk

WRAPPER_NAME=$(PRODUCT_NAME).app
EXECUTABLE_NAME=$(PRODUCT_NAME)
SOURCES_ABS=$(addprefix $(SRCROOT)/,$(SOURCES))
INFOPLIST_ABS=$(addprefix $(SRCROOT)/,$(INFOPLIST_FILE))
OBJECTS=\
	$(patsubst %.c,%.o,$(filter %.c,$(SOURCES))) \
	$(patsubst %.cc,%.o,$(filter %.cc,$(SOURCES))) \
	$(patsubst %.cpp,%.o,$(filter %.cpp,$(SOURCES))) \
	$(patsubst %.m,%.o,$(filter %.m,$(SOURCES))) \
	$(patsubst %.mm,%.o,$(filter %.mm,$(SOURCES)))
OBJECTS_ABS=$(addprefix $(CONFIGURATION_TEMP_DIR)/,$(OBJECTS))
APP_ABS=$(BUILT_PRODUCTS_DIR)/$(WRAPPER_NAME)
RAWWAVES_DIR=$(APP_ABS)/rawwaves
PRODUCT_ABS=$(APP_ABS)/$(EXECUTABLE_NAME)

all: $(PRODUCT_ABS)

$(PRODUCT_ABS): $(APP_ABS) $(OBJECTS_ABS)
	$(LD) $(LDFLAGS) -o $(PRODUCT_ABS) $(OBJECTS_ABS)

$(APP_ABS): $(INFOPLIST_ABS)
	mkdir -p $(APP_ABS)
	cp $(INFOPLIST_ABS) $(APP_ABS)/

#$(RAWWAVES_DIR): $(RAWWAVES_SRC)#
#	mkdir -p $(RAWWAVES_DIR)
#	cp -f $(RAWWAVES_SRC)/*.raw $(RAWWAVES_DIR)/

$(CONFIGURATION_TEMP_DIR)/%.o: $(SRCROOT)/%.m
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

$(CONFIGURATION_TEMP_DIR)/%.o: $(SRCROOT)/%.mm
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS_ABS)
	rm -rf $(APP_ABS)

