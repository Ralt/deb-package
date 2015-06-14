(in-package #:deb-package)

(ftype get-item list symbol list)
(defun get-item (list keyword)
  (rest
   (find-if #'(lambda (item)
                (getf item keyword))
            list)))

(defmacro define-deb-package (name &body forms)
  `(let ((changelog-entries
          (make-array
           ,(length (get-item forms :changelog))
           :initial-contents (list ,@(mapcar
                                      #'(lambda (entry)
                                          `(make-instance 'changelog-entry ,@entry))
                                      (get-item forms :changelog))))))
     (let ((package (make-instance 'deb-package
                                   :name ',name
                                   :changelog changelog-entries)))
       (write-deb-file (package-pathname package) package))))

(defclass changelog-entry ()
  ((version :initarg :version
            :type string
            :initform (error "Version required."))
   (author :initarg :author
           :type string
           :initform (error "Author required."))
   (message :initarg :message
            :type string
            :initform (error "Message required.")))
  (:documentation "A single changelog entry."))

(defclass deb-package ()
  ((name :initarg :name
         :type symbol
         :initform (error "Name required."))
   (changelog :initarg :changelog
              :type (vector changelog-entry)
              :reader changelog
              :initform (error "Changelog required.")))
  (:documentation "Holds all the data required to generate a debian package."))

(ftype name deb-package string)
(defun name (package)
  (string-downcase (symbol-name (slot-value package 'name))))

(ftype write-deb-file pathname deb-package null)
(defun write-deb-file (path package)
  (with-open-file (s path :direction :output
                     :element-type '(unsigned-byte 8)
                     :if-does-not-exist :create)
    (write-bytes (ar-global-header) s)
    (write-bytes (ar-add-entry #p"debian-binary" (debian-binary)) s)
    (write-bytes (ar-add-entry #p"control.tar.gz" (control-file package)) s)))

(ftype write-bytes (vector integer) stream null)
(defun write-bytes (bytes stream)
  (loop
     :for byte across bytes
     :do (write-byte byte stream)))

(ftype debian-binary (vector integer))
(defun debian-binary ()
  #(#x32 #x2E #x30 #x0A))

(ftype control-file deb-package (vector integer))
(defun control-file (package)
  #())

(ftype package-pathname deb-package pathname)
(defun package-pathname (package)
  (pathname (concatenate 'string (name package) ".deb")))
