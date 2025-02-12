;;; torture-test-for-compiler-08.scm
;;; << WHAT DOES THIS FILE CONTAIN >>
;;;
;;; Programmer: Mayer Goldberg, 2013

;;; should return ((#t) (#t) (#t))

(let ()
  ((lambda s
     (let ()
       ((lambda s s) s s s)))
   #t))