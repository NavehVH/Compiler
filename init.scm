;;; init.scm
;;; Initial definitions that should be available for the compiler
;;;
;;; Programmer: Mayer Goldberg, 2024

(define (caar x) (car (car x)))
(define (cadr x) (car (cdr x)))
(define (cdar x) (cdr (car x)))
(define (cddr x) (cdr (cdr x)))
(define (caaar x) (car (caar x)))
(define (caadr x) (car (cadr x)))
(define (cadar x) (car (cdar x)))
(define (caddr x) (car (cddr x)))
(define (cdaar x) (cdr (caar x)))
(define (cdadr x) (cdr (cadr x)))
(define (cddar x) (cdr (cdar x)))
(define (cdddr x) (cdr (cddr x)))
(define (caaaar x) (caar (caar x)))
(define (caaadr x) (caar (cadr x)))
(define (caadar x) (caar (cdar x)))
(define (caaddr x) (caar (cddr x)))
(define (cadaar x) (cadr (caar x)))
(define (cadadr x) (cadr (cadr x)))
(define (caddar x) (cadr (cdar x)))
(define (cadddr x) (cadr (cddr x)))
(define (cdaaar x) (cdar (caar x)))
(define (cdaadr x) (cdar (cadr x)))
(define (cdadar x) (cdar (cdar x)))
(define (cdaddr x) (cdar (cddr x)))
(define (cddaar x) (cddr (caar x)))
(define (cddadr x) (cddr (cadr x)))
(define (cdddar x) (cddr (cdar x)))
(define (cddddr x) (cddr (cddr x)))

(define (list? e)
  (or (null? e)
      (and (pair? e)
           (list? (cdr e)))))

(define list (lambda args args))

