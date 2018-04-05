;;;
;;; packages.el - spacemacs layer to build and configure vxworks-7 images
;;;

;; Copyright 2015-2018 Harmonic Software Systems Ltd

;; Author : Ed Liversidge, Harmonic Software Systems Ltd
;; URL: harmonicss.co.uk
;; Version: 0.3
;; Package-Requires:

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 2, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License along with
;; GNU Emacs; see the file COPYING.  If not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

;;
;; ABOUT
;;
;; VxWorks is a Real Time Operating System developed by Wind River. Wind River
;; ships the Eclipse development environment (called Workbench) which configures
;; and builds the VxWorks Source Build (VSB) and VxWorks Image Project (VIP) to
;; produce a single VxWorks executable for a target system.
;;
;; This code is specific to VxWorks-7 but by using vxprj instead of wrtool, it
;; is easy to get it to work with the previous VxWorks 6 or 653 versions. 
;;
;; By providing an emacs library, it becomes possible to build and configure
;; vxworks code from the touch of a button, rather than dragging the mouse
;; and wasting valuable time.
;;
;; As a plus, combining with helm, gtags and semantic, it
;; is possible to quickly navigate through the vxworks source code.
;;

;;
;; INSTALLATION for SPACEMACS
;;
;; 1. Edit .spacemacs
;;
;;    enable in your ~/.spacemacs by adding vxworks7 to dotspacemacs-configuration-layers
;;
;; 2. Restart Spacemacs to load the new config
;;
;; 3. Create the vxworks7env.el script from wrenv.
;;
;;    * NOTE * This only needs to be done once for each VxWorks install.
;;
;;    SPC : execute-wrenv
;;
;;    This will prompt for the vxworks-install-dir, which should be set to your
;;    vxworks installation directory, e.g. c:\WindRiver_vxw7.0
;;
;;    The vxworks7env.el file will be auto created in this directory, by executing
;;    wrenv and parsing into emacs lisp environment varibles.
;;
;; 4. Call the setup to use
;;
;;    SPC : setup-vxworks7-env
;;
;;    e.g.
;;
;;    SPC-: (or SPC SPC for v0.2 or higher)
;;
;;    setup-vxworks6-env
;;
;; if you dont set vxworks-install-dir you will be asked for it at startup
;;
;; ISSUES
;;
;;
;; The code does not detect if your WindRiver installation is not licenced.
;; Things just wont work, so make sure the installation is licensed first.
;;
;; Also, there are a few issues:
;;  - Older versions of wrtool (earlier than v4.3.0) when calling
;;    'wrtool prj vip create' will result in wrtool returning a
;;    vague project creation error.
;;
;;  - Not tested on Linux
;;
;;
;; TODO
;;
;; - Add a JOBS option for host multicore builds
;;
;; - Add compiler option for GNU as well as DIAB
;;
;; - investigate getting GDB to work with a VxWorks target
;; 

(defconst vxworks7-packages
  '(
    ))


(setq debug-on-error t)

;; variables, these can be overridden in your .emacs file

