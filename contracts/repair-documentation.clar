;; Repair Documentation Contract
;; Shares successful fix methodologies

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u403))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))

;; Data structures
(define-map repair-guides
  { guide-id: uint }
  {
    author: principal,
    title: (string-ascii 100),
    device-type: (string-ascii 100),
    manufacturer: (string-ascii 100),
    model: (string-ascii 100),
    issue-type: (string-ascii 100),
    difficulty-level: (string-ascii 20), ;; "beginner", "intermediate", "advanced", "expert"
    time-estimate: uint, ;; in minutes
    tools-required: (string-ascii 500),
    parts-required: (string-ascii 500),
    steps: (string-ascii 2000),
    tips: (string-ascii 500),
    warnings: (string-ascii 500),
    images: (string-ascii 500),
    videos: (string-ascii 500),
    creation-date: uint,
    last-updated: uint,
    verification-status: bool
  }
)

(define-map repair-cases
  { case-id: uint }
  {
    technician: principal,
    device-id: uint,
    guide-id: uint,
    diagnosis: (string-ascii 500),
    solution: (string-ascii 1000),
    parts-used: (string-ascii 500),
    repair-time: uint, ;; in minutes
    success-level: (string-ascii 20), ;; "complete", "partial", "unsuccessful"
    follow-up-needed: bool,
    images-before: (string-ascii 500),
    images-after: (string-ascii 500),
    notes: (string-ascii 500),
    creation-date: uint
  }
)

(define-map guide-ratings
  { rating-id: uint }
  {
    guide-id: uint,
    user: principal,
    rating: uint, ;; 1-5
    comments: (string-ascii 500),
    helpful: bool,
    rating-date: uint
  }
)

(define-map verifiers
  { address: principal }
  { is-verifier: bool }
)

(define-data-var last-guide-id uint u0)
(define-data-var last-case-id uint u0)
(define-data-var last-rating-id uint u0)

;; Public functions
(define-public (create-repair-guide
                (title (string-ascii 100))
                (device-type (string-ascii 100))
                (manufacturer (string-ascii 100))
                (model (string-ascii 100))
                (issue-type (string-ascii 100))
                (difficulty-level (string-ascii 20))
                (time-estimate uint)
                (tools-required (string-ascii 500))
                (parts-required (string-ascii 500))
                (steps (string-ascii 2000))
                (tips (string-ascii 500))
                (warnings (string-ascii 500))
                (images (string-ascii 500))
                (videos (string-ascii 500)))
  (let ((new-id (+ (var-get last-guide-id) u1)))
    (var-set last-guide-id new-id)
    (map-set repair-guides
      { guide-id: new-id }
      {
        author: tx-sender,
        title: title,
        device-type: device-type,
        manufacturer: manufacturer,
        model: model,
        issue-type: issue-type,
        difficulty-level: difficulty-level,
        time-estimate: time-estimate,
        tools-required: tools-required,
        parts-required: parts-required,
        steps: steps,
        tips: tips,
        warnings: warnings,
        images: images,
        videos: videos,
        creation-date: block-height,
        last-updated: block-height,
        verification-status: false
      }
    )
    (ok new-id)
  )
)

(define-public (update-repair-guide
                (guide-id uint)
                (title (string-ascii 100))
                (issue-type (string-ascii 100))
                (difficulty-level (string-ascii 20))
                (time-estimate uint)
                (tools-required (string-ascii 500))
                (parts-required (string-ascii 500))
                (steps (string-ascii 2000))
                (tips (string-ascii 500))
                (warnings (string-ascii 500))
                (images (string-ascii 500))
                (videos (string-ascii 500)))
  (match (map-get? repair-guides { guide-id: guide-id })
    guide
      (if (is-eq tx-sender (get author guide))
        (begin
          (map-set repair-guides
            { guide-id: guide-id }
            (merge guide {
              title: title,
              issue-type: issue-type,
              difficulty-level: difficulty-level,
              time-estimate: time-estimate,
              tools-required: tools-required,
              parts-required: parts-required,
              steps: steps,
              tips: tips,
              warnings: warnings,
              images: images,
              videos: videos,
              last-updated: block-height
            })
          )
          (ok guide-id)
        )
        ERR-NOT-AUTHORIZED
      )
    ERR-NOT-FOUND
  )
)

