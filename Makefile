#
#  DYYY
#
#  Copyright (c) 2024 huami. All rights reserved.
#  Channel: @huamidev
#  Created on: 2024/10/04
#
#

TARGET = iphone:clang:latest:15.0
ARCHS = arm arm64 arm64e

#export THEOS=/Users/huami/theos
#export THEOS_PACKAGE_SCHEME=roothide

ifeq ($(SCHEME),roothide)
    export THEOS_PACKAGE_SCHEME = roothide
else ifeq ($(SCHEME),rootless)
    export THEOS_PACKAGE_SCHEME = rootless
endif

export DEBUG = 0
INSTALL_TARGET_PROCESSES = Aweme

include $(THEOS)/makefiles/common.mk

# 核心修改：TWEAK_NAME 变量
TWEAK_NAME = DyHookbyX

# 同步修改所有以 DYYY_ 开头的变量前缀为 DyHookbyX_
DyHookbyX_LIBRARY_SEARCH_PATHS = $(THEOS_PROJECT_DIR)/libs
DyHookbyX_HEADER_SEARCH_PATHS = $(THEOS_PROJECT_DIR)/libs/include

DyHookbyX_FILES = DYYY.xm DYYYHide.xm DYYYFloatClearButton.xm DYYYFloatSpeedButton.xm DYYYSettings.xm DYYYABTestHook.xm DYYYSettingViewController.m DYYYBottomAlertView.m DYYYCustomInputView.m DYYYOptionsSelectionView.m DYYYIconOptionsDialogView.m DYYYAboutDialogView.m DYYYManager.m CityManager.m
DyHookbyX_CFLAGS = -fobjc-arc -w -I$(DyHookbyX_HEADER_SEARCH_PATHS)
DyHookbyX_LDFLAGS = -L$(DyHookbyX_LIBRARY_SEARCH_PATHS) -lwebp
DyHookbyX_FRAMEWORKS = CoreAudio

CXXFLAGS += -std=c++11
CCFLAGS += -std=c++11
DyHookbyX_LOGOS_DEFAULT_GENERATOR = internal

export THEOS_STRICT_LOGOS=0
export ERROR_ON_WARNINGS=0
export LOGOS_DEFAULT_GENERATOR=internal

include $(THEOS_MAKE_PATH)/tweak.mk

THEOS_DEVICE_IP = 192.168.31.222
THEOS_DEVICE_PORT = 22

clean::
	@echo -e "\033[31m==>\033[0m Cleaning packages…"
	@rm -rf .theos packages

after-package::
	@if [ "$(THEOS_PACKAGE_SCHEME)" = "roothide" ] && [ "$(INSTALL)" = "1" ]; then \
	echo -e "\033[31m==>\033[0m Installing package to device…"; \
	DEB_FILE=$$(ls -t packages/*.deb | head -1); \
	PACKAGE_NAME=$$(basename "$$DEB_FILE" | cut -d'_' -f1); \
	ssh root@$(THEOS_DEVICE_IP) "rm -rf /tmp/$${PACKAGE_NAME}.deb"; \
	scp "$$DEB_FILE" root@$(THEOS_DEVICE_IP):/tmp/$${PACKAGE_NAME}.deb; \
	ssh root@$(THEOS_DEVICE_IP) "dpkg -i --force-overwrite /tmp/$${PACKAGE_NAME}.deb && rm -f /tmp/$${PACKAGE_NAME}.deb"; \
	fi