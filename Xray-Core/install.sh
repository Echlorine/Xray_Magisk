##########################################################################################
#
# Magisk Module Installer Script
#
##########################################################################################
##########################################################################################
#
# Instructions:
#
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure and implement callbacks in this file
# 4. If you need boot scripts, add them into common/post-fs-data.sh or common/service.sh
# 5. Add your additional or modified system properties into common/system.prop
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=true

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=true

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
REPLACE="
"

##########################################################################################
#
# Function Callbacks
#
# The following functions will be called by the installation framework.
# You do not have the ability to modify update-binary, the only way you can customize
# installation is through implementing these functions.
#
# When running your callbacks, the installation framework will make sure the Magisk
# internal busybox path is *PREPENDED* to PATH, so all common commands shall exist.
# Also, it will make sure /data, /system, and /vendor is properly mounted.
#
##########################################################################################
##########################################################################################
#
# The installation framework will export some variables and functions.
# You should use these variables and functions for installation.
#
# ! DO NOT use any Magisk internal paths as those are NOT public API.
# ! DO NOT use other functions in util_functions.sh as they are NOT public API.
# ! Non public APIs are not guranteed to maintain compatibility between releases.
#
# Available variables:
#
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Availible functions:
#
# ui_print <msg>
#     print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#     print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     this function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     for all files in <directory>, it will call:
#       set_perm file owner group filepermission context
#     for all directories in <directory> (including itself), it will call:
#       set_perm dir owner group dirpermission context
#
##########################################################################################
##########################################################################################
# If you need boot scripts, DO NOT use general boot scripts (post-fs-data.d/service.d)
# ONLY use module scripts as it respects the module status (remove/disable) and is
# guaranteed to maintain the same behavior in future Magisk releases.
# Enable boot scripts by setting the flags in the config section above.
##########################################################################################

# Set what you want to display when installing your module

print_modname() {
  ui_print "*******************************"
  ui_print "         安装 Xray-core        "
  ui_print "*        Magisk Module        *"
  ui_print "          作者: Cmite          "
  ui_print "*******************************"
}

# Copy/extract your module files into $MODPATH in on_install.

on_install() {
  # The following is the default implementation: extract $ZIPFILE/system to $MODPATH
  # Extend/change the logic to whatever you want

  ui_print "* Detected arch: $ARCH"
  ui_print "+ Extracting package contents..."
  ui_print "+ ============================ +"
  ui_print "+ ============================ +"

  if [[ $ARCH != "arm64" ]]; then
    ui_print "Only Support arm64"
    return 1
  fi
  touch $MODPATH/access.log
  touch $MODPATH/error.log
  CONFIG_PATH="/sdcard/Documents/Configs/Xray/"
  tag=$(wget -qO- -t5 -T10 "https://api.github.com/repos/xtls/Xray-core/releases/latest" | grep "tag_name" | head -n 1 | awk -F ':' '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
  if [ -z $tag ]; then
    unzip -j -o "${ZIPFILE}" "bin/*.zip" -d ${MODPATH}
    localTag=$(ls ${MODPATH}/*.zip | awk -F '-' '{print $NF}' | sed 's/\.zip//g')
    ui_print "!!! Cannot download the latest Xray-core, we will use the local Xray-core(${localTag})."
    mv ${MODPATH}/*.zip ${MODPATH}/xray.zip
  else
    ui_print "+ latest version is ${tag}"
    wget -O $MODPATH/xray.zip "https://github.com/xtls/Xray-core/releases/download/${tag}/Xray-android-arm64-v8a.zip"
  fi
  unzip -o $MODPATH/xray.zip -d $MODPATH
  rm $MODPATH/xray.zip
}

# Only some special files require specific permissions
# This function will be called after on_install is done
# The default permissions should be good enough for most cases

set_permissions() {
  # The following is the default rule, DO NOT remove
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm $MODPATH/xray 0 0 0755
  set_perm $MODPATH/access.log 00 0664
  set_perm $MODPATH/error.log 00 0664

  ui_print "✓ Now no need to reboot..."
  ui_print "+ Attempting to start Xray-core"
  ui_print "+ please wait..."
  ui_print ""

  if [[ -e "${CONFIG_PATH}config.json" ]]; then
      cp -af ${CONFIG_PATH}config.json $MODPATH/config.json
      sed -i "s|\"access\": .*|\"access\": \"${MODPATH}/access.log\",|g" "$MODPATH/config.json"
      sed -i "s|\"error\": .*|\"error\": \"${MODPATH}/error.log\",|g" "$MODPATH/config.json"
      set_perm $MODPATH/config.json 00 0644
      $MODPATH/xray run -config $MODPATH/config.json 2>&1 &
      sleep 5
      if [[ -e "$MODPATH/config.json" ]]; then
        cat "$MODPATH"/error.log
        sed -i 's/\[.*\]/\[ Xray 核心正常工作中 \]/g' "$MODPATH/module.prop" > /dev/null 2>&1
        ui_print "Xray 启动完成..."
      else
        sed -i 's/\[.*\]/\[ Xray 未运行 \]/g' "$MODPATH/module.prop" > /dev/null 2>&1
        ui_print "Xray 启动失败..."
        ui_print "[!] 请确认配置文件后重新启动"
      fi
  else
    sed -i 's/\[.*\]/\[ 配置文件丢失，请重新设置配置文件 \]/g' "$MODPATH/module.prop" > /dev/null 2>&1
    ui_print "{$CONFIG_PATH}config.json 配置文件不存在"
    ui_print ""
    ui_print "[!] 请确认配置文件后重新启动"
  fi
}

# You can add more functions to assist your custom script code