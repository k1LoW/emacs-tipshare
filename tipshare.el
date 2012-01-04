;;; tipshare.el --- Emacs integration for tipshare.info

;; Filename: tipshare.el
;; Description: Emacs integration for tipshare.info
;; Author: Kenichirou Oyama <k1lowxb@gmail.com>
;; Maintainer: Kenichirou Oyama <k1lowxb@gmail.com>
;; Copyright (C) 2012, 101000code/101000LAB, all rights reserved.
;; Created: 2012-01-04
;; Version: 0.0.1
;; URL:
;; Keywords: tipshare
;; Compatibility: GNU Emacs 23
;;
;; Features that might be required by this library:
;;
;; `cl'
;;

;;; This file is NOT part of GNU Emacs

;;; Reference
;; Some code referenced from gist.el
;;
;; gist.el
;; Author: Christian Neukirchen <purl.org/net/chneukirchen>
;; Maintainer: Chris Wanstrath <chris@ozmm.org>
;; Contributors:
;; Will Farrington <wcfarrington@gmail.com>
;; Michael Ivey
;; Phil Hagelberg
;; Dan McKinley
;;

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;;; Installation:
;;
;; Put anything-exuberant-ctags.el to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (require 'tipshare)
;;
;; No need more.

;;; Commands:
;;
;; Below are complete command list:
;;
;;  `tipshare-region'
;;    Post the current region as a new tips at tipshare.info
;;  `tipshare-auth-info'
;;    Returns the user's Tipshare authorization information.
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `tipshare-username'
;;    tipshare.info username
;;    default = nil
;;  `tipshare-key'
;;    tipshare.info API key
;;    default = nil

(eval-when-compile (require 'cl))

(defcustom tipshare-username nil
  "tipshare.info username"
  :type 'string)

(defcustom tipshare-key nil
  "tipshare.info API key"
  :type 'string)

(defun tipshare-region (begin end)
  "Post the current region as a new tips at tipshare.info"
  (interactive "r")
  (let* ((private nil))
    (tipshare-request
     "http://tipshare.info/api/post.json"
     'tipshare-created-callback
     (buffer-substring begin end))))

(defmacro tipshare-with-auth-info (username key &rest body)
  "Binds tipshare authentication credentials to `username' and `key'."
  (declare (indent 2))
  `(let ((*tipshare-auth-info* (tipshare-auth-info)))
     (destructuring-bind (,username . ,key) *tipshare-auth-info*
       ,@body)))

(defun* tipshare-request (url callback body)
  "Makes a request to `url' asynchronously, notifying `callback' when
complete."
  (tipshare-with-auth-info username key
    (let ((url-request-data (tipshare-make-query-string
                             `(("body" . ,body)
                               )))
          (url-cookie-untrusted-urls '(".*"))
          (url-request-method "POST")
          (url-request-extra-headers
             '(("Content-Type" . "application/x-www-form-urlencoded"))))
      (message (concat url "?username=" username "&secret_key=" key))
      (url-retrieve (concat url "?username=" username "&secret_key=" key) callback))))

(defun tipshare-auth-info ()
  "Returns the user's Tipshare authorization information."
  (interactive)
  (if (boundp '*tipshare-auth-info*)
      *tipshare-auth-info*
    (let
        ((username tipshare-username)
         (key tipshare-key))
      (when (not username)
        (setq username (read-string "Tipshare username: ")))
      (when (not key)
        (setq key (read-string "Tipshare API token: ")))
      (custom-set-variables `(tipshare-username username))
      (custom-set-variables `(tipshare-key key))
      (cons username key))))

(defun tipshare-make-query-string (params)
  "Returns a query string constructed from PARAMS, which should be
a list with elements of the form (KEY . VALUE). KEY and VALUE
should both be strings."
  (mapconcat
   (lambda (param)
     (concat (url-hexify-string (car param)) "="
             (url-hexify-string (cdr param))))
   params "&"))

(defun tipshare-created-callback (status)
  (message "%s" "tipshare posted."))

(provide 'tipshare)