;;
;; Setups up the paths for a vxWorks 7 installation. 
;;
;; requires code from vxworks.el
;;
;;

;; vxworks-install-dir should be like this:
;;    C:/WindRiver_vxw7.0/  <with a slash!>
;;
;;(if (eq vxworks-install-dir nil)
;;  (call-interactively 'get-vxworks-install-dir vxworks-install-dir))

(getenv "PATH")

(setenv "PATH"
  (concat
   vxworks-install-dir "workbench-4/tcl/x86-win32/bin;"
   vxworks-install-dir "vxworks-7/host/x86-win32/bin;"
   vxworks-install-dir "vxworks-7/pkgs/test/vxtestv2/bspvts/scripts;"
   vxworks-install-dir "vxworks-7/host/binutils/x86-win32/bin;"
   vxworks-install-dir ";"
   vxworks-install-dir "utilities/x86-win32/bin;"
   vxworks-install-dir "license/lmapi-5/x86-win32/bin;"
   vxworks-install-dir "workbench-4/wrsysviewer/host/x86-win32/bin;"
   vxworks-install-dir "workbench-4/eclipse/bin;"
   vxworks-install-dir "workbench-4/x86-win32/bin;"
   vxworks-install-dir "workbench-4;"
   vxworks-install-dir "compilers/gnu-4.3.3/x86-win32/bin;"
   vxworks-install-dir "compilers/icc/icc_vxworks_14.0.0.018/x86-win32/bin/ia32;"
   vxworks-install-dir "compilers/diab-5.9.4.5/WIN32/bin;"
   "C:/cygwin64/bin;"
   "C:/cygwin64/usr/local/bin;"))


(setenv "WIND_PREFERRED_PACKAGES"
    "vxworks-7")

(setenv "WIND_HOME"
    vxworks-install-dir)

(setenv "WIND_BASE"
    (concat vxworks-install-dir "vxworks-7"))

(setenv "WIND_DOCS"
    (concat vxworks-install-dir "vxworks-7/docs/"))

(setenv "WIND_DIAB_PATH"
    (concat vxworks-install-dir "compilers/diab-5.9.4.5"))

(setenv "WRSD_LICENSE_FILE"
    (concat vxworks-install-dir "license"))

(setenv "LM_A_APP_DISABLE_CACHE_READ"
		"set")

(setenv "WIND_TOOLCHAINS"
    "gnu;icc;diab")

(setenv "WIND_HOST_TYPE"
    "x86-win32")

(setenv "WIND_GNU_PATH"
    (concat vxworks-install-dir "compilers/gnu-4.8.1.4"))

(setenv "WIND_ICC_PATH"
    (concat vxworks-install-dir "compilers/icc/icc_vxworks_14.0.0.018"))


(setenv "IPPROOT"
    (concat vxworks-install-dir "compilers/icc/ipp_vxworks_8.0.1.018"))

(setenv "LD_LIBRARY_PATH"
    (concat 
    vxworks-install-dir "workbench-4/tcl/x86-win32/lib;"
    vxworks-install-dir "vxworks-7/host/x86-win32/lib;"
    vxworks-install-dir "license/lmapi-5/x86-win32/lib;"
    vxworks-install-dir "workbench-4/wrsysviewer/host/x86-win32/lib;"
    vxworks-install-dir "workbench-4/x86-win32/lib;"
    vxworks-install-dir "compilers/icc/icc_vxworks_14.0.0.018/x86-win32/bin/ia32"
    ))

(setenv "WIND_TOOLS"
    (concat vxworks-install-dir "workbench-4"))

(setenv "WIND_WRWB_PATH"
    (concat vxworks-install-dir "workbench-4/eclipse/x86-win32"))

(setenv "WIND_RPM"
    (concat vxworks-install-dir "workbench-4/eclipse"))

(setenv "APROBE"
    (concat vxworks-install-dir "workbench-4/x86-win32"))

(setenv "WIND_WRSV_PATH"
    (concat vxworks-install-dir "workbench-4/wrsysviewer"))

(setenv "FLEXLM_NO_CKOUT_INSTALL_LIC"
    "1")


(setenv "WIND_SAMPLES"
    (concat
    vxworks-install-dir "vxworks-7/samples/rtp;"
    vxworks-install-dir "vxworks-7/samples/dkm;"
    vxworks-install-dir "workbench-4/samples/vxworks7"
    ))

(setenv "WIND_UTILITIES"
    (concat vxworks-install-dir "utilities"))

(setenv "MANPATH"
    (concat vxworks-install-dir "vxworks-7/man"))

(setenv "WIND_BUILD"
    (concat vxworks-install-dir "vxworks-7/build"))

(setenv "WIND_PLATFORM"
    "vxworks-7.0")

(setenv "WIND_RSS_CHANNELS"
    "http://www.windriver.com/feeds/vxworks_660.xml")

(setenv "WIND_INTRO"
    (concat vxworks-install-dir "vxworks-7/gettingStarted/vxworks.properties"))

(setenv "WIND_KRNL_MK"
    (concat vxworks-install-dir "vxworks-7/build/mk/krnl"))

(setenv "WIND_USR_MK"
    (concat vxworks-install-dir "vxworks-7/build/mk/usr"))

(setenv "WIND_BUILD_TOOL"
    (concat vxworks-install-dir "vxworks-7/build/tool"))

(setenv "WIND_LAYER_PATHS"
    (concat vxworks-install-dir "vxworks-7/pkgs"))

(setenv "WIND_BSP_PATHS"
    (concat vxworks-install-dir "vxworks-7/pkgs/os/board"))

(setenv "WIND_VSB_PROFILE_PATHS"
    (concat vxworks-install-dir "vxworks-7/build/misc/bsp_profiles"))

(setenv "COMP_DSM_TOOLS"
    (concat vxworks-install-dir "vxworks-7/host/binutils"))

(setenv "OSCONFIG_PATH"
    (concat vxworks-install-dir "vxworks-7/build/osconfig"))

(setenv "WIND_COMPILER_PATHS"
    (concat vxworks-install-dir "compilers"))

(setenv "TCLLIBPATH"
    (concat vxworks-install-dir "vxworks-7/build/osconfig/tcl"))

(setenv "WIND_FOUNDATION_PATH"
    (concat vxworks-install-dir "workbench-4/tcl"))

(setenv "WIND_WRTOOL_WORKSPACE"
    (concat vxworks-install-dir "workspace"))
