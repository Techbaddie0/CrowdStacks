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

(define-constant ERR_PROJECT_NOT_FOUND (err u100))
(define-constant ERR_PROJECT_FUNDED (err u101))
(define-constant ERR_PROJECT_FAILED (err u102))
(define-constant ERR_NOT_AUTHORIZED (err u103))
(define-constant ERR_MILESTONES_NOT_MET (err u104))

(define-public (create-project (goal uint) (milestones uint))
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

(define-public (fund-project (project-id uint) (amount uint))
    (let ((project (map-get? projects project-id)))
        (match project
            project-value
            (let ((funds-raised (get funds-raised project-value)))
                (if (< funds-raised (get goal project-value))
                    (let ((new-funds (+ funds-raised amount)))
                        (begin
                            (try! (stx-transfer? amount tx-sender (get creator project-value)))
                            (map-set projects project-id (merge project-value {funds-raised: new-funds}))
                            (map-set contributions {project-id: project-id, funder: tx-sender} amount)
                            (ok true)
                        )
                    )
                    (ok false)
                )
            )
            ERR_PROJECT_NOT_FOUND
        )
    )
)

(define-public (complete-milestone (project-id uint))
    (let ((project (map-get? projects project-id)))
        (match project
            project-value
            (if (is-eq tx-sender (get creator project-value))
                (let ((milestones-met (get milestones-met project-value))
                      (milestones (get milestones project-value)))
                    (if (< milestones-met milestones)
                        (begin
                            (map-set projects project-id (merge project-value {milestones-met: (+ milestones-met u1)}))
                            (ok true)
                        )
                        ERR_MILESTONES_NOT_MET
                    )
                )
                ERR_NOT_AUTHORIZED
            )
            ERR_PROJECT_NOT_FOUND
        )
    )
)

(define-public (withdraw-funds (project-id uint))
    (let ((project (map-get? projects project-id)))
        (match project
            project-value
            (if (is-eq tx-sender (get creator project-value))
                (let ((milestones-met (get milestones-met project-value))
                      (goal (get goal project-value))
                      (funds-raised (get funds-raised project-value)))
                    (if (>= funds-raised goal)
                        (begin
                            (try! (stx-transfer? 
                                (* (/ milestones-met (get milestones project-value)) funds-raised) 
                                (get creator project-value) 
                                tx-sender))
                            (ok true)
                        )
                        (ok false)
                    )
                )
                ERR_NOT_AUTHORIZED
            )
            ERR_PROJECT_NOT_FOUND
        )
    )
)

(define-public (refund (project-id uint))
    (let ((project (map-get? projects project-id)))
        (match project
            project-value
            (if (and (not (get refunded project-value)) 
                     (< (get milestones-met project-value) (get milestones project-value)))
                (let ((contribution (map-get? contributions {project-id: project-id, funder: tx-sender})))
                    (match contribution
                        amount
                        (begin
                            (try! (stx-transfer? amount (get creator project-value) tx-sender))
                            (map-set projects project-id (merge project-value {refunded: true}))
                            (ok true)
                        )
                        ERR_PROJECT_FAILED
                    )
                )
                (ok false)
            )
            ERR_PROJECT_NOT_FOUND
        )
    )
)