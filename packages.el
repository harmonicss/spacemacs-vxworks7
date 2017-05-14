;;;
;;; packages.el - spacemacs layer to build and configure vxworks-7 images
;;;

;; Copyright 2015-2017 Harmonic Software Systems Ltd

;; Author : Ed Liversidge, Harmonic Software Systems Ltd
;; URL:
;; Version: 0.2 - updated for spacemacs
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
;; As a plus, combining with ecb (emacs code browser), gtags and semantic, it
;; is possible to quickly navigate through the vxworks source code. 
;;

;;
;; INSTALLATION
;;
;; 1. Setup the vxworks environment file
;;
;;   Two emacs lisp files are required:
;;      a. vxworks7.el      - general lisp functions
;;      b. vxworks7env.el  - specific setup for a vxworks 7 installation
;;  
;;   The vxworks7env.el file should be checked with your specific VxWorks
;;   installation, as compiler versions could have changed.
;;  
;;   To do this, open a vxworks development shell and type:
;;  
;;     wrenv -p vxworks-7 -o print_env
;;  
;;   Make sure the the environment in the shell matches the environment setup
;;   in vxworks7env.el. Could probaly write some lisp code to execute this and
;;   generate the env file automatically, but for now this is a manual process. 
;;
;;   The vxworks7env.el file should be in the WIND_HOME installation directory:
;;
;;     e.g. C:/WindRiver_vxw7
;;
;; 2. Edit .emacs
;;
;;   add the following to your .emacs file:
;;  
;;   (load-file "<path-to-file>/vxworks7.el")
;;   (setq vxworks-install-dir "<your vxworks install dir - with a trailing slash!>")
;;   (setq vxworks-workspace-dir "<your workspace directory - with a trailing slash!>")
;;   (setup-vxworks-7-env) 
;;
;;  for example:
;;
;;   (load-file "~/.emacs.d/lisp/vxworks7.el")
;;   (setq vxworks-install-dir "C:/WindRiver_vxw7.0/")
;;   (setq vxworks-workspace-dir "C:/WindRiver_vxw7.0/workspace/")
;;   (setup-vxworks-7-env) 
;;
;; if you dont set vxworks-install-dir you will be asked for it at startup
;;
;; ISSUES
;;
;; Currently this code makes a few assumptions:
;;  - vxworks7env.el exists and is in WIND_HOME
;;
;; where WIND_HOME is your WindRiver installation directory
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
    vxworks7
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

(defvar vxworks-vsb nil
  "the VxWorks Source Build to be created or built")

(defvar vxworks-vip nil
  "the VxWorks Image Project to be created or built")

(defvar vxworks-dkm nil
  "the VxWorks Downloadable Kernel Module to be created or built")

(defvar vxworks-component-list nil
  "a list of strings of VIP components. Output from wrtool")

(defvar vxworks-bsp-list nil
  "a list of strings of BSPs. Output from wrtool")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; ENTRY POINT - call this first
