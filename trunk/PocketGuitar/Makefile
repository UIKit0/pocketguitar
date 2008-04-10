ifeq ($(strip $(PRODUCT_NAME)),)
PRODUCT_NAME:=PocketGuitar
endif
ifeq ($(strip $(SRCROOT)),)
SRCROOT=.
endif
ifeq ($(strip $(BUILT_PRODUCTS_DIR)),)
BUILT_PRODUCTS_DIR=./build/Release
endif
ifeq ($(strip $(CONFIGURATION_TEMP_DIR)),)
CONFIGURATION_TEMP_DIR=./build/tmp
endif

INFOPLIST_FILE=Info.plist
SOURCES=\
	main.m \
	GuitarApp.m \
	Guitar.mm \
	GuitarView.m \
	AudioOutput.m \
	SettingsView.m \
	InstrumentFactory.mm \
	Fretboard.m \
	FretboardEditor.m \
	FretboardView.m

STK_HOME=../stk-4.3.1
RAWWAVES_SRC=rawwaves
CC=/usr/local/bin/arm-apple-darwin-gcc
CPP=/usr/local/bin/arm-apple-darwin-cpp
CFLAGS=-g -O2 -mfpu=vfp -Wall -D__IPHONE__ -I$(STK_HOME)/include -I/usr/local/arm-apple-darwin/include
LD=$(CC)
LIBS=-lstdc++.6 -lgcc_eh -lobjc -ObjC -lmpg123 -framework MobileMusicPlayer -framework CoreFoundation -framework Foundation -framework CoreGraphics -framework GraphicsServices -framework UIKit -framework LayerKit -framework CoreAudio -framework AudioToolbox -framework Celestial
LDFLAGS=-Wl $(LIBS)
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
EXTRACT_SAMPLES_NAME=extract_samples
EXTRACT_SAMPLES_ABS=$(APP_ABS)/$(EXTRACT_SAMPLES_NAME)

all: $(PRODUCT_ABS) $(EXTRACT_SAMPLES_ABS)

$(PRODUCT_ABS): $(APP_ABS) $(OBJECTS_ABS)
	$(LD) $(LDFLAGS) -o $(PRODUCT_ABS) $(OBJECTS_ABS) $(STK_HOME)/src/libstk.a

$(EXTRACT_SAMPLES_ABS): $(APP_ABS)
	$(CC) $(CFLAGS) $(LIBS) -o $(EXTRACT_SAMPLES_ABS) extract_samples.m

$(APP_ABS): $(INFOPLIST_ABS) $(ICON_ABS)
	mkdir -p $(APP_ABS)
	cp $(INFOPLIST_ABS) $(APP_ABS)/
	cp about.html $(APP_ABS)/
	cp silence.wav $(APP_ABS)/
	cp $(SRCROOT)/Images/*.png $(APP_ABS)/

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

