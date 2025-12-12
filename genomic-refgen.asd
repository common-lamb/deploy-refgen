(defsystem "com.lamb.genomic-refgen"
  :description "refgen operations, currently: download & prep"
  :author "common-lamb (https://github.com/common-lamb)"
  :license "MIT"
  :depends-on (
               ;; package ; qlot add
               "cmd" ; ql cmd
               "str" ; ql cl-str
               "drakma"
               "trivial-download"
               "cl-ppcre"
               "chipz"

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
