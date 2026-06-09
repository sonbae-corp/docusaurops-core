---
name: Specification
description: Create a new specification following INVEST criteria and persona-driven format
title: "[Role] - [Action or Feature]"
labels: [specification]
---

## Summary

```
Following INVEST criteria, write a high-level description of what needs to be delivered:
- Independent: Deliverable on its own with minimal dependency on other features
- Negotiable: Describes the outcome and intent, not a fixed implementation
- Valuable: Clearly states value for an identified persona (user or service)
- Estimable: Has enough context and scope for reliable effort estimation
- Small: Sized to fit within a sprint (typically up to 2 weeks); split if larger
- Testable: Includes measurable acceptance criteria to confirm completion

IMPORTANT: Write as a persona-driven action in context, NOT as a technical task:
  ❌ WRONG: "Implement a button to submit the order"
  ✅ RIGHT: "Client - Submit an order after reviewing my cart"

Include:
- Who performs the action (user, background process, service, etc.)
- What the feature or action is
- The context where it's used in the solution
```

[role] - [action or feature]

```
Add here original requirements numbers refernece from any source material if applicable.
``` 

---

## Prerequisites

```
List all requirements needed before this specification can be implemented:

Include:
- Infrastructure or components from other features that must be deployed
- External dependencies or services that must be accessible
- Information or clarifications needed (functional or non-functional)
- Data preparation or cleanup required for development environments

If no prerequisites exist, state "None" or "N/A".

Examples of valid prerequisites:
- Service XYZ must be accessible and configured with [specific settings]
- Resource ABC must be created in [environment]
- Data in [store] needs to be migrated or cleaned
- Feature/Issue #123 must be completed first
```

**List prerequisites here or state N/A if none**

---

## Acceptance Criteria

```
Define measurable and testable behaviors that confirm successful completion.
Criteria must be precise enough for developers and QA to validate implementation.

CRITICAL: Reject unclear or subjective requirements and request clarification:
  ❌ WRONG: "The operation should be fast"
  ✅ RIGHT: "The operation completes in 1-3 seconds from start to finish"
  
  ❌ WRONG: "The feature should be secure"
  ✅ RIGHT: "Only users from Entra ID group 'XYZ' with roles 'A' and 'B' can access; all others receive HTTP 403"

Each criterion should:
- Be testable and verifiable
- Specify measurable thresholds (time, percentage, limits, etc.)
- Define access controls and permissions explicitly
- Include both happy path and edge cases where relevant
```

- [ ] **Criterion 1**: [Describe expected behavior with measurable outcomes]
- [ ] **Criterion 2**: [Describe expected behavior with measurable outcomes]
- [ ] **Criterion 3**: [Add more criteria as needed]

---