;;
;; setup functions, setting up vxworks environment and some keys
;; Note that is relies on a vxworks7env.el file, which is specific
;; to a Workbench installation.
;;
(defun vxworks7/init-vxworks7 ()
  "Sets up the vxworks environment for building vxWorks 7 images"
  (interactive)
  (if (eq vxworks-install-dir nil)
      (call-interactively 'vxworks-set-install-dir vxworks-install-dir))
  (if (eq vxworks-workspace-dir nil)
      (call-interactively 'vxworks-set-workspace-dir vxworks-workspace-dir))
  ;; Im hoping config.el does all this now
  ;; (setq load-dir-file (format "%svxworks7env.el" vxworks-install-dir))
  ;; (load-file load-dir-file)
  ;; change these to evilified-state-evilify?
  (global-set-key [f10] 'vxworks-compile-vip)
  (global-set-key [(shift f10)] 'vxworks-compile-vsb)
  (global-set-key [(control f10)] 'vxworks-compile-this-vsb-file)
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; vsb code
;;

(defun vxworks-set-vsb ()
  "Set the current VxWorks Source Build (VSB) to point to a directory in the 
current workspace. Note that no checking is made to make sure a VSB had been 
selected."
  (interactive)
  (set-workspace-project-list)
  (setq vxworks-vsb (completing-read
                       "Select a VSB: "
                       vxworks-workspace-projects nil t "")))

(defun vxworks-compile-vsb ()
  "Cds to the VxWorks 7 VSB and compiles it."
  (interactive)
  (if (eq vxworks-vsb nil)
      (call-interactively 'vxworks-set-vsb vxworks-vsb))
  (setq this-buffer-dir default-directory)
  (setq compile-dir (format "%s" vxworks-workspace-dir vxworks-vsb))
  (cd compile-dir)
  (setq compile-command "make JOBS=8")
  (call-interactively 'compile)
  (cd this-buffer-dir))

;; TODO update to select compiler
(defun vxworks-compile-this-vsb-file ()
  "Compiles this file (and any modifed files in this directory) in the VSB, 
with debug enabled. Currently fixed for diab compiler."
  (interactive)
  (if (eq vxworks-vsb nil)
      (call-interactively 'vxworks-set-vsb vxworks-vsb))
  (setq this-buffer-dir default-directory)
  (setq compile-command (format "make CPU=PPCE500V2 ADDED_CFLAGS+=\"-g -Xoptimized-debug-off\" TOOL=diab VSB_DIR=%s%s" vxworks-workspace-dir vxworks-vsb))
  (call-interactively 'compile)
  (cd this-buffer-dir))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; vip code
;;

(defun vxworks-set-vip ()
  "Set the current VxWorks Image Project (VIP) to point to a directory in the 
current workspace. Note that no checking is made to make sure a VIP has been 
selected."
  (interactive)
  (set-workspace-project-list)
  (setq vxworks-vip (ido-completing-read
                       "Select a VIP: "
                       vxworks-workspace-projects nil t "")))

;; If this VIP has a DKM associated with it, a build using wrtool wont work
;; because of limitations with wrtool. In this case you can replace the build
;; command in the minibuffer with this :
;;
;;  make BUILD_SPEC=default DEBUG_MODE=0 TRACE=1 JOBS=4
;;
(defun vxworks-compile-vip ()
  "Cds to the VIP directory and builds the VxWorks VIP image using wrtool. "
  (interactive)
  (if (eq vxworks-vip nil)
      (call-interactively 'vxworks-set-vip vxworks-vip))
  (if (eq vxworks-target nil)
      (call-interactively 'vxworks-set-target vxworks-target))
  (setq this-buffer-dir default-directory)
  (setq compile-dir (format "%s%s" vxworks-workspace-dir vxworks-vip))
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
  (setq vxworks-project (ido-cmpleting-read
						 "Select a Project to add the file to: "
						 vxworks-workspace-projects))
  (setq this-buffer-dir default-directory)
  (setq compile-dir (format "%s" vxworks-workspace-dir))
  (cd compile-dir)
  (message "Adding %s to %s" s vxworks-project)
  (shell-command (format "wrtool -data %s prj file add %s %s"
                         vxworks-workspace-dir s vxworks-project))
  (find-file (format "%s%s/%s" vxworks-workspace-dir vxworks-project s))
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
  (if (eq vxworks-vsb nil)
      (call-interactively 'vxworks-set-vsb vxworks-vsb))
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
  (setq vxworks-vip vip-to-create) 
  (cd this-buffer-dir))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; VIP componenent code
;;

(defun vxworks-vip-component-add ()
  "Add a component to the current VIP"
  (interactive)
  (if (eq vxworks-vip nil)
      (call-interactively 'set-vip vxworks-vip))
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
                  vxworks-workspace-dir vxworks-workspace-dir vxworks-vip vip-component-to-add))
  (message "Done")
  (cd this-buffer-dir)
  ;; display results
  (switch-to-buffer "*Shell Command Output*"))

(defun vxworks-vip-component-remove ()
  "Remove a component from the current VIP"
  (interactive)
  (if (eq vxworks-vip nil)
      (call-interactively 'set-vip vxworks-vip))
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
                         vxworks-workspace-dir vxworks-workspace-dir vxworks-vip vip-component-to-remove))
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
  (if (eq vxworks-vip nil)
      (call-interactively 'set-vip vxworks-vip))
  (setq this-buffer-dir default-directory)
  (cd vxworks-workspace-dir)
  (message "Scanning VIP %s for components. Please wait..." vxworks-vip)
  (setq vxworks-component-list-shell-output
        (shell-command-to-string
         (format "wrtool -data %s prj vip component list %s%s all"
                 vxworks-workspace-dir vxworks-workspace-dir vxworks-vip)))
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; auto configure semantic to look for vxworks header files
;;
;; this is quite specific to versioned directories
;; doesnt include any rtp code yet.
;; 
;; calling from my .emacs doesnt seem to work. Seems that it only works when a
;; target file is in the buffer. 
;;
;; can check with (semantic-c-describe-environment)
;;
;; NOTE: dont really need this if semantic is working with GTAGS
;;
(defun setup-vxworks-includes ()
  "Adds vxworks include paths to semantic"
  (interactive)
  (if (eq semantic-mode t)
      (progn
        (semantic-add-system-include
         (format "%svxworks-7/pkgs/os/core/kernel-1.0.9.0/h" vxworks-install-dir) 'c-mode)
        (semantic-add-system-include
         (format "%svxworks-7/pkgs/os/core/io-1.0.1.3/h" vxworks-install-dir) 'c-mode))))


;;; vxworks.el ends here
