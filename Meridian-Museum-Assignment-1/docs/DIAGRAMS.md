# ER/EER diagrams – Meridian Museum

## Preferred ER model
```mermaid
erDiagram
 PARTY ||--o| PERSON : subtype
 PARTY ||--o| ORGANIZATION : subtype
 PERSON ||--o| EMPLOYEE : role
 PARTY ||--o| LENDER : role
 LENDER ||--o{ LOAN : lends
 EMPLOYEE ||--o{ LOAN : creates
 LOAN ||--|{ LOAN_OBJECT : contains
 ARTIFACT ||--o{ LOAN_OBJECT : custody_history
 LOAN_OBJECT ||--o{ CONDITION_REPORT : evidence
 COLLECTION_UNIT ||--o{ ARTIFACT : contains
 COLLECTION_TYPE ||--o{ ARTIFACT : classifies
 EXHIBITION ||--|{ DISPLAY_SLOT : identifies
 DISPLAY_SLOT ||--o{ PLACEMENT : hosts
 LOAN_OBJECT ||--o{ PLACEMENT : displayed_as
 ARTIFACT ||--o{ ARTIFACT_OWNER : ownership_history
 PARTY ||--o{ ARTIFACT_OWNER : owns
 PARTY ||--o{ PARTY_PHONE : has
```

## EER roles
```mermaid
erDiagram
 PARTY ||--o| PERSON : subtype
 PARTY ||--o| ORGANIZATION : subtype
 PERSON ||--o| EMPLOYEE : employee
 PERSON ||--o| LENDER : personal_lender
 EMPLOYEE ||--o| CURATOR_VIEW : role_CURATOR
 EMPLOYEE ||--o| REGISTRAR_VIEW : role_REGISTRAR
 PERSON ||--o{ CONTACT_TARGET : union_member
 ORGANIZATION ||--o{ CONTACT_TARGET : union_member
```

EMPLOYEE has a role discriminator: CURATOR, REGISTRAR or SUPPORT. Roles are disjoint in this implementation; the specialization is partial if support staff exist. A curator who lends privately uses the same PERSON identity for employee and lender roles. CONTACT_TARGET is a union/category over PERSON and ORGANIZATION; each row points to exactly one subtype.

## Changed ownership history
```mermaid
erDiagram
 ARTIFACT ||--o{ ARTIFACT_OWNER : has_versions
 PARTY ||--o{ ARTIFACT_OWNER : owner
 ARTIFACT_OWNER {
   bigint artifact_id PK,FK
   bigint owner_party_id PK,FK
   date valid_from PK
   date valid_to
   decimal share_percent
 }
```

Example: artifact A-10 has P1 60% and P2 40% from Jan 1 to Jun 30. From Jul 1, P1 has 50%, P2 30%, P3 20%. The loan custody interval may span this ownership change and remains unchanged.

## Chen notation legend
- Rectangle: strong entity; double rectangle: weak entity DISPLAY_SLOT.
- Diamond: relationship; double diamond: identifying relationship EXHIBITION–DISPLAY_SLOT.
- Underlined attribute: primary key; slot_no is the weak entity's partial key.
- Dashed oval: derived attribute; double oval: multivalued attribute.
- Composite oval: person name decomposed into given/middle/family.
- ISA triangle: specialization/generalization.
- Double line: total participation; single line: optional participation.
- DISPLAY_SLOT full key is (exhibition_id, slot_no). Slot numbers are not globally unique.
- PLACEMENT references the composite slot key, not slot_no alone.