(define (not x) (if x #f #t))

(define (rational? q)
  (or (integer? q)
      (fraction? q)))

(define list*
  (letrec ((run
             (lambda (a s)
               (if (null? s)
                   a
                   (cons a
                     (run (car s) (cdr s)))))))
    (lambda (a . s)
      (run a s))))

(define apply
  (letrec ((run
             (lambda (a s)
               (if (pair? s)
                   (cons a
                     (run (car s)
                       (cdr s)))
                   a))))
    (lambda (f . s)
      (__bin-apply f
        (run (car s)
          (cdr s))))))

(define ormap
  (lambda (f . s)
    (letrec ((loop
               (lambda (s)
                 (and (pair? (car s))
                      (or (apply f (map car s))
                          (loop (map cdr s)))))))
      (and (pair? s)
           (loop s)))))

(define andmap
  (lambda (f . s)
    (letrec ((loop
               (lambda (s)
                 (or (null? (car s))
                     (and (apply f (map car s))
                          (loop (map cdr s)))))))
      (or (null? s)
          (and (pair? s)
               (loop s))))))

(define map
  (letrec ((map1
             (lambda (f s)
               (if (null? s)
                   '()
                   (cons (f (car s))
                     (map1 f (cdr s))))))
           (map-list
             (lambda (f s)
               (if (null? (car s))
                   '()
                   (cons (apply f (map1 car s))
                     (map-list f
                       (map1 cdr s)))))))
    (lambda (f . s)
      (if (null? s)
          '()
          (map-list f s)))))

(define reverse
  (lambda (s)
    (fold-left
      (lambda (r a) (cons a r))
      '()
      s)))

(define append
  (letrec ((run-1
             (lambda (s1 sr)
               (if (null? sr)
                   s1
                   (run-2 s1
                     (run-1 (car sr)
                       (cdr sr))))))
           (run-2
             (lambda (s1 s2)
               (if (null? s1)
                   s2
                   (cons (car s1)
                     (run-2 (cdr s1) s2))))))
    (lambda s
      (if (null? s)
          '()
          (run-1 (car s)
            (cdr s))))))

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

;;; Please remember that the order here is as per Scheme, and 
;;; not the correct order, which is in Ocaml!
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

(define -
  (let* ((error (lambda () (error '- "all arguments need to be numbers")))
         (bin-
           (lambda (a b)
             (cond ((integer? a)
                    (cond ((integer? b) (__bin-sub-zz a b))
                          ((fraction? b)
                           (__bin-sub-qq (__integer-to-fraction a) b))
                          ((real b) (__bin-sub-rr (integer->real a) b))
                          (else (error))))
                   ((fraction? a)
                    (cond ((integer? b)
                           (__bin-sub-qq a (__integer-to-fraction b)))
                          ((fraction? b) (__bin-sub-qq a b))
                          ((real? b) (__bin-sub-rr (fraction->real a) b))
                          (else (error))))
                   ((real? a)
                    (cond ((integer? b) (__bin-sub-rr a (integer->real b)))
                          ((fraction? b) (__bin-sub-rr a (fraction->real b)))
                          ((real? b) (__bin-sub-rr a b))
                          (else (error))))
                   (else (error))))))
    (lambda (a . s)
      (if (null? s)
          (bin- 0 a)
          (let ((b (fold-left + 0 s)))
            (bin- a b))))))

(define *
  (let* ((error (lambda () (error '* "all arguments need to be numbers")))
         (bin*
           (lambda (a b)
             (cond ((integer? a)
                    (cond ((integer? b) (__bin-mul-zz a b))
                          ((fraction? b)
                           (__bin-mul-qq (__integer-to-fraction a) b))
                          ((real? b) (__bin-mul-rr (integer->real a) b))
                          (else (error))))
                   ((fraction? a)
                    (cond ((integer? b)
                           (__bin-mul-qq a (__integer-to-fraction b)))
                          ((fraction? b) (__bin-mul-qq a b))
                          ((real? b) (__bin-mul-rr (fraction->real a) b))
                          (else (error))))
                   ((real? a)
                    (cond ((integer? b)
                           (__bin-mul-rr a (integer->real b)))
                          ((fraction? b) (__bin-mul-rr a (fraction->real b)))
                          ((real? b) (__bin-mul-rr a b))
                          (else (error))))
                   (else (error))))))
    (lambda s
      (fold-left bin* 1 s))))

(define /
  (let* ((error (lambda () (error '/ "all arguments need to be numbers")))
         (bin/
           (lambda (a b)
             (cond ((integer? a)
                    (cond ((integer? b) (__bin-div-zz a b))
                          ((fraction? b)
                           (__bin-div-qq (__integer-to-fraction a) b))
                          ((real? b) (__bin-div-rr (integer->real a) b))
                          (else (error))))
                   ((fraction? a)
                    (cond ((integer? b)
                           (__bin-div-qq a (__integer-to-fraction b)))
                          ((fraction? b) (__bin-div-qq a b))
                          ((real? b) (__bin-div-rr (fraction->real a) b))
                          (else (error))))
                   ((real? a)
                    (cond ((integer? b)
                           (__bin-div-rr a (integer->real b)))
                          ((fraction? b) (__bin-div-rr a (fraction->real b)))
                          ((real? b) (__bin-div-rr a b))
                          (else (error))))
                   (else (error))))))
    (lambda (a . s)
      (if (null? s)
          (bin/ 1 a)
          (let ((b (fold-left * 1 s)))
            (bin/ a b))))))

(define fact
  (lambda (n)
    (if (zero? n)
        1
        (* n (fact (- n 1))))))

(define < #void)
(define <= #void)
(define > #void)
(define >= #void)
(define = #void)

(let* ((exit
         (lambda ()
           (error 'generic-comparator
             "all the arguments must be numbers")))
       (make-bin-comparator
         (lambda (comparator-zz comparator-qq comparator-rr)
           (lambda (a b)
             (cond ((integer? a)
                    (cond ((integer? b) (comparator-zz a b))
                          ((fraction? b)
                           (comparator-qq (__integer-to-fraction a) b))
                          ((real? b) (comparator-rr (integer->real a) b))
                          (else (exit))))
                   ((fraction? a)
                    (cond ((integer? b)
                           (comparator-qq a (__integer-to-fraction b)))
                          ((fraction? b) (comparator-qq a b))
                          ((real? b)
                           (comparator-rr (fraction->real a) b))
                          (else (exit))))
                   ((real? a)
                    (cond ((integer? b)
                           (comparator-rr a (integer->real b)))
                          ((fraction? b)
                           (comparator-rr a (fraction->real b)))
                          ((real? b) (comparator-rr a b))
                          (else (exit))))
                   (else (exit))))))
       (bin<? (make-bin-comparator
                __bin-less-than-zz
                __bin-less-than-qq
                __bin-less-than-rr))
       (bin=? (make-bin-comparator
                __bin-equal-zz
                __bin-equal-qq
                __bin-equal-rr))
       (bin>=? (lambda (a b) (not (bin<? a b))))
       (bin>? (lambda (a b) (bin<? b a)))
       (bin<=? (lambda (a b) (not (bin>? a b)))))
  (let ((make-run
          (lambda (bin-ordering)
            (letrec ((run
                       (lambda (a s)
                         (or (null? s)
                             (and (bin-ordering a (car s))
                                  (run (car s) (cdr s)))))))
              (lambda (a . s) (run a s))))))
    (set! < (make-run bin<?))
    (set! <= (make-run bin<=?))
    (set! > (make-run bin>?))
    (set! >= (make-run bin>=?))
    (set! = (make-run bin=?))))

;;; Replaced with the corresponding procedure in assembly,
;;; in the epilog.asm file
#;(define make-list
  (letrec ((run
             (lambda (n ch)
               (if (zero? n)
                   '()
                   (cons ch
                     (run (- n 1) ch))))))
    (lambda (n . chs)
      (cond ((null? chs) (run n #void))
            ((and (pair? chs)
                  (null? (cdr chs)))
             (run n (car chs)))
            (else (error 'make-list
                    "Usage: (make-list length ?optional-init-char)"))))))

(define char<? #void)
(define char<=? #void)
(define char=? #void)
(define char>? #void)
(define char>=? #void)

(let ((make-char-comparator
        (lambda (comparator)
          (lambda s
            (apply comparator
              (map char->integer s))))))
  (set! char<? (make-char-comparator <))
  (set! char<=? (make-char-comparator <=))
  (set! char=? (make-char-comparator =))
  (set! char>? (make-char-comparator >))
  (set! char>=? (make-char-comparator >=)))

(define char-downcase #void)
(define char-upcase #void)

(let ((delta
        (- (char->integer #\a)
          (char->integer #\A))))
  (set! char-downcase
    (lambda (ch)
      (if (char<=? #\A ch #\Z)
          (integer->char
            (+ (char->integer ch) delta))
          ch)))
  (set! char-upcase
    (lambda (ch)
      (if (char<=? #\a ch #\z)
          (integer->char
            (- (char->integer ch) delta))
          ch))))

(define char-ci<? #void)
(define char-ci<=? #void)
(define char-ci=? #void)
(define char-ci>? #void)
(define char-ci>=? #void)

(let ((make-char-ci-comparator
        (lambda (comparator)
          (lambda s
            (apply comparator
              (map (lambda (ch)
                     (char->integer
                       (char-downcase ch)))
                s))))))
  (set! char-ci<? (make-char-ci-comparator <))
  (set! char-ci<=? (make-char-ci-comparator <=))
  (set! char-ci=? (make-char-ci-comparator =))
  (set! char-ci>? (make-char-ci-comparator >))
  (set! char-ci>=? (make-char-ci-comparator >=)))

(define string-downcase #void)
(define string-upcase #void)

(let ((make-string-case-converter
        (lambda (char-case-converter)
          (lambda (str)
            (list->string
              (map char-case-converter
                (string->list str)))))))
  (set! string-downcase (make-string-case-converter char-downcase))
  (set! string-upcase (make-string-case-converter char-upcase)))

(define string<? #void)
(define string<=? #void)
(define string=? #void)
(define string>=? #void)
(define string>? #void)
(define string-ci<? #void)
(define string-ci<=? #void)
(define string-ci=? #void)
(define string-ci>=? #void)
(define string-ci>? #void)

(let ((make-string<?
        (lambda (char<? char=?)
          (letrec ((run
                     (lambda (i str1 len1 str2 len2)
                       (or (and (= i len1) (< len1 len2))
                           (and
                             (< i len1)
                             (or (char<?
                                   (string-ref str1 i)
                                   (string-ref str2 i))
                                 (and (char=?
                                        (string-ref str1 i)
                                        (string-ref str2 i))
                                      (run (+ i 1) str1 len1 str2 len2))))))))
            (let ((binary-string<?
                    (lambda (str1 str2)
                      (let ((len1 (string-length str1))
                            (len2 (string-length str2)))
                        (if (<= len1 len2)
                            (run 0 str1 len1 str2 len2)
                            (run 0 str2 len2 str1 len1))))))
              (letrec ((run
                         (lambda (str strs)
                           (or (null? strs)
                               (and (binary-string<? str (car strs))
                                    (run (car strs) (cdr strs)))))))
                (lambda (str . strs)
                  (run str strs))))))))
  (set! string<? (make-string<? char<? char=?))
  (set! string-ci<? (make-string<? char-ci<? char-ci=?))
  (set! string>? (make-string<? char>? char=?))
  (set! string-ci>? (make-string<? char-ci>? char-ci=?)))

(let ((make-string<=?
        (lambda (char<? char=?)
          (letrec ((run
                     (lambda (i str1 len1 str2 len2)
                       (or (= i len1)
                           (char<?
                             (string-ref str1 i)
                             (string-ref str2 i))
                           (and (< i len1)
                                (char=?
                                  (string-ref str1 i)
                                  (string-ref str2 i))
                                (run (+ i 1) str1 len1 str2 len2))))))
            (let ((binary-string<=?
                    (lambda (str1 str2)
                      (let ((len1 (string-length str1))
                            (len2 (string-length str2)))
                        (if (<= len1 len2)
                            (run 0 str1 len1 str2 len2)
                            (run 0 str2 len2 str1 len1))))))
              (letrec ((run
                         (lambda (str strs)
                           (or (null? strs)
                               (and (binary-string<=? str (car strs))                                     (run (car strs) (cdr strs)))))))
                (lambda (str . strs)
                  (run str strs))))))))
  (set! string<=? (make-string<=? char<? char=?))
  (set! string-ci<=? (make-string<=? char-ci<? char-ci=?))
  (set! string>=? (make-string<=? char>? char=?))
  (set! string-ci>=? (make-string<=? char-ci>? char-ci=?)))

(let ((make-string=?
        (lambda (char=?)
          (letrec ((run
                     (lambda (i str1 str2 len)
                       (or (= i len)
                           (and (< i len)
                                (char=?
                                  (string-ref str1 i)
                                  (string-ref str2 i))
                                (run (+ i 1) str1 str2 len))))))
            (let ((binary-string=?
                    (lambda (str1 str2)
                      (let ((len1 (string-length str1))
                            (len2 (string-length str2)))
                        (and (= len1 len2)
                             (run 0 str1 str2 len1))))))
              (letrec ((run
                         (lambda (str strs)
                           (or (null? strs)
                               (and (binary-string=? str (car strs))
                                    (run (car strs) (cdr strs)))))))
                (lambda (str . strs)
                  (run str strs))))))))
  (set! string=? (make-string=? char=?))
  (set! string-ci=? (make-string=? char-ci=?)))

(define list?
  (lambda (e)
    (or (null? e)
        (and (pair? e)
             (list? (cdr e))))))

(define make-vector
  (let ((asm-make-vector make-vector))
    (lambda (n . xs)
      (let ((x
              (cond ((null? xs) #void)
                    ((and (pair? xs)
                          (null? (cdr xs)))
                     (car xs))
                    (else (error 'make-vector
                            "Usage: (make-vector size ?optional-default)")))))
        (asm-make-vector n x)))))

(define make-string
  (let ((asm-make-string make-string))
    (lambda (n . chs)
      (let ((ch
              (cond ((null? chs) #\nul)
                    ((and (pair? chs)
                          (null? (cdr chs)))
                     (car chs))
                    (else (error 'make-string
                            "Usage: (make-string size ?optional-default)")))))
        (asm-make-string n ch)))))

(define list->vector
  (letrec ((run
             (lambda (s i)
               (if (null? s)
                   (make-vector i #void)
                   (let ((v (run (cdr s) (+ i 1))))
                     (vector-set! v i (car s))
                     v)))))
    (lambda (s)
      (run s 0))))

(define list->string
  (letrec ((run
             (lambda (s i)
               (if (null? s)
                   (make-string i #\nul)
                   (let ((str (run (cdr s) (+ i 1))))
                     (string-set! str i (car s))
                     str)))))
    (lambda (s)
      (run s 0))))

(define vector (lambda s (list->vector s)))

(define string->list
  (letrec ((run
             (lambda (str i n)
               (if (< i n)
                   (cons (string-ref str i)
                     (run str (+ i 1) n))
                   '()))))
    (lambda (str)
      (run str 0 (string-length str)))))

(define vector->list
  (letrec ((run
             (lambda (v i n)
               (if (< i n)
                   (cons (vector-ref v i)
                     (run v (+ i 1) n))
                   '()))))
    (lambda (v)
      (run v 0 (vector-length v)))))

(define random (lambda (n) (remainder (trng) n)))

(define positive?
  (lambda (x)
    (< 0 x)))

(define negative? (lambda (x) (< x 0)))

(define even? (lambda (n) (zero? (remainder n 2))))

(define odd? (lambda (n) (not (even? n))))

(define abs (lambda (x) (if (negative? x) (- x) x)))

(define equal?
  (lambda (e1 e2)
    (cond ((and (pair? e1) (pair? e2))
           (and (equal? (car e1) (car e2))
                (equal? (cdr e1) (cdr e2))))
          ((and (vector? e1) (vector? e2)
                (= (vector-length e1) (vector-length e2)))
           (equal? (vector->list e1) (vector->list e2)))
          ((and (string? e1) (string? e2)
                (= (string-length e1) (string-length e2)))
           (string=? e1 e2))
          ((and (number? e1) (number? e2)) (= e1 e2))
          ((and (char? e1) (char? e2)) (char=? e1 e2))
          (else (eq? e1 e2)))))

(define assoc
  (lambda (a s)
    (cond ((null? s) #f)
          ((eq? (caar s) a) (car s))
          (else (assoc a (cdr s))))))

(define string-append
  (letrec ((run
             (lambda (target i s)
               (if (null? s)
                   target
                   (begin
                     (let ((i (add target i (car s) 0 (string-length (car s)))))
                       (run target i (cdr s)))))))
           (add
             (lambda (target i str j limit)
               (if (< j limit)
                   (begin
                     (string-set! target i (string-ref str j))
                     (add target (+ i 1) str (+ j 1) limit))
                   i))))
    (lambda strings
      (run 
        (make-string
          (apply + (map string-length strings)))
        0
        strings))))

(define vector-append
  (letrec ((run
             (lambda (target i s)
               (if (null? s)
                   target
                   (begin
                     (let ((i (add target i (car s) 0 (vector-length (car s)))))
                       (run target i (cdr s)))))))
           (add
             (lambda (target i vec j limit)
               (if (< j limit)
                   (begin
                     (vector-set! target i (vector-ref vec j))
                     (add target (+ i 1) vec (+ j 1) limit))
                   i))))
    (lambda vectors
      (run 
        (make-vector
          (apply + (map vector-length vectors)))
        0
        vectors))))

(define string-reverse
  (lambda (str)
    (list->string
      (reverse
        (string->list str)))))

(define vector-reverse
  (lambda (vec)
    (list->vector
      (reverse
        (vector->list vec)))))

(define string-reverse!
  (letrec ((run
             (lambda (str i j)
               (if (< i j)
                   (let ((ch (string-ref str i)))
                     (string-set! str i (string-ref str j))
                     (string-set! str j ch)
                     (run str (+ i 1) (- j 1)))
                   str))))
    (lambda (str)
      (let ((n (string-length str)))
        (if (zero? n)
            str
            (run str 0 (- n 1)))))))

(define vector-reverse!
  (letrec ((run
             (lambda (vec i j)
               (if (< i j)
                   (let ((ch (vector-ref vec i)))
                     (vector-set! vec i (vector-ref vec j))
                     (vector-set! vec j ch)
                     (run vec (+ i 1) (- j 1)))
                   vec))))
    (lambda (vec)
      (let ((n (vector-length vec)))
        (if (zero? n)
            vec
            (run vec 0 (- n 1)))))))

(define make-list-thunk
  (lambda (n thunk)
    (letrec ((run
               (lambda (i)
                 (if (< i n)
                     (cons (thunk i)
                       (run (+ i 1)))
                     '()))))
      (run 0))))

(define make-string-thunk
  (lambda (n thunk)
    (let ((str (make-string n)))
      (letrec ((run
                 (lambda (i)
                   (if (< i n)
                       (begin
                         (string-set! str i (thunk i))
                         (run (+ i 1)))
                       str))))
        (run 0)))))

(define make-vector-thunk
  (lambda (n thunk)
    (let ((vec (make-vector n)))
      (letrec ((run
                 (lambda (i)
                   (if (< i n)
                       (begin
                         (vector-set! vec i (thunk i))
                         (run (+ i 1)))
                       vec))))
        (run 0)))))

(define logarithm
  (lambda (a b n)
    (cond ((zero? n) 1.0)
          ((< a b) (+ 1.0 (logarithm a (/ b a) n)))
          ((= a b) 1.0)
          (else (/ 1.0 (logarithm b a (- n 1)))))))

(define newline
  (lambda ()
    (write-char #\newline)))

(define void (lambda () #void))

;;; end-of-input
