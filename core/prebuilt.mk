###########################################################
## Standard rules for copying files that are prebuilt
##
## Additional inputs from base_rules.make:
## None.
##
###########################################################

ifneq ($(LOCAL_PREBUILT_LIBS),)
$(error dont use LOCAL_PREBUILT_LIBS anymore LOCAL_PATH=$(LOCAL_PATH))
endif
ifneq ($(LOCAL_PREBUILT_EXECUTABLES),)
$(error dont use LOCAL_PREBUILT_EXECUTABLES anymore LOCAL_PATH=$(LOCAL_PATH))
endif
ifneq ($(LOCAL_PREBUILT_JAVA_LIBRARIES),)
$(error dont use LOCAL_PREBUILT_JAVA_LIBRARIES anymore LOCAL_PATH=$(LOCAL_PATH))
endif

include $(BUILD_SYSTEM)/base_rules.mk

# Deal with the OSX library timestamp issue when installing
# a prebuilt simulator library.
ifneq ($(filter STATIC_LIBRARIES SHARED_LIBRARIES,$(LOCAL_MODULE_CLASS)),)
  prebuilt_module_is_a_library := true
else
  prebuilt_module_is_a_library :=
endif

PACKAGES.$(LOCAL_MODULE).OVERRIDES := $(strip $(LOCAL_OVERRIDES_PACKAGES))

ifeq ($(LOCAL_CERTIFICATE),)
  # can't re-sign this package, so predexopt is not available.
else

# If this is not an absolute certificate, assign it to a generic one.
ifeq ($(dir $(strip $(LOCAL_CERTIFICATE))),./)
    LOCAL_CERTIFICATE := $(SRC_TARGET_DIR)/product/security/$(LOCAL_CERTIFICATE)
endif

private_key := $(LOCAL_CERTIFICATE).pk8
certificate := $(LOCAL_CERTIFICATE).x509.pem

$(LOCAL_BUILT_MODULE): $(private_key) $(certificate) $(SIGNAPK_JAR)
$(LOCAL_BUILT_MODULE): PRIVATE_PRIVATE_KEY := $(private_key)
$(LOCAL_BUILT_MODULE): PRIVATE_CERTIFICATE := $(certificate)

PACKAGES.$(LOCAL_MODULE).PRIVATE_KEY := $(private_key)
PACKAGES.$(LOCAL_MODULE).CERTIFICATE := $(certificate)

PACKAGES := $(PACKAGES) $(LOCAL_MODULE)
endif
 
# Ensure that prebuilt .apks have been aligned.
ifneq ($(filter APPS,$(LOCAL_MODULE_CLASS)),)
$(LOCAL_BUILT_MODULE) : $(LOCAL_PATH)/$(LOCAL_SRC_FILES) | $(ZIPALIGN)
ifneq ($(LOCAL_CERTIFICATE),PRESIGNED)
	$(transform-prebuilt-to-target)
	$(sign-package)
	@# Alignment must happen after all other zip operations.
	$(align-package)
else
	$(transform-prebuilt-to-target-with-zipalign)
endif
else
ifneq ($(LOCAL_PREBUILT_STRIP_COMMENTS),)
$(LOCAL_BUILT_MODULE) : $(LOCAL_PATH)/$(LOCAL_SRC_FILES)
	$(transform-prebuilt-to-target-strip-comments)
else
$(LOCAL_BUILT_MODULE) : $(LOCAL_PATH)/$(LOCAL_SRC_FILES) | $(ACP)
	$(transform-prebuilt-to-target)
endif
endif

ifneq ($(prebuilt_module_is_a_library),)
  ifneq ($(LOCAL_IS_HOST_MODULE),)
	$(transform-host-ranlib-copy-hack)
  else
	$(transform-ranlib-copy-hack)
  endif
endif
