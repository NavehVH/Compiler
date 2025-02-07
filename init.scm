(define list (lambda args args))

(define +
  (let* ((error (lambda () (error '+ "all arguments need to be numbers")))
         (bin+
           (lambda (a b)
             (cond ((integer? a)
                    (cond ((integer? b) (__bin-add-zz a b))
                          ((fraction? b)
                           (__bin-add-qq (__integer-to-fraction a) b))
                          ((real? b) (__bin-add-rr (integer->real a) b))
                          (else (error))))
                   ((fraction? a)
                    (cond ((integer? b)
                           (__bin-add-qq a (__bin_integer_to_fraction b)))
                          ((fraction? b) (__bin-add-qq a b))
                          ((real? b) (__bin-add-rr (fraction->real a) b))
                          (else (error))))
                   ((real? a)
                    (cond ((integer? b) (__bin-add-rr a (integer->real b)))
                          ((fraction? b) (__bin-add-rr a (fraction->real b)))
                          ((real? b) (__bin-add-rr a b))
                          (else (error))))
                   (else (error))))))
    (lambda s (fold-left bin+ 0 s))))

(define fold-left
  (letrec ((run
             (lambda (f unit ss)
               (if (ormap null? ss)
                   unit
                   (run f
                     (apply f unit (map car ss))
                     (map cdr ss))))))
    (lambda (f unit . ss)
      (run f unit ss))))

(define fold-right
  (letrec ((run
             (lambda (f unit ss)
               (if (ormap null? ss)
                   unit
                   (apply f
                     `(,@(map car ss)
                       ,(run f unit (map cdr ss))))))))
    (lambda (f unit . ss)
      (run f unit ss))))