(define-public (document-repair-case
                (device-id uint)
                (guide-id uint)
                (diagnosis (string-ascii 500))
                (solution (string-ascii 1000))
                (parts-used (string-ascii 500))
                (repair-time uint)
                (success-level (string-ascii 20))
                (follow-up-needed bool)
                (images-before (string-ascii 500))
                (images-after (string-ascii 500))
                (notes (string-ascii 500)))
  (let ((new-id (+ (var-get last-case-id) u1)))
    (var-set last-case-id new-id)
    (map-set repair-cases
      { case-id: new-id }
      {
        technician: tx-sender,
        device-id: device-id,
        guide-id: guide-id,
        diagnosis: diagnosis,
        solution: solution,
        parts-used: parts-used,
        repair-time: repair-time,
        success-level: success-level,
        follow-up-needed: follow-up-needed,
        images-before: images-before,
        images-after: images-after,
        notes: notes,
        creation-date: block-height
      }
    )
    (ok new-id)
  )
)

(define-public (rate-repair-guide
                (guide-id uint)
                (rating uint)
                (comments (string-ascii 500))
                (helpful bool))
  (match (map-get? repair-guides { guide-id: guide-id })
    guide
      (let ((new-id (+ (var-get last-rating-id) u1)))
        (var-set last-rating-id new-id)
        (map-set guide-ratings
          { rating-id: new-id }
          {
            guide-id: guide-id,
            user: tx-sender,
            rating: rating,
            comments: comments,
            helpful: helpful,
            rating-date: block-height
          }
        )
        (ok new-id)
      )
    ERR-NOT-FOUND
  )
)

(define-public (add-verifier (verifier principal))
  (if (is-eq tx-sender contract-caller)
    (begin
      (map-set verifiers { address: verifier } { is-verifier: true })
      (ok true)
    )
    ERR-NOT-AUTHORIZED
  )
)

(define-public (verify-repair-guide (guide-id uint) (verified bool))
  (match (map-get? verifiers { address: tx-sender })
    verifier
      (if (get is-verifier verifier)
        (match (map-get? repair-guides { guide-id: guide-id })
          guide
            (begin
              (map-set repair-guides
                { guide-id: guide-id }
                (merge guide { verification-status: verified })
              )
              (ok guide-id)
            )
          ERR-NOT-FOUND
        )
        ERR-NOT-AUTHORIZED
      )
    ERR-NOT-AUTHORIZED
  )
)

;; Read-only functions
(define-read-only (get-repair-guide (guide-id uint))
  (map-get? repair-guides { guide-id: guide-id })
)

(define-read-only (get-repair-case (case-id uint))
  (map-get? repair-cases { case-id: case-id })
)

(define-read-only (get-guide-rating (rating-id uint))
  (map-get? guide-ratings { rating-id: rating-id })
)

(define-read-only (get-guide-average-rating (guide-id uint))
  ;; In a real implementation, this would calculate the average rating
  ;; For simplicity, we're returning a default value
  (ok u0)
)

(define-read-only (find-guides-by-device (device-type (string-ascii 100)) (model (string-ascii 100)))
  ;; In a real implementation, this would search for guides for the device
  ;; For simplicity, we're returning an empty list
  (list)
)

(define-read-only (find-guides-by-issue (issue-type (string-ascii 100)))
  ;; In a real implementation, this would search for guides for the issue
  ;; For simplicity, we're returning an empty list
  (list)
)

(define-read-only (get-cases-by-device (device-id uint))
  ;; In a real implementation, this would return cases for the device
  ;; For simplicity, we're returning an empty list
  (list)
)

(define-read-only (get-last-guide-id)
  (var-get last-guide-id)
)

(define-read-only (get-last-case-id)
  (var-get last-case-id)
)

(define-read-only (get-last-rating-id)
  (var-get last-rating-id)
)
