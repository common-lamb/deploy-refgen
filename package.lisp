(in-package #:cl-user)

(defpackage #:refgen/download
  (:documentation "download and prepare refgens")
  (:use #:cl)
  ;;(:package-local-nicknames :cool :com-lamb-utility-long)
  (:export
   ;; parameters
   ;;
   *ncbi-ftp*
   *chromosome-links*
   *target-dir*
   ;; *target-dir-approval*
                                        ;e defsystem "" functions
   ;; functions
   ;;
   get-ftp-html
   get-link-strings
   download-chromosomes
   decompress-chromosomes
   concatenate-fastas
   ))
