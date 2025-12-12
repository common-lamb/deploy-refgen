(defsystem "com.lamb.genomic-refgen"
  :description "refgen operations, currently: download & prep"
  :author "common-lamb (https://github.com/common-lamb)"
  :version "0.0.1"
  :license "MIT"
  :depends-on (
               ;; package ; qlot add
               "cmd" ; ql cmd
               "str" ; ql cl-str
               "drakma" ; ql drakma
               "trivial-download" ; ql trivial-download
               "cl-ppcre" ; ql cl-ppcre
               "chipz" ;  ql chipz

               "qlot" ; ql qlot
               "alexandria" ; ql alexandria
               "filepaths" ; ultralisp fosskers-filepaths
               "filesystem-utils" ; ql filesystem-utils
               )
  :serial t
  :components (
               (:file "package") ; .lisp
               (:file "refgen-download") ; .lisp
               )
  )

#|

;; utility naming convention

;;repo name
githib.com/common-lamb/genomic-refgen
  genomic-refgen.asd
  package.lisp
  refgen-download.lisp

;;system name
(asdf:defsystem "com.lamb.genomic-refgen"
  (:depends-on "other-asdf-system"))

;;package name
(defpackage #:refgen/download
  (:use #:cl)
;;(:package-local-nicknames :cool :com-lamb-utility-long)
  (:export *sym*))

|#
