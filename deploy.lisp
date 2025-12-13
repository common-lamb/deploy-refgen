;; setup sequence
;;
;; clone repo
;; qlot init
;; qlot install
;; qlot add {each from asdf}

;; startup sequence
;;
;; M-x conda-env-activate download-refgen
;; , '
;; (asdf:load-system :lamb.genomic.download-refgen)
;; (in-package :download-refgen/deploy)

(in-package :download-refgen/deploy)

;; SRG parameters
(defparameter *restriction-enzyme-1* nil
  " first restriction enzyme
we choose ApeKI or PstI
https://pmc.ncbi.nlm.nih.gov/articles/PMC9394214/
")
(defparameter *restriction-enzyme-2* nil
  " second restriction enzyme
we choose ApeKI or MspI
https://pmc.ncbi.nlm.nih.gov/articles/PMC9394214/
")
(defparameter *min-bp* nil
  " minimum base pair length of digested chromosome fragments
we chose 50")
(defparameter *max-bp* nil
  " maximum base pair length of digested chromosome fragments
we choose 1000")
(defparameter *species* nil
  " the species of the refgen")

;; pipeline parameters
(defparameter *ncbi-ftp* nil
  "
ftp address to the dir above the fasta files
trailing / is mandatory
ie. contains chromosome data
for barley, chr1H.fna.gz - chr7H.fna.gz

check the content with get-ftp-html

morexV3
 \"https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/904/849/725/GCF_904849725.1_MorexV3_pseudomolecules_assembly/GCF_904849725.1_MorexV3_pseudomolecules_assembly_assembly_structure/Primary_Assembly/assembled_chromosomes/FASTA/\"
")

(defparameter *chr-link-regex* nil
  "
a perl compatible reg ex (pcre)
in three groups
the first use parses html for href links
the second use parses links for groups to get the file name

matches barley links and chromsomes:
     group 1     group 2           group 3
   '(<a href=\")(chr[1-7]H.fna.gz)(\">)'
    make the single quotes double quotes

check with get-link-strings
or get-ftp-html and use  pcre at https://regex101.com/
")

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
   (cmd:cmd "which git")
   ;; for SRG
   (cmd:cmd "which parallel")
   (cmd:cmd "which bwa")
   (cmd:cmd "which python")
   (cmd:cmd "python -m pip show natsort")
   (cmd:cmd "python -m pip show biopython")
   (cmd:cmd "which samtools")
   (cmd:cmd "which bedtools")))

;; &&& add more
(defun check-variables ()
  "tests if all variables are set"
  ;; *restriction-enzyme-1*
  (if (null *restriction-enzyme-1*)
      (error "the parameter *restriction-enzyme-1* must be set.
try: (documentation '*some-var* 'variable) ~&~&~A"
             (documentation '*restriction-enzyme-1* 'variable) )
      (format t "~%*restriction-enzyme-1* set to : ~A" *restriction-enzyme-1*))
  ;; *restriction-enzyme-2*
  (if (null *restriction-enzyme-2*)
      (error "the parameter *restriction-enzyme-2* must be set.
try: (documentation '*some-var* 'variable) ~&~&~A"
             (documentation '*restriction-enzyme-2* 'variable) )
      (format t "~%*restriction-enzyme-2* set to : ~A" *restriction-enzyme-2*))
  ;; *min-bp*
  (if (null *min-bp*)
      (error "the parameter *min-bp* must be set.
try: (documentation '*some-var* 'variable) ~&~&~A"
             (documentation '*min-bp* 'variable) )
      (format t "~%*min-bp* set to : ~A" *min-bp*))
  ;; *max-bp*
  (if (null *max-bp*)
      (error "the parameter *max-bp* must be set.
try: (documentation '*some-var* 'variable) ~&~&~A"
             (documentation '*max-bp* 'variable) )
      (format t "~%*max-bp* set to : ~A" *max-bp*))
  ;; *species*
  (if (null *species*)
      (error "the parameter *species* must be set.
try: (documentation '*some-var* 'variable) ~&~&~A"
             (documentation '*species* 'variable) )
      (format t "~%*species* set to : ~A" *species*))
  ;; *ncbi-ftp*
  (if (null *ncbi-ftp*)
      (error "the parameter *ncbi-ftp* must be set.
try: (documentation '*some-var* 'variable) ~&~&~A"
             (documentation '*ncbi-ftp* 'variable) )
      (format t "~%*ncbi-ftp* set to : ~A" *ncbi-ftp*))
  ;; *chr-link-regex*
  (if (null *chr-link-regex*)
      (error "the parameter *chr-link-regex* must be set.
try: (documentation '*some-var* 'variable) ~&~&~A"
             (documentation '*chr-link-regex* 'variable) )
      (format t "~%*chr-link-regex* set to : ~A" *chr-link-regex*))
  ;; *target-dir*
  (if (null *target-dir*)
      (error "the parameter *target-dir* must be set.
try: (documentation '*some-var* 'variable) ~&~&~A"
             (documentation '*target-dir* 'variable) )
      (format t "~%*target-dir* set to : ~A" *target-dir*))
  T)

(defun check-target ()
  "tests if target-dir exists, offers to create"
  ;; check exists
  (let ((E (probe-file *target-dir*)))
    (if E
        ;; check with user
        (progn
          (format t "target dir exists")
          (format t "~&contents:~% ~A"
                  (directory (merge-pathnames "**/*.*" *target-dir*)))
          (format t "~&proceed? certainly overwriting these files."))
        ;; offer to make
        (progn
          (format t "~&target dir does not exist")
          (format t "~&proceed? creating dir:~%~A" *target-dir*))))
  ;; user check with override
  (if (not *target-dir-approval*)
    (let ((cont (y-or-n-p)))
      (if cont
          (ensure-directories-exist *target-dir*)
          (error "please setf a new location, or remove sensitive files. Unable to proceed without approval for use of *target-dir*: ~A" *target-dir*)))
    (let ((must-pre-exist (probe-file *target-dir*)))
      (unless must-pre-exist
        (error "with preapproval the target must already exist")))))

(defun check-prerequisites()
  "ensure vars, deps and locations etc are right"
  ;;
  (format t "~&checking tools on path" )
  (format t "~&all on path: ~S" (every #'zerop (check-environment)))
  ;;
  (format t "~&checking parameters are set" )
  (format t "~&all set: ~S" (check-variables))
  ;; announce exist or make
  (format t "~&checking *target-dir* exists" )
  (format t "~&exists: ~A" (check-target)))

(defun get-ftp-html ()
  (drakma:http-request *ncbi-ftp*))

(defun get-link-strings ()
  "parse the html content for chromosome links"
  ;; get the links
  (let* ((scanner (ppcre:create-scanner *chr-link-regex* ))
         (links (ppcre:all-matches-as-strings scanner
                                              (get-ftp-html))))
    ;; get the second groups
    (mapcar (lambda (link) (ppcre:register-groups-bind (nil 2nd nil)
                               (scanner link)
                             2nd))
            links)))

(defun get-file (filename)
  "download content of the parsed ftp address"
  (let ((source (concatenate 'string *ncbi-ftp* filename))
        (target (merge-pathnames filename *target-dir*)))
    (trivial-download:download source target)))

(defun download-chromosomes ()
  "use parameters to pull files to target"
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
                (uiop:delete-file-if-exists (probe-file zip))))
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

;; SRG

(defun clone-srg ()
  "conditionally clone the SRG repo in *target-dir*"
  (unless (probe-file (merge-pathnames "SRG-Extractor" *target-dir*))
    ;; creates: *target-dir*/SRG-Extractor
    ;; &&& pull request and change link to /jlaroche/
    (cmd:cmd "git clone https://github.com/common-lamb/SRG-Extractor.git" :in *target-dir*)))

(defun fasta-srg (fasta)
  (clone-srg)
  (let* (
         (nude (filepaths:drop-extension fasta))
         (name (pathname-name nude))
         (frag (make-pathname :defaults nude
                              :name (concatenate 'string name "_fragments")
                              :type "bed"))
         (bed (filepaths:add-extension nude "bed"))
         (comp (make-pathname :defaults nude
                              :name (concatenate 'string name "_fragments_complement")
                              :type "bed"))
         (srg (make-pathname :defaults nude
                             :name (concatenate 'string name "_SRG")
                             :type "fasta"))
         )
    ;; (print "") (print nude) (print name) (print frag) (print bed) (print comp) (print srg)
    (format t "~&~%beginning SRG for: ~A~%" name)
    ;;./srg_extractor.py ApeKI ApeKI 50 1000 <file>.fasta soybean
    (format t  "~&SRG 1 : makes ~A_fragments.bed~%" name)
    (cmd:cmd
     (format nil "./srg_extractor.py ~A ~A ~A ~A ~A ~A"
             *restriction-enzyme-1*
             *restriction-enzyme-2*
             *min-bp*
             *max-bp*
             fasta
             *species*)
     :in (merge-pathnames "SRG-Extractor/" *target-dir*))

    ;; ./make_genome_file.py <file>.fasta
    (format t  "~&SRG 2 : makes ~A.bed~%" name)
    (cmd:cmd
     (format nil "./make_genome_file.py ~A" fasta)
     :in (merge-pathnames "SRG-Extractor/" *target-dir*))

    ;; ./gbs_irrelevant.sh <file>_fragments.bed <file>.bed <file>_fragments_complement.bed
    (format t  "~&SRG 3 : makes ~A_fragments_complement.bed~%" name)
    (cmd:cmd
     (format nil "./gbs_irrelevant.sh ~A ~A ~A" frag bed comp)
     :in (merge-pathnames "SRG-Extractor/" *target-dir*))

    ;; ./masking.sh <file>.fasta <file>_fragments_complement.bed <file>_SRG.fasta
    (format t  "~&SRG 4 : makes ~A_SRG.fasta~%" name)
    (cmd:cmd
     (format nil "./masking.sh ~A ~A ~A" fasta comp srg)
     :in (merge-pathnames "SRG-Extractor/" *target-dir*))

    ;; srg 5 : makes stats table
    ;; ./stat_srg_genome.py <file>_SRG.fasta
    ;; ./stat_srg_genome.py /mnt/QNAP/holdens/LIBS/BarleyReferenceGenomes/test/chr1H_SRG.fasta
    (format t "~&done SRG~%")
    ))

(defun fastas-srg ()
  "collect and process all fasta files"
  ;; process all fastas
  (let ((fastas
          ;; all fasta, but not if _SRG processed
          (remove-if #'(lambda (p)
                         (str:containsp "_SRG" (pathname-name p)))
                     (directory (merge-pathnames "*.fasta" *target-dir*)))))
    (mapcar #'fasta-srg fastas))
  ;; clean up
  (uiop:delete-directory-tree
   (merge-pathnames "SRG-Extractor/" *target-dir*)
   :validate t)
  (let ((non-fastas
          ;; all non fasta
          (remove-if #'(lambda (p)
                         (str:containsp "fasta" (pathname-type p)))
                     (directory (merge-pathnames "*.*" *target-dir*)))))
    (mapcar #'uiop:delete-file-if-exists non-fastas)))

;; index
(defun fasta-index (fasta)
  (let ((name (pathname-name fasta)))

    ;; bwa index -a bwtsw SRG.fasta
    (format t  "~&~%bwa index ~A~&~%" name)
    (cmd:cmd
     (format nil "bwa index -a bwtsw ~A" fasta)
     :in *target-dir*)

    ;; samtools faidx SRG.fasta
    (format t  "~&~%samtools faidx ~A~&~%" name)
    (cmd:cmd
     (format nil "samtools faidx ~A" fasta)
     :in *target-dir*)

    (format t  "~&~%index complete ~A~&~%" name)))


(defun fastas-index ()
  (let ((fastas
          (directory (merge-pathnames "*.fasta" *target-dir*))))
    (mapcar #'fasta-index fastas)))

;;;; all operations
(defun deploy-refgen ()
  (check-prerequisites)
  (download-chromosomes)
  (decompress-chromosomes)
  (concatenate-fastas)
  (fastas-srg)
  (fastas-index))
