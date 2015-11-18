;; Copyright (c) 2015 Intel Corporation
;;
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;      http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

(module
  (memory 40000000 4)

  (func $multiply (param i32) (param i32) (result i32)
   (local i32 i32 i32 i32 i32 i32)

   ;; Locals are:
   ;;   0 is the parameter: n.
   ;;   1 is the parameter: a.
   ;;   2 is for the first matrix n * n.
   ;;   3 is for the second matrix n * n.
   ;;   4 is for the third matrix n * n.
   ;;   5 ~ 7 are temps/IVs.

   (block
    ;; Calculate size of each n * n matrix.
    (set_local 6 (i32.mul
                  (i32.mul (get_local 0) (get_local 0))
                  (i32.const 4)))

    ;; Get pointers for each matrix.
    (set_local 2 (i32.const 0))
    (set_local 3 (get_local 6))
    (set_local 4 (i32.add (get_local 2) (get_local 6)))

    (set_local 5 (i32.const 0))

    ;; Multiply by 4 to match IV's increments.
    (set_local 7 (i32.mul (get_local 0) (i32.const 4)))

    (label
     ;; Outer loop.
     (loop
      (if_else
       (i32.eq (get_local 5) (get_local 7))
         (br 1)
         (block
          ;; Set inner IV to 0.
          (set_local 6 (i32.const 0))

          (label
           ;; Inner loop.
           (loop
            (if_else
             (i32.eq (get_local 6) (get_local 7))
             (br 1)
             (block
             (i32.store (get_local 4)
                        (i32.add
                          (i32.mul (get_local 1)
                                   (i32.load (get_local 2)))
                          (i32.load (get_local 3))))

              ;; Augment IVs and pointers.
              (set_local 2 (i32.add (get_local 2) (i32.const 4)))
              (set_local 3 (i32.add (get_local 3) (i32.const 4)))
              (set_local 4 (i32.add (get_local 4) (i32.const 4)))
              (set_local 6 (i32.add (get_local 6) (i32.const 4)))
             )
            )

            ;; Next iteration.
            (br 0)
           )
          )

          (set_local 5 (i32.add (get_local 5) (i32.const 4)))
         )
        )

        ;; Next iteration.
        (br 0)
       )
     )

    (set_local 7 (i32.div (get_local 0) (i32.const 2)))

    (set_local 6 (i32.add
                    (i32.mul
                      (i32.mul (get_local 7) (get_local 0))
                      (i32.const 4))
                    (i32.mul
                      (get_local 7)
                      (i32.const 4))))

    ) ;; Function block end.
   (return (i32.load (get_local 6)))
  )

  (func $setter (param i32) (result i32)
   (local i32 i32 i32 i32 i32 i32 i32)

   (block
    ;; Calculate size of each n * n matrix.
    (set_local 6 (i32.mul
                  (i32.mul (get_local 0) (get_local 0))
                  (i32.const 4)))

    ;; Get pointers for each matrix.
    (set_local 2 (i32.const 0))
    (set_local 3 (get_local 6))

    ;; Multiply by 4 to match IV's increments.
    (set_local 6 (i32.mul (get_local 0) (i32.const 4)))

    (set_local 4 (i32.const 0))

    (label
     ;; Outer loop.
     (loop
      (if_else
       (i32.eq (get_local 4) (get_local 6))
         (br 1)
         (block
          ;; Set inner IV to 0.
          (set_local 5 (i32.const 0))

          (label
           ;; Inner loop.
           (loop
            (if_else
             (i32.eq (get_local 5) (get_local 6))
             (br 1)
             (block
              ;; Calculate the address: i * n + j
              ;;                   which means local(4) * n + local(5)
              (set_local 7 (i32.add
                 (i32.mul
                   (get_local 4)
                     (get_local 0))
                       (get_local 5)))

              ;; Set i * j at that cell for matrix starting at local(2).
              (i32.store (i32.add (get_local 2) (get_local 7))
                         (i32.div
                                    (i32.mul (get_local 4) (get_local 5))
                                    (i32.const 16)
                         )
              )

              ;; Set i * j at that cell for matrix starting at local(3).
              (i32.store (i32.add (get_local 3) (get_local 7))
                         (i32.div
                                    (i32.mul (get_local 4) (get_local 5))
                                    (i32.const 16)
                         )
              )

              ;; Augment IVs.
              (set_local 5 (i32.add (get_local 5) (i32.const 4)))
             )
            )

            ;; Next iteration.
            (br 0)
           )
          )

          (set_local 4 (i32.add (get_local 4) (i32.const 4)))
         )
        )

        ;; Next iteration.
        (br 0)
       )
     )

   ) ;; Function block end.
   (return (i32.const 0))
  )

  (export "multiply" $multiply)
  (export "setter" $setter)
)

(assert_return (invoke "setter" (i32.const 1000)) (i32.const 0))
(assert_return (invoke "multiply" (i32.const 1000) (i32.const 1000)) (i32.const 250000))
