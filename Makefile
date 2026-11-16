ARCHS = armv7 armv7s
TARGET = iphone:clang:latest:6.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UADiscover
UADiscover_FILES = Tweak.xm
UADiscover_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
