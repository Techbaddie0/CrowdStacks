# CrowdStacks Smart Contract

A decentralized crowdfunding platform built on Stacks blockchain that enables milestone-based funding and transparent project tracking.

## Features

- Create crowdfunding projects with customizable goals and milestones
- Secure fund collection and distribution
- Milestone tracking and verification
- Automatic refund mechanism for failed projects
- Project status tracking (Active, Completed, Refunded)

## Contract Functions

### Project Creation and Management

- create-project: Create a new crowdfunding project
- complete-milestone: Mark project milestones as completed
- withdraw-funds: Withdraw funds based on completed milestones

### Funding Operations

- fund-project: Contribute STX to a project
- refund: Request refund for failed projects

## Project States

- STATUS-ACTIVE (1): Project is accepting funds and completing milestones
- STATUS-COMPLETED (2): All milestones completed
- STATUS-REFUNDED (3): Project failed, funds returned

## Usage Examples

### Creating a Project

clarity
(contract-call? .crowdstacks create-project u1000000 u3)
;; Creates project with 1M STX goal and 3 milestones


### Contributing to a Project

clarity
(contract-call? .crowdstacks fund-project u1 u50000)
;; Contributes 50k STX to project #1


### Completing Milestones

clarity
(contract-call? .crowdstacks complete-milestone u1)
;; Marks next milestone as complete for project #1


## Error Codes

- ERR_PROJECT_NOT_FOUND (u100): Project ID doesn't exist
- ERR_NOT_AUTHORIZED (u103): Caller not authorized
- ERR_MILESTONES_NOT_MET (u104): Required milestones not completed
- ERR_INVALID_STATUS (u109): Invalid project status for operation

## Security Features

- Input validation for all parameters
- Status-based operation restrictions
- Milestone-based fund release
- Creator-only milestone verification

## Development

### Prerequisites

- Clarinet
- Stacks blockchain environment

### Testing

Run the test suite:
bash
clarinet test

## Contributing

Pull requests welcome. For major changes, open an issue first.