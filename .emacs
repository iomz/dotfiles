;;;;;;;;;;;;;;;;;;;;
;; lisp
(setq inferior-lisp-program "sbcl")
;; auto-install
;; (add-to-list 'load-path "~/.emacs.d/auto-install/")
;; (require 'auto-install)
;; (auto-install-update-emacswiki-package-name t)
;; (auto-install-compatibility-setup)
;; (setq ediff-window-setup-function 'ediff-setup-windows-plain)

;;loads ruby mode when a .rb file is opened.
(autoload 'ruby-mode "ruby-mode" "Major mode for editing ruby scripts." t)
(setq auto-mode-alist  (cons '(".rb$" . ruby-mode) auto-mode-alist))
(setq auto-mode-alist  (cons '(".rhtml$" . html-mode) auto-mode-alist))

;;; open-junk-file
;(require 'open-junk-file)
;(global-set-key (kbd "C-x C-z") 'open-junk-file)

;;; lispxmp
;(require 'lispxmp)
;(define-key emacs-lisp-mode-map (kbd "C-c C-d") 'lispxmp)

;;; Parenthesis edit
;(require 'paraedit)
;(add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)
;(add-hook 'lisp-interaction-mode-hook 'enable-paredit-mode)
;(add-hook 'lisp-mode-hook 'enable-paredit-mode)
;(add-hook 'ielm-mode-hook 'enable-paredit-mode)

;;; Automatic compilation
;; (require 'auto-async-byte-compile)
;; (setq auto-async-byte-compile-exclude-files-regexp "/junk/")
;; (add-hook 'emacs-lisp-mode-hook 'enable-auto-async-byte-compile-mode)
;; (add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
;; (add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)
;; (add-hook 'ielm-mode-hook 'turn-on-eldoc-mode)
;; (setq eldoc-idle-delay 0.2)       ; rapid display
;; (setq eldoc-minor-mode-string "") ; hide ElDoc mode
;; (show-paren-mode 1)               ; compensate parenthesis
;; (global-set-key "C-m" 'newline-and-indent)
;; (find-function-setup-keys)

;;; set up unicode
(setq default-buffer-file-coding-system 'utf-8)
(set-language-environment "Japanese")
(prefer-coding-system       'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-buffer-file-coding-system 'utf-8-unix)

;;; From Emacs wiki
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))

;;; MS Windows clipboard is UTF-16LE
;; (set-clipboard-coding-system 'utf-16le-dos)

;;; ispell loader
;; (autoload 'ispell-word "ispell"
;;          "Check the spelling of word in buffer." t)
;;       (global-set-key "\e$" 'ispell-word)
;;       (autoload 'ispell-region "ispell"
;;          "Check the spelling of region." t)
;;       (autoload 'ispell-buffer "ispell"
;;          "Check the spelling of buffer." t)
;;       (autoload 'ispell-complete-word "ispell"
;;          "Look up current word in dictionary and try to complete it." t)
;;       (autoload 'ispell-change-dictionary "ispell"
;;          "Change ispell dictionary." t)
;;       (autoload 'ispell-message "ispell"
;;          "Check spelling of mail message or news post.")
;;       (autoload 'ispell-minor-mode "ispell"
;;          "Toggle mode to automatically spell check words as they are typed in.")

;;; Saving versions
(setq
   backup-by-copying t      ; don't clobber symlinks
   backup-directory-alist
    '(("." . "~/.saves"))    ; don't litter my fs tree
   delete-old-versions t
   kept-new-versions 6
   kept-old-versions 2
   version-control t)       ; use versioned backups

;;;Colour config
(if window-system (progn
 (set-face-foreground 'font-lock-comment-face "MediumSeaGreen")
 (set-face-foreground 'font-lock-string-face  "purple")
 (set-face-foreground 'font-lock-keyword-face "blue")
 (set-face-foreground 'font-lock-function-name-face "blue")
 (set-face-bold-p 'font-lock-function-name-face t)
 (set-face-foreground 'font-lock-variable-name-face "black")
 (set-face-foreground 'font-lock-type-face "LightSeaGreen")
 (set-face-foreground 'font-lock-builtin-face "purple")
 (set-face-foreground 'font-lock-constant-face "black")
 (set-face-foreground 'font-lock-warning-face "blue")
 (set-face-bold-p 'font-lock-warning-face nil)
))
