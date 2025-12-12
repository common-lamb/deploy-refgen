(in-package #:cl-user)

(defpackage #:refgen/download
  (:documentaion "download and prepare refgens")
  (:use #:cl)
  ;;(:package-local-nicknames :cool :com-lamb-utility-long)
  (:export
   ;; parameters
   *ncbi-ftp*
   *chromosome-links*
   ;; functions
   get-contents
   download-chromosomes
   decompress-chromosomes
   concatenate-fastas
   ))
