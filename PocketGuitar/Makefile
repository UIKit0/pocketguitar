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

STK_HOME=/Users/shinya/src/stk-4.3.1
RAWWAVES_SRC=rawwaves
CC=/usr/local/bin/arm-apple-darwin-gcc
CPP=/usr/local/bin/arm-apple-darwin-cpp
CFLAGS=-g -O2 -lobjc -framework CoreFoundation -framework Foundation -mfpu=vfp -Wall -D__IPHONE__ -I$(STK_HOME)/include -I/usr/local/arm-apple-darwin/include
LD=$(CC)
LDFLAGS=-Wl -lstdc++ -lobjc -ObjC -framework MobileMusicPlayer -framework CoreFoundation -framework Foundation -framework CoreGraphics -framework GraphicsServices -framework UIKit -framework LayerKit -framework CoreAudio -framework AudioToolbox -framework Celestial
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
	$(LD) $(LDFLAGS) -o $(PRODUCT_ABS) $(OBJECTS_ABS) libstk.a

$(EXTRACT_SAMPLES_ABS): $(APP_ABS)
	$(CC) $(CFLAGS) -o $(EXTRACT_SAMPLES_ABS) extract_samples.m libmpg123.a

$(APP_ABS): $(INFOPLIST_ABS) $(ICON_ABS)
	mkdir -p $(APP_ABS)
	cp $(INFOPLIST_ABS) $(APP_ABS)/
	cp $(SRCROOT)/*.png $(APP_ABS)/

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

