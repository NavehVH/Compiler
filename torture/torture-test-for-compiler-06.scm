;;; torture-test-for-compiler-06.scm
;;; << WHAT DOES THIS FILE CONTAIN >>
;;;
;;; Programmer: Mayer Goldberg, 2012

(define even?
  (letrec ((even-1?
	    (lambda (n)
	      (or (zero? n)
		  (odd-2? (- n 1) 'odd-2))))
	   (odd-2?
	    (lambda (n _)
	      (and (positive? n)
		   (even-3? (- n 1) (+ n n) (+ n n n)))))
	   (even-3?
	    (lambda (n _1 _2)
	      (or (zero? n)
		  (odd-5? (- n 1) (+ n n) (* n n) 'odd-5 'odder-5))))
	   (odd-5?
	    (lambda (n _1 _2 _3 _4)
	      (and (positive? n)
		   (even-1? (- n 1))))))
    even-1?))

(even? 100)
