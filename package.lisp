(in-package #:cl-user)

(defpackage #:deploy-refgen
  (:documentation "download and prepare refgens")
  (:use #:cl)
  (:export
   ;; parameters
   *restriction-enzyme-1*
   *restriction-enzyme-2*
   *min-bp*
   *max-bp*
   *species*
   *ncbi-ftp*
   *chr-link-regex*
   *target-dir*
   *target-dir-approval*

   ;; functions
   check-prerequisites
   get-ftp-html
   get-link-strings
   download-chromosomes
   decompress-chromosomes
   concatenate-fastas
   fastas-srg
   fastas-index
   deploy-refgen
   ))
