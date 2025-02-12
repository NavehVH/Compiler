;;; torture-test-for-compiler-07.scm
;;; << WHAT DOES THIS FILE CONTAIN >>
;;;
;;; Programmer: Mayer Goldberg, 2013

(let ((a 1))
  (let ((b 2) (c 3))
    (let ((d 4) (e 5) (f 6))
      (= 720 (* a b c d e f)))))