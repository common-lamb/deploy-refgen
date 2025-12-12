
(in-package #:refgen/download)




;; contains chr1H.fna.gz - 7H
;; trailing / mandatory
(defparameter *ncbi-ftp* "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/904/849/725/GCF_904849725.1_MorexV3_pseudomolecules_assembly/GCF_904849725.1_MorexV3_pseudomolecules_assembly_assembly_structure/Primary_Assembly/assembled_chromosomes/FASTA/")

;;  matches barley: "(<a href=\")(chr[1-7]H.fna.gz)(\">)"
;; three groups
(defparameter *chromosome-links* (ppcre:create-scanner "(<a href=\")(chr[1-7]H.fna.gz)(\">)"))

;; (defparameter *target-dir* #P"/home/holdens/holdensQNAP/LIBS/BarleyReferenceGenomes/test/")

(defparameter *target-dir* nil)

;; &&& must exist, must report contents, user approves
(defun check-target-dir-proceed ())

(defun get-contents ()
  (drakma:http-request *ncbi-ftp*))

(defun get-file (filename)
  "download targeted content of the ftp address"
  ;; &&& error if no target dir
  (let ((source (concatenate 'string *ncbi-ftp* filename))
        (target (merge-pathnames filename *target-dir*)))
    (trivial-download:download source target)))

(defun get-link-strings ()
  (let ((links (ppcre:all-matches-as-strings *chromosome-links* (get-contents))))
    (mapcar (lambda (link) (ppcre:register-groups-bind (nil 2nd nil)
                               (*chromosome-links* link)
                             2nd))
            links)))

(defun download-chromosomes ()
  ;; &&& maybe check target here
  (dolist (l (get-link-strings))
    (format t "~&~%downloading: ~S~%" l)
    (get-file l)))


;; unzip-downloads
(defun decompress-chromosomes ()
  (let ((zips (directory (merge-pathnames "*.gz" *target-dir*))))
    (mapcar (lambda (zip)
              (let* ((basename (pathname-name (pathname-name zip)))
                     (rename (make-pathname :defaults *target-dir*
                                            :name basename
                                            :type "fasta")))
                (format t "~%Decompressing ~A~&" basename)
                (chipz:decompress rename 'chipz:gzip zip)))
            zips)))


;; &&& concatenate

(defun concatenate-fastas ()
  "add all lines of *.fasta files to concatenated.fasta"
  ;; create an empty file to recieve
  (with-open-file (s (merge-pathnames "concatenated.fasta" *target-dir*)
                     :direction :output
                     :if-does-not-exist :create
                     :if-exists :overwrite)
    nil)

  ;; add contents
  (with-open-file (out (merge-pathnames "concatenated.fasta" *target-dir*)
                       :direction :output
                       :if-does-not-exist :error
                       :if-exists :append)
    (dolist (fasta
             ;; all fasta files but the concatenated.fasta
             (remove-if #'(lambda (pn)
                            (pathname-match-p pn
                                              (first (directory (merge-pathnames "concatenated.fasta" *target-dir*)))))
                        (directory (merge-pathnames "*.fasta" *target-dir*))))
      (format t "~&concatenating: ~A~%" fasta)

      ;; read and write the file by lines
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
