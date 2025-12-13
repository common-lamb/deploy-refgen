(defsystem "com.lamb.genomic.download-refgen"
  :description "refgen operations, download & prep"
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
  :components ((:file "package")
               (:file "deploy")))

#|

;; utility naming convention

repo name

githib.com/common-lamb/download-refgen
  download-refgen.asd
  package.lisp
  deploy.lisp

system name

(asdf:defsystem "lamb.genomic.download-refgen"
  (:depends-on "other-asdf-system")
  (:depends-on "lamb.genomic.download-refgen/subsystem")
   :components ((:file "package")
                (:file "deploy")))
package name

(defpackage #:download-refgen/deploy
  (:use #:cl)
  (:export *sym*))

|#
