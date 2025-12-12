;; setup sequence
;;
;; qlot init
;; qlot install
;; qlot add {each from asdf}

;; startup sequence
;;
;; M-x conda-env-activate try-refgen-download
;; , '
;; (asdf:load-system :com.lamb.genomic-refgen)
;; (in-package :refgen/download)

(in-package #:refgen/download)

(defparameter *ncbi-ftp* "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/904/849/725/GCF_904849725.1_MorexV3_pseudomolecules_assembly/GCF_904849725.1_MorexV3_pseudomolecules_assembly_assembly_structure/Primary_Assembly/assembled_chromosomes/FASTA/"
  "
https address to the dir above the fasta files
ie. contains chromosome data
for barley, chr1H.fna.gz - 7H
trailing / is mandatory

check it with get-ftp-html

"
  )

(defparameter *chromosome-links* (ppcre:create-scanner "(<a href=\")(chr[1-7]H.fna.gz)(\">)")
  "
a perl compatible reg ex (pcre)
in three groups
the first use parses html for href links
the second use parses links for groups to get the file name

matches barley links and chromsomes:
    \"(<a href=\")(chr[1-7]H.fna.gz)(\">)\"

check with get-link-strings
or get-ftp-html and use  pcre at https://regex101.com/ ")

(defparameter *target-dir* nil
  "
an absolute path to an directory to receive
large fasta files. it should be empty.
trailing / mandatory

ALERT: this program is not designed to respect the current contents and may overwrite or delete any existing *.gz *.fasta etc files!

 (setf *target-dir* #P\"/home/<user>/<user>QNAP/LIBS/BarleyReferenceGenomes/test/\")
 ")

(defparameter *target-dir-approval* nil
  "set to T to skip the user approval of target dir selection.")

(defun check-environment ()
  "ensure needed tools are on path. throws big stinky errors if something needed is not found, or a nice list of 0 exit codes if everything is on path."
  (list
   (cmd:cmd "which sbcl")
   ;; for SRG
   ;; srg_extractor.py (this distribution)
   (cmd:cmd "which parallel")
   (cmd:cmd "which bwa")
   (cmd:cmd "which python")
   (cmd:cmd "python -m pip show biopython")
   (cmd:cmd "which samtools")
   (cmd:cmd "which bedtools")))

(defun check-target ()
  "tests if target-dir exists, offers to create"
  ;;check set
  (when (null *target-dir*)
    (error "the parameter *target-dir* must be set. try: (documentation '*target-dir* 'variable)"))
  ;; check exists
  (let ((E (probe-file *target-dir*)))
    (if E
        ;; check with user
        (progn
          (format t "target dir exists")
          (format t "~&contents:~% ~A"
                  (directory (merge-pathnames "**/*.*" *target-dir*)))
          (format t "~&proceed? possibly overwringing some of these files."))
        ;; offer to make
        (progn
          (format t "~&target dir does not exist")
          (format t "~&proceed? creating dir:~%~A")

          )))
  ;; user check with override
  (unless *target-dir-approval*
    (let ((cont (y-or-n-p)))
      (if cont
          (print *target-dir*)
          (error "please setf a new location, or remove sensitive files. Unable to proceed without approval for use of *target-dir*: ~A" *target-dir*)))))

(defun check-assumptions ()
  "ensure deps and locations etc are right"
  (format t "~&checking tools on path" )
  (format t "~&all on path: ~S" (every #'zerop (check-environment)))
  ;; &&& announce exist or make
  (format t "~&checking *target-dir* exists" )
  (format t "~&exists: ~A" (check-target)))

(defun get-ftp-html ()
  (drakma:http-request *ncbi-ftp*))

(defun get-link-strings ()
  "parse the html content for chromosome links"
  (let ((links (ppcre:all-matches-as-strings *chromosome-links*
                                             (get-ftp-html))))
    ;; get the second group
    (mapcar (lambda (link) (ppcre:register-groups-bind (nil 2nd nil)
                               (*chromosome-links* link)
                             2nd))
            links)))

(defun get-file (filename)
  "download content of the parsed ftp address"
  (let ((source (concatenate 'string *ncbi-ftp* filename))
        (target (merge-pathnames filename *target-dir*)))
    (trivial-download:download source target)))

(defun download-chromosomes ()
  "use parameters to pull files to target"
  (check-assumptions)
  (dolist (l (get-link-strings))
    (format t "~&~%downloading: ~S~%" l)
    (get-file l)))

(defun decompress-chromosomes ()
  "convert *.gz to .fasta"
  (let ((zips (directory (merge-pathnames "*.gz" *target-dir*))))
    (mapcar (lambda (zip)
              (let* ((basename (pathname-name (pathname-name zip)))
                     (rename (make-pathname :defaults *target-dir*
                                            :name basename
                                            :type "fasta")))
                (format t "~%Decompressing ~A~&" basename)
                (chipz:decompress rename 'chipz:gzip zip)
                ;; remove .gz file
                (uiop:delete-file-if-exists zip)
                ))
            zips)))

(defun concatenate-fastas ()
  "add all lines of *.fasta files to concatenated.fasta"
  ;; create an empty file to receive individual contents
  (with-open-file (out (merge-pathnames "concatenated.fasta"
                                      *target-dir*)
                     :direction :output
                     :if-does-not-exist :create
                     :if-exists :overwrite)
    nil)
  ;; add contents
  (with-open-file (out (merge-pathnames "concatenated.fasta"
                                        *target-dir*)
                       :direction :output
                       :if-does-not-exist :error
                       :if-exists :append)
    (dolist (fasta
             ;; all fasta files but the concatenated.fasta
             (remove-if #'(lambda (pn)
                            (pathname-match-p pn
                                              (first (directory (merge-pathnames "concatenated.fasta" *target-dir*)))))
                        (directory (merge-pathnames "*.fasta" *target-dir*))))
      ;; read and write each file by lines
      (format t "~&concatenating: ~A~%" fasta)
      (with-open-file (in fasta
                          :direction :input
                          :if-does-not-exist :error)
        ;; add lines
        (loop :for line = (read-line in nil nil)
              :while line
              :do (write-line line out))))))

;; &&& srg
;; &&& index

;;;; big operation
;;(download-chromosomes)
;; (decompress-chromosomes)
;; (concatenate-fastas)
