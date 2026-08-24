(defsystem "metarepl.genomic.deploy-refgen"
  :description "refgen: download, preparation, and placement"
  :author "metarepl (https://github.com/metarepl)"
  :version "0.0.1"
  :license "MIT"
  :depends-on (
               "cmd"
               "str"
               "drakma"
               "trivial-download"
               "cl-ppcre"
               "chipz"

               "alexandria"
               "filepaths"
               "filesystem-utils"
               )
  :serial t
  :components ((:file "package")
               (:file "deploy")))