(defvar vxworks-install-dir nil 
  "the VxWorks directory i.e. 
WIND_HOME (e.g. \"C:\/WindRiver_vxw7.0\/\" needs a trailing slash)")

(defvar vxworks-workspace-dir nil
  "the workspace directory")

(defvar vxworks-target "uVxWorks"
  "the vxWorks target to build, e.g. uVxWorks vxWorks vxWorks.bin")

(defvar vxworks-vip-bsp nil
  "the default BSP that we are going to use to create the VIP")

(defvar vxworks-vip-profile "PROFILE_DEVELOPMENT"
  "the profile to use for building the VIP")

(defvar vxworks-vsb-dir nil
  "the VxWorks Source Build directory to be created or built")

(defvar vxworks-vip-dir nil
  "the VxWorks Image Project directory to be created or built")

(defvar vxworks-dkm nil
  "the VxWorks Downloadable Kernel Module to be created or built")

(defvar vxworks-component-list nil
  "a list of strings of VIP components. Output from wrtool")

(defvar vxworks-compiler "gnu"
  "the VxWorks compiler to use gnu or diab.")

(defvar vxworks-cpu "PPC32"
  "the VxWorks target CPU e.g. NEHALEM, VXATOM, PPC85XX PPC32")

(defvar vxworks-cpu-variant "_ppc85XX_e6500"
  "the VxWorks target CPU variant")

(defvar vxworks-bsp-list nil
  "a list of strings of BSPs. Output from wrtool")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; INITIAL SETUP - call this ONCE for each new VxWorks install
;;
;; This will call wrenv and create a vxworks6env.el file, which will be read 
;; by spacemacs to setup the enviroment for building vxWorks code. 
;;
(defun execute-wrenv ()
  "Executes wrenv and opens the resulting text file for processing"
  (interactive)
  (if (eq vxworks-install-dir nil)
      (call-interactively 'vxworks-set-install-dir vxworks-install-dir))
  (setq default-directory vxworks-install-dir)

  (if (eq system-type 'gnu/linux)
      (call-process (format "%s/wrenv.sh" vxworks-install-dir) nil "vxworks7env.el" nil "-p" "vxworks-7" "-f" "bat" "-o" "print_env")
    ;; default to windows
    (call-process "wrenv" nil "vxworks7env.el" nil "-p" "vxworks-6.9" "-f" "bat" "-o" "print_env"))
  (convert-file-to-emacs-env))

(defun convert-line-to-emacs-env ()
  "Converts the current line to an emacs setenv string"

  ;;  change:
  ;;    set Path=C:\WindRiver_vx
  ;;  to:
  ;;    (setenv "PATH" "C:\...)
  ;;

  (beginning-of-line)
  (if (search-forward "set" nil t)
      (progn 
        (backward-char 3)
        (insert "(")
        (forward-char 3)
        (insert "env")
        (forward-char 1)
        (insert "\"")
        (search-forward "=" nil t)
        (backward-char 1)
        (delete-char 1)
        (insert "\" \"")
        (end-of-line)
        (insert "\")"))))

(defun convert-file-to-emacs-env ()
  "Converts the output from wrenv to emacs setenv format"
  (interactive)
  (with-current-buffer "vxworks7env.el"
    (goto-char (point-min))
    (convert-line-to-emacs-env)
    (while (= 0 (forward-line 1))
      (convert-line-to-emacs-env))

    ;; replace \ with /
    (goto-char (point-min))
    (while (search-forward "\\" nil t)
        (progn
          (backward-char 1)
          (delete-char 1)
          (insert "/")))

    ;; replace 'Path' with 'PATH'
    (goto-char (point-min))
    (search-forward "Path" nil t)
    (replace-match "PATH")

    ;; insert some comments
    (goto-char (point-min))
    (insert ";;\n")
    (insert (format ";; VxWorks Enviroment for %s, for Spacemacs\n" vxworks-install-dir))
    (insert (format ";; Created %s\n" (current-time-string)))
    (insert ";;\n")

    (write-file "vxworks7env.el")))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; ENTRY POINT - call this to use (make sure vxworks6env.el has been created)
;;
;; setup functions, setting up vxworks environment and some keys
;; Note that is relies on a vxworks7env.el file, which is specific
;; to a Workbench installation.
;;
(defun setup-vxworks7-env ()
  "Sets up the vxworks environment for building vxWorks 7 images"
  (interactive)
  ;; check we have vxworks7env.el
  (if (eq vxworks-install-dir nil)
      (call-interactively 'vxworks-set-install-dir vxworks-install-dir))
  (setq default-directory vxworks-install-dir)
  (if (eq (file-exists-p "vxworks7env.el") nil)
      (error "Need to create vxworks7env.el first. Call 'SPC : execute-wrenv'"))
  (if (eq vxworks-workspace-dir nil)
      (call-interactively 'vxworks-set-workspace-dir vxworks-workspace-dir))
  ;; set the default directory, to allow the rest of the code to start here. 
  (setq load-dir-file (format "%svxworks7env.el" vxworks-install-dir))
  (load-file load-dir-file)
  (global-set-key [f10] 'vxworks-compile-vip)
  (global-set-key [(shift f10)] 'vxworks-compile-vsb)
  (global-set-key [(control f10)] 'vxworks-compile-this-vsb-file))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; vsb code
;;

(defun vxworks-set-vsb (D)
  "Set the current VxWorks Source Build (VSB) to point to a directory in the 
current workspace. Note that no checking is made to make sure a VSB had been 
selected."
  (interactive "DSelect a VSB: ")
  (setq vxworks-vsb-dir D))


(defun vxworks-compile-vsb ()
  "Cds to the VxWorks 7 VSB and compiles it."
  (interactive)
  (if (eq vxworks-vsb-dir nil)
      (call-interactively 'vxworks-set-vsb vxworks-vsb-dir))
  (setq this-buffer-dir default-directory)
  (setq compile-dir vxworks-vsb-dir)
  (cd compile-dir)
  (setq compile-command "make JOBS=8")
  (call-interactively 'compile)
  (cd this-buffer-dir))

(defun vxworks-create-vsb ()
  "Creates a VSB, specific for CERT VSB, using linux only python build script"
  (interactive)
  (setq this-buffer-dir default-directory)
  (setq compile-dir vxworks-workspace-dir)
  (cd compile-dir)
  (setq compile-command "$WIND_BASE/pkgs/test/cert-tests/cert-scripts/build_tool/buildCertVsb.sh fsl_t1 -debug")
  (call-interactively 'compile)
  (cd this-buffer-dir))

;; diab flag: -g -Xoptimized-debug-off
(defun vxworks-compile-this-vsb-file ()
  "Compiles this file (and any modifed files in this directory) in the VSB,
current for SMP, with debug enabled."
  (interactive)
  (if (eq vxworks-vsb-dir nil)
      (call-interactively 'vxworks-set-vsb vxworks-vsb-dir))
  (setq this-buffer-dir default-directory)
  ;; this is without CPU variant and SMP
  ;;(setq compile-command (format "make CPU=%s ADDED_CFLAGS+=\"-g -O0\" TOOL=%s VSB_DIR=%s" vxworks-cpu vxworks-compiler vxworks-vsb-dir))
  ;; this is with CPU variant and SMP
  (setq compile-command (format "make CPU=%s CPU_VARIANT=%s VXBUILD=SMP ADDED_CFLAGS+=\"-g -O0\" TOOL=%s VSB_DIR=%s" vxworks-cpu vxworks-cpu-variant vxworks-compiler vxworks-vsb-dir))
  (call-interactively 'compile)
  (cd this-buffer-dir))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; vip code
;;

(defun vxworks-set-vip (D)
  "Set the current VxWorks Image Project (VIP) to point to a directory in the
current workspace. Note that no checking is made to make sure a VIP has been
selected."
  (interactive "DSelect a VIP: ")
  (setq vxworks-vip-dir D))


;; If this VIP has a DKM associated with it, a build using wrtool wont work
;; because of limitations with wrtool. In this case you can replace the build
;; command in the minibuffer with this :
;;
;;  make BUILD_SPEC=default DEBUG_MODE=0 TRACE=1 JOBS=4
;;
(defun vxworks-compile-vip ()
  "Cds to the VIP directory and builds the VxWorks VIP image using make. "
  (interactive)
  (if (eq vxworks-vip-dir nil)
      (call-interactively 'vxworks-set-vip vxworks-vip-dir))
  (if (eq vxworks-target nil)
      (call-interactively 'vxworks-set-target vxworks-target))
  (setq this-buffer-dir default-directory)
  (setq compile-dir vxworks-vip-dir)
  (cd compile-dir)
  (setq compile-command (concat "wrtool -data " vxworks-workspace-dir " prj vip build " vxworks-target)) 
  (call-interactively 'compile)
  (cd this-buffer-dir))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; setters
;;
;; call these functions to change build and config parameters
;;

;; this will add the required trailing slash
(defun vxworks-set-install-dir (D)
  (interactive "DVxWorks Install Directory: ") 
  (setq vxworks-install-dir D))

;; this will add the required trailing slash
(defun vxworks-set-workspace-dir (D)
  (interactive "DWorkspace Directory: ") 
  (setq vxworks-workspace-dir D))

;; TODO select from a list : uVxWorks, vxWorks, vxWorks.bin
(defun vxworks-set-target (s)
  (interactive "sVxWorks Target: ")
  (setq vxworks-target s))

;; TODO select from list
(defun vxworks-set-vip-profile (s)
  (interactive "sVxWorks Profile: ")
  (setq vxworks-vip-profile s))

;; sets a BSP to be associated with a VIP build e.g. fsl_t1_1_0_1_1
(defun vxworks-set-vip-bsp ()
  (interactive)
  (if (eq vxworks-bsp-list nil)
      (set-vip-bsp-list))
  (setq vxworks-vip-bsp (ido-completing-read
                         "Select a BSP: "
                         vxworks-bsp-list)))
       

(defun vxworks-add-file (s)
  "Adds the specified file to a specified project. wrtool will create the file 
if it does not already exist."
  (interactive "sName of file: ")
  (set-workspace-project-list)
  (setq vxworks-project (ido-completing-read
                         "Select a Project to add the file to: "
                         vxworks-workspace-projects))
  (setq this-buffer-dir default-directory)
  (setq compile-dir (format "%s%s" vxworks-workspace-dir vxworks-project))
  (cd compile-dir)
  (message "compile-dir %s" compile-dir)
  (find-file (format "%s%s/%s" vxworks-workspace-dir vxworks-project s))
  (message "Adding %s to %s" s compile-dir)
  (shell-command (format "vxprj file add %s" s))
  (cd this-buffer-dir))

(defun vxworks-delete-file (s)
  "Remove the specified file from a specified project. This will delete the file!"
  (interactive "sName of file: ")
  (set-workspace-project-list)
  (setq vxworks-project (ido-completing-read
                         "Select a Project to delete the file from: "
                         vxworks-workspace-projects))
  (setq this-buffer-dir default-directory)
  (setq compile-dir (format "%s" vxworks-workspace-dir))
  (cd compile-dir)
  (message "Deleting %s from %s" s vxworks-project)
  (shell-command (format "wrtool -data %s prj file delete %s %s"
                         vxworks-workspace-dir s vxworks-project))
  (cd this-buffer-dir))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Subproject management
;;

(defun vxworks-add-subproject-to-project ()
  "Associates an existing project \(e.g. a DKM\) as a subproject to an existing project 
\(e.g.\) a VIP."
  (interactive)
  (set-workspace-project-list)
  (setq vxworks-subproject (ido-completing-read
                            "Select a Sub Project: "
                            vxworks-workspace-projects))
  (setq vxworks-project (ido-completing-read
                         "Select a Project to associate the Sub Project to: "
                         vxworks-workspace-projects))
  (setq this-buffer-dir default-directory)
  (setq compile-dir (format "%s" vxworks-workspace-dir))
  (cd compile-dir)
  (message "Associating sub project %s with project %s" vxworks-subproject vxworks-project)
  (shell-command (format "wrtool -data %s prj subproject add %s %s"
                         vxworks-workspace-dir vxworks-subproject vxworks-project))
  (cd this-buffer-dir))
  
  
(defun vxworks-remove-subproject-from-project ()
  "Removes an existing subproject \(e.g. a DKM\) from an existing project 
\(e.g.\) a VIP."
  (interactive)
  (set-workspace-project-list)
  (setq vxworks-subproject (ido-completing-read
                            "Select a Sub Project: "
                            vxworks-workspace-projects))
  (setq vxworks-project (ido-completing-read
                         "Select a Project from which to remove the sub project: "
                         vxworks-workspace-projects))
  (setq this-buffer-dir default-directory)
  (setq compile-dir (format "%s" vxworks-workspace-dir))
  (cd compile-dir)
  (message "Removing  sub project %s from project %s" vxworks-subproject vxworks-project)
  (shell-command (format "wrtool -data %s prj subproject remove %s %s"
                         vxworks-workspace-dir vxworks-subproject vxworks-project))
  (cd this-buffer-dir))
  




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; DKM (Downloadable kernel module) Functions
;;
;;
;; This sufferes from ERROR: Project creation failed. 
;;

(defun vxworks-set-dkm ()
  "Set the current Downloadable Kernel Module (DKM) to point to a directory in the 
current workspace. Note that no checking is made to make sure a DKM has been 
selected."
  (interactive)
  (set-workspace-project-list)
  (setq vxworks-dkm (ido-completing-read
                     "Select a DKM: "
                     vxworks-workspace-projects nil t "")))


(defun vxworks-create-dkm (s)
  "Create a DKM in the workspace directory"
  (interactive "sVxWorks DKM to create: ")
  (setq vxworks-dkm s)
  (if (eq vxworks-vip-dir nil)
      (call-interactively 'vxworks-set-vip vxworks-vip-dir))
  (setq this-buffer-dir default-directory)
  (setq compile-dir (format "%s" vxworks-workspace-dir))
  (cd compile-dir)
  (shell-command (format "wrtool -data %s prj dkm create -force -vsb %s %s"
                         vxworks-workspace-dir vxworks-vsb vxworks-dkm))
  (cd this-buffer-dir))

;;
;; This is only good for building standalone DKMs (because of limitations with wrtool)
;;
(defun vxworks-compile-dkm ()
  "Compiles the currently selected DKM."
  (interactive)
  (if (eq vxworks-dkm nil)
      (call-interactively 'vxworks-set-dkm vxworks-dkm))
  (setq this-buffer-dir default-directory)
  (setq compile-dir (format "%s%s" vxworks-workspace-dir vxworks-dkm))
  (cd compile-dir)  
  (setq compile-command (format "wrtool -data %s prj build" vxworks-workspace-dir))
  (call-interactively 'compile)
  (cd this-buffer-dir))

  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; VIP creation function
;;
;; wrtool prj vip create doesnt work from emacs shell for some
;; wrtool versions (< 4.3.0?)
;;
;; So can resort to vxprj. Also, vxprj wont create a WB aware project,
;; it cannot be imported.  
;;

(defun vxworks-create-vip (vip-to-create)
  "Creates from scratch the specified VIP (VxWorks Image Project). 
Sets the current vip to this one. "
  (interactive "sName of VIP to create: ")
  (if (eq vxworks-vsb nil)
      (call-interactively 'vxworks-set-vsb vxworks-vsb))
  (if (eq vxworks-vip-bsp nil)
      (call-interactively 'vxworks-set-vip-bsp vxworks-vip-bsp))
  (setq this-buffer-dir default-directory)
  (setq compile-dir (format "%s" vxworks-workspace-dir))
  (cd compile-dir)
  (setq compile-command (format "wrtool -data %s prj vip create -force -debug -profile %s -vsb %s %s diab %s"
                                vxworks-workspace-dir vxworks-vip-profile
                                vxworks-vsb vxworks-vip-bsp vip-to-create))
  ;;(setq compile-command (format "vxprj create -force -debug -profile %s -vsb %s %s diab %s" vxworks-vip-profile vxworks-vsb vxworks-vip-bsp vip-to-create))
  (call-interactively 'compile)
  (setq vxworks-vip-dir vip-to-create) 
  (cd this-buffer-dir))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; VIP componenent code
;;

(defun vxworks-vip-component-add ()
  "Add a component to the current VIP"
  (interactive)
  (if (eq vxworks-vip-dir nil)
      (call-interactively 'set-vip vxworks-vip-dir))
  ;; TODO change this to detect if this is a new VIP and rescan
  ;; calling set-vip-components-list
  (if (eq vxworks-component-list nil)
      (set-vip-component-list))
  (setq this-buffer-dir default-directory)
  (cd vxworks-workspace-dir)
  (setq vip-component-to-add (ido-completing-read
                              "Add a Component: "
                              vxworks-component-list nil t ""))
  (message "Adding component %s. Please wait..." vip-component-to-add)
  (shell-command (format "wrtool -data %s prj vip component add %s%s %s"
                  vxworks-workspace-dir vxworks-workspace-dir vxworks-vip-dir vip-component-to-add))
  (message "Done")
  (cd this-buffer-dir)
  ;; display results
  (switch-to-buffer "*Shell Command Output*"))

(defun vxworks-vip-component-remove ()
  "Remove a component from the current VIP"
  (interactive)
  (if (eq vxworks-vip-dir nil)
      (call-interactively 'set-vip vxworks-vip-dir))
  ;; TODO change this to detect if this is a new VIP and rescan
  ;; calling set-vip-components-list
  (if (eq vxworks-component-list nil)
      (set-vip-component-list))
  (setq this-buffer-dir default-directory)
  (cd vxworks-workspace-dir)
  (setq vip-component-to-remove (ido-completing-read
                                 "Remove a Component: "
                                 vxworks-component-list nil t ""))
  (message "Removing component %s. Please wait..." vip-component-to-remove)
  (shell-command (format "wrtool -data %s prj vip component remove %s%s %s"
                         vxworks-workspace-dir vxworks-workspace-dir vxworks-vip-dir vip-component-to-remove))
  (message "Done")
  (cd this-buffer-dir)
  ;; display results
  (switch-to-buffer "*Shell Command Output*"))

;; TODO vip-component-list-included

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; wrtool functions
;;
;; execute wrtool and parse results for meaningful emacs interaction.
;; wrtool can be quite slow (30s) so once vxworks-component-list is set
;; we dont want to call this function again, unless you have changed to
;; building a different VIP. 
;;

(defun set-vip-bsp-list ()
  "Get a list of possible BSPs that we can build a VIP from"
  (interactive)
  (setq this-buffer-dir default-directory)
  (cd vxworks-workspace-dir)
  (message "Scanning for BSPs. Please wait...")
  (setq vxworks-bsp-list-shell-output
        (shell-command-to-string
         (format "wrtool -data . prj vip listBsps")))
  (setq vxworks-bsp-list (split-string vxworks-bsp-list-shell-output))
  ;; need to remove first two elements : "Valid" and "BSPs". This was
  ;; spouted out by wrtool
  (setq vxworks-bsp-list (cdr vxworks-bsp-list))
  (setq vxworks-bsp-list (cdr vxworks-bsp-list))
  (message "Done")
  (cd this-buffer-dir)) 
  
(defun set-vip-component-list ()
  "Get a list of possible components from a VIP as a list of strings. Note, wrtool 
   can be quite slow (30s) to produce results. "
  (interactive)
  (if (eq vxworks-vip-dir nil)
      (call-interactively 'set-vip vxworks-vip-dir))
  (setq this-buffer-dir default-directory)
  (cd vxworks-workspace-dir)
  (message "Scanning VIP %s for components. Please wait..." vxworks-vip-dir)
  (setq vxworks-component-list-shell-output
        (shell-command-to-string
         (format "wrtool -data %s prj vip component list %s%s all"
                 vxworks-workspace-dir vxworks-workspace-dir vxworks-vip-dir)))
  (setq vxworks-component-list (split-string vxworks-component-list-shell-output))
  (message "Done")
  (cd this-buffer-dir)) 

(defun set-workspace-project-list ()
  "Get a list of workspace projects from the wrtool as a list of strings."
  ;; refresh the workspace first, projects may have been deleted.
  ;; this causes java.lang.NullPointerException. Great. 
  ;;(shell-command (format "wrtool -data %s prj refresh" vxworks-workspace-dir))
  (message "Getting project list. Please wait...")
  (setq wrtool-prj-list-shell-output
        (shell-command-to-string (format "wrtool -data %s prj list"
                                         vxworks-workspace-dir))) 
  (message "Done")
  ;; delete everything from within brackets
  (strip-wrtool-prj-list-shell-output))

(defun strip-wrtool-prj-list-shell-output ()
  "take the string from wrtool prj list and get rid of all the guff in the brackets,
   returning a list of strings."
  (setq vxworks-workspace-projects nil)  
  (setq wrtool-prj-list-shell-output
        (replace-regexp-in-string "\n" " " wrtool-prj-list-shell-output))
  ;; s1 and s2 are local search indexes
  (let (s1 s2)
    (setq s1 0)    
    (setq s2 (string-match "(" wrtool-prj-list-shell-output))
    ;; move search one char to left, we dont want the (
    (setq s2 (- s2 1))
    (while (not (eq s2 nil))
      ;; concat the directory names, using substring to remove the stuff in the brackets
      (setq vxworks-workspace-projects (concat vxworks-workspace-projects
            (substring wrtool-prj-list-shell-output s1 s2)))
      ;; move the start point along for the next search
      (setq s1 (string-match ")" wrtool-prj-list-shell-output s2))
      ;; move search one char right, dont want )
      (setq s1 (+ 1 s1))
        (setq s2 (string-match "(" wrtool-prj-list-shell-output s1))
      )
    ;; now we have a big string, split them up
    (setq vxworks-workspace-projects (split-string vxworks-workspace-projects))))




;;; vxworks.el ends here
