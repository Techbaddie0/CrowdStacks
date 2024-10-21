;; CrowdStacks Smart Contract

(define-map projects 
    uint 
    {
        creator: principal, 
        goal: uint, 
        funds-raised: uint, 
        milestones: uint, 
        milestones-met: uint, 
        refunded: bool
    })

(define-map contributions 
    {
        project-id: uint, 
        funder: principal
    } 
    uint)

(define-data-var project-counter uint u0)

;; Error constants
(define-constant ERR_PROJECT_NOT_FOUND (err u100))
(define-constant ERR_PROJECT_FUNDED (err u101))
(define-constant ERR_PROJECT_FAILED (err u102))
(define-constant ERR_NOT_AUTHORIZED (err u103))
(define-constant ERR_MILESTONES_NOT_MET (err u104))
(define-constant ERR_INVALID_GOAL (err u105))
(define-constant ERR_INVALID_MILESTONES (err u106))
(define-constant ERR_INVALID_AMOUNT (err u107))
(define-constant ERR_INVALID_PROJECT_ID (err u108))

;; Helper functions for validation
(define-private (is-valid-goal (goal uint))
    (> goal u0))

(define-private (is-valid-milestones (milestones uint))
    (and (> milestones u0) (<= milestones u10)))

(define-private (is-valid-project-id (project-id uint))
    (< project-id (var-get project-counter)))

(define-public (create-project (goal uint) (milestones uint))
    (begin
        (asserts! (is-valid-goal goal) ERR_INVALID_GOAL)
        (asserts! (is-valid-milestones milestones) ERR_INVALID_MILESTONES)
        (let ((id (var-get project-counter)))
            (begin
                (map-set projects id {
                    creator: tx-sender, 
                    goal: goal, 
                    funds-raised: u0, 
                    milestones: milestones, 
                    milestones-met: u0, 
                    refunded: false
                })
                (var-set project-counter (+ id u1))
                (ok id)
            )
        )
    )
)

(define-public (fund-project (project-id uint) (amount uint))
    (begin
        (asserts! (is-valid-project-id project-id) ERR_INVALID_PROJECT_ID)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (let ((project (unwrap! (map-get? projects project-id) ERR_PROJECT_NOT_FOUND)))
            (let ((funds-raised (get funds-raised project)))
                (if (< funds-raised (get goal project))
                    (let ((new-funds (+ funds-raised amount)))
                        (begin
                            (try! (stx-transfer? amount tx-sender (get creator project)))
                            (map-set projects project-id (merge project {funds-raised: new-funds}))
                            (map-set contributions {project-id: project-id, funder: tx-sender} amount)
                            (ok true)
                        )
                    )
                    (ok false)
                )
            )
        )
    )
)

(define-public (complete-milestone (project-id uint))
    (begin
        (asserts! (is-valid-project-id project-id) ERR_INVALID_PROJECT_ID)
        (let ((project (unwrap! (map-get? projects project-id) ERR_PROJECT_NOT_FOUND)))
            (asserts! (is-eq tx-sender (get creator project)) ERR_NOT_AUTHORIZED)
            (let ((milestones-met (get milestones-met project))
                  (milestones (get milestones project)))
                (if (< milestones-met milestones)
                    (begin
                        (map-set projects project-id (merge project {milestones-met: (+ milestones-met u1)}))
                        (ok true)
                    )
                    ERR_MILESTONES_NOT_MET
                )
            )
        )
    )
)

(define-public (withdraw-funds (project-id uint))
    (begin
        (asserts! (is-valid-project-id project-id) ERR_INVALID_PROJECT_ID)
        (let ((project (unwrap! (map-get? projects project-id) ERR_PROJECT_NOT_FOUND)))
            (asserts! (is-eq tx-sender (get creator project)) ERR_NOT_AUTHORIZED)
            (let ((milestones-met (get milestones-met project))
                  (goal (get goal project))
                  (funds-raised (get funds-raised project)))
                (if (>= funds-raised goal)
                    (begin
                        (try! (stx-transfer? 
                            (* (/ milestones-met (get milestones project)) funds-raised) 
                            (get creator project) 
                            tx-sender))
                        (ok true)
                    )
                    (ok false)
                )
            )
        )
    )
)

(define-public (refund (project-id uint))
    (begin
        (asserts! (is-valid-project-id project-id) ERR_INVALID_PROJECT_ID)
        (let ((project (unwrap! (map-get? projects project-id) ERR_PROJECT_NOT_FOUND)))
            (if (and (not (get refunded project)) 
                     (< (get milestones-met project) (get milestones project)))
                (let ((contribution (unwrap! (map-get? contributions {project-id: project-id, funder: tx-sender}) ERR_PROJECT_FAILED)))
                    (begin
                        (try! (stx-transfer? contribution (get creator project) tx-sender))
                        (map-set projects project-id (merge project {refunded: true}))
                        (ok true)
                    )
                )
                (ok false)
            )
        )
    )
)