Feature: Visibility and permissions in the Scrum object model
  In order to protect team-internal context and share outcomes
  As a Scrum Team
  We enforce public/team/private visibility and role-based permissions.

  Background:
    Given a team "Atlas Scrum" with policies applied
    And member "Riley (PO)" has role "ProductOwner"
    And member "Kai (SM)" has role "ScrumMaster"
    And member "Ava Dev" has role "Developer"
    And member "Noah QA" has role "QA"
    And member "Pat Stakeholder" has role "Stakeholder"
    And backlog item "PB-101" visibility is "team" with exception "Pat Stakeholder" can "view"
    And backlog item "PB-102" visibility is "private" without exceptions
    And backlog item "PB-103" visibility is "public"
    And the Definition of Done includes "All AC pass", "Automated tests >= 80%", "Security scan clean"

  #
  # Visibility scenarios
  #

  Scenario: Stakeholder can view demo and selected items
    When a "SprintReview" event is created with visibility "public"
    Then "Pat Stakeholder" CAN view the event
    And "Pat Stakeholder" CAN view "PB-101" due to exception
    And "Pat Stakeholder" CANNOT edit "PB-101"

  Scenario: Team-only Daily Scrum is hidden from Stakeholders
    When a "DailyScrum" event is created with visibility "team"
    Then "Pat Stakeholder" CANNOT view the event
    And "Riley (PO)" CAN view the event
    And "Ava Dev" CAN view the event
    And "Noah QA" CAN view the event

  Scenario: Private backlog item is inaccessible without exception
    Then "Pat Stakeholder" CANNOT view "PB-102"
    And "Riley (PO)" CANNOT view "PB-102"
    But "Kai (SM)" CANNOT view "PB-102"
    And "Ava Dev" CANNOT view "PB-102"
    # Only explicit exceptions would grant access

  Scenario: Public backlog item is visible to all roles
    Then "Pat Stakeholder" CAN view "PB-103"
    And "Riley (PO)" CAN view "PB-103"
    And "Kai (SM)" CAN view "PB-103"
    And "Ava Dev" CAN view "PB-103"
    And "Noah QA" CAN view "PB-103"

  #
  # Permission scenarios
  #

  Scenario: Product Owner prioritizes the Product Backlog
    When "Riley (PO)" reorders backlog items
    Then the operation is allowed by "Backlog.Reorder"

  Scenario: Developer updates remaining hours on Sprint Backlog
    Given backlog item "PB-101" is in Sprint Backlog "S-12"
    When "Ava Dev" updates "PB-101" remaining hours to "6"
    Then the operation is allowed by "Sprint.UpdateRemaining"
    And the remaining hours of "PB-101" are updated to "6"

  Scenario: QA records test result and blocks item
    Given backlog item "PB-101" is in status "InProgress"
    When "Noah QA" sets status of "PB-101" to "Blocked" with reason "failing tests"
    Then the operation is allowed by "Item.Test"
    And "PB-101" status becomes "Blocked"

  Scenario: Scrum Master facilitates Sprint Planning
    When "Kai (SM)" facilitates a "SprintPlanning" event
    Then the operation is allowed by "Event.Facilitate"

  #
  # Negative permission checks
  #

  Scenario: Stakeholder cannot reorder backlog
    When "Pat Stakeholder" attempts to reorder backlog items
    Then the operation is denied by policy
    And an error message "Permission denied: Backlog.Reorder requires ProductOwner" is shown

  Scenario: Developer cannot accept backlog item
    When "Ava Dev" attempts to accept backlog item "PB-101"
    Then the operation is denied by policy
    And an error message "Permission denied: Item.Accept requires ProductOwner" is shown

  Scenario: QA cannot invite new team members
    When "Noah QA" attempts to invite a new member "Chris Observer"
    Then the operation is denied by policy
    And an error message "Permission denied: Team.Invite requires ScrumMaster" is shown

  #
  # End-to-end increment validation
  #

  Scenario: Increment is marked done when all conditions are met
    Given backlog item "PB-101" has status "Done"
    And all acceptance criteria pass
    And automated tests coverage is 85%
    And security scan results are clean
    When increment "INC-12" is published for Sprint "S-12"
    Then increment "INC-12" is marked "Accepted"
    And increment "INC-12" is visible as "public"
