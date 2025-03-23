;; Device Registration Contract
;; Records details of assistive technologies needing repair

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u403))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))

;; Data structures
(define-map devices
  { device-id: uint }
  {
    owner: principal,
    device-type: (string-ascii 100),
    manufacturer: (string-ascii 100),
    model: (string-ascii 100),
    serial-number: (string-ascii 100),
    year: uint,
    issue-description: (string-ascii 500),
    urgency-level: (string-ascii 20), ;; "low", "medium", "high", "critical"
    location: (string-ascii 200),
    images: (string-ascii 500),
    status: (string-ascii 20), ;; "registered", "matched", "in-repair", "fixed", "unfixable"
    registration-date: uint
  }
)

(define-map device-history
  { history-id: uint }
  {
    device-id: uint,
    status: (string-ascii 20),
    notes: (string-ascii 500),
    updated-by: principal,
    timestamp: uint
  }
)

(define-data-var last-device-id uint u0)
(define-data-var last-history-id uint u0)

;; Public functions
(define-public (register-device
                (device-type (string-ascii 100))
                (manufacturer (string-ascii 100))
                (model (string-ascii 100))
                (serial-number (string-ascii 100))
                (year uint)
                (issue-description (string-ascii 500))
                (urgency-level (string-ascii 20))
                (location (string-ascii 200))
                (images (string-ascii 500)))
  (let ((new-id (+ (var-get last-device-id) u1)))
    (var-set last-device-id new-id)
    (map-set devices
      { device-id: new-id }
      {
        owner: tx-sender,
        device-type: device-type,
        manufacturer: manufacturer,
        model: model,
        serial-number: serial-number,
        year: year,
        issue-description: issue-description,
        urgency-level: urgency-level,
        location: location,
        images: images,
        status: "registered",
        registration-date: block-height
      }
    )
    ;; Add initial history entry
    (add-history-entry new-id "registered" "Device registered for repair")
    (ok new-id)
  )
)

(define-public (update-device-info
                (device-id uint)
                (issue-description (string-ascii 500))
                (urgency-level (string-ascii 20))
                (location (string-ascii 200))
                (images (string-ascii 500)))
  (match (map-get? devices { device-id: device-id })
    device
      (if (is-eq tx-sender (get owner device))
        (begin
          (map-set devices
            { device-id: device-id }
            (merge device {
              issue-description: issue-description,
              urgency-level: urgency-level,
              location: location,
              images: images
            })
          )
          (add-history-entry device-id (get status device) "Device information updated")
          (ok device-id)
        )
        ERR-NOT-AUTHORIZED
      )
    ERR-NOT-FOUND
  )
)

(define-public (update-device-status
                (device-id uint)
                (status (string-ascii 20))
                (notes (string-ascii 500)))
  (match (map-get? devices { device-id: device-id })
    device
      (if (or (is-eq tx-sender (get owner device))
              (is-authorized-technician tx-sender device-id))
        (begin
          (map-set devices
            { device-id: device-id }
            (merge device { status: status })
          )
          (add-history-entry device-id status notes)
          (ok device-id)
        )
        ERR-NOT-AUTHORIZED
      )
    ERR-NOT-FOUND
  )
)

;; Private functions
(define-private (add-history-entry (device-id uint) (status (string-ascii 20)) (notes (string-ascii 500)))
  (let ((new-id (+ (var-get last-history-id) u1)))
    (var-set last-history-id new-id)
    (map-set device-history
      { history-id: new-id }
      {
        device-id: device-id,
        status: status,
        notes: notes,
        updated-by: tx-sender,
        timestamp: block-height
      }
    )
    new-id
  )
)

(define-private (is-authorized-technician (technician principal) (device-id uint))
  ;; In a real implementation, this would check if the technician is assigned to this device
  ;; For simplicity, we're returning false
  false
)

;; Read-only functions
(define-read-only (get-device (device-id uint))
  (map-get? devices { device-id: device-id })
)

(define-read-only (get-device-history (device-id uint))
  ;; In a real implementation, this would return all history entries for the device
  ;; For simplicity, we're returning an empty list
  (list)
)

(define-read-only (get-devices-by-status (status (string-ascii 20)))
  ;; In a real implementation, this would return all devices with the given status
  ;; For simplicity, we're returning an empty list
  (list)
)

(define-read-only (get-devices-by-owner (owner principal))
  ;; In a real implementation, this would return all devices owned by the given principal
  ;; For simplicity, we're returning an empty list
  (list)
)

(define-read-only (get-last-device-id)
  (var-get last-device-id)
)
