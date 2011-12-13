;;;;;;;;;;;;;;;;;;;;
;; set up unicode
(set-language-environment "Japanese")
(prefer-coding-system       'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-buffer-file-coding-system 'utf-8-unix)
;; This from a japanese individual.  I hope it works.
(setq default-buffer-file-coding-system 'utf-8)
;; From Emacs wiki
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))
;; MS Windows clipboard is UTF-16LE
(set-clipboard-coding-system 'utf-16le-dos)

(setq
   backup-by-copying t      ; don't clobber symlinks
   backup-directory-alist
    '(("." . "~/.saves"))    ; don't litter my fs tree
   delete-old-versions t
   kept-new-versions 6
   kept-old-versions 2
   version-control t)       ; use versioned backups


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