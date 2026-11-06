# CSA05 – Database Management Systems
## Assignment 1 – CO1: Meridian Museum (50 marks)

### Case interpretation
The museum has 8 collection units, 35 curators, 1,200 lenders and 9,000 artifacts in its stated starting scenario. A loan belongs to one lender and contains multiple artifacts. Artifacts may have successive loans. Display-slot numbers are local to an exhibition. A curator may also lend a privately owned object.

The design must distinguish **legal ownership**, **temporary museum custody**, **exhibition placement** and **condition evidence**. A lender is not necessarily the legal owner: the lender may be an agent or authorised party.

---

## Task 1 – Conceptual alternatives (5 marks)

**Users:** registrars create loan agreements; curators request and place objects; conservators create condition reports; exhibition planners assign slots; administrators maintain identifiers and integrity.

**Alternative A – dated LENDER–ARTIFACT relationship.** Store start, due and return dates on a dated association. It is compact, but the association has no convenient independent loan identity. If one loan covers two artifacts, agreement facts are repeated. Failure case: artifact A-17 and A-18 are returned on different dates; a flat relationship duplicates loan-level facts and makes “loan L-204” hard to reference as one event.

**Alternative B – independent LOAN and LOAN_OBJECT (preferred).** LOAN has a stable loan_id, one lender and agreement-level facts. LOAN_OBJECT has one row per artifact in that loan, with received, due and returned dates. CONDITION_REPORT references the exact custody line. This supports successive loans for one artifact and different return dates for lines in the same loan. Failure case avoided: one line is returned while another remains in custody.

**Alternative C – LOAN plus CUSTODY_EPISODE.** Each physical handover is a separate event linked to the agreement and artifact. This is flexible if repeated handovers happen under one agreement, but adds an entity and joins. The given case can use LOAN_OBJECT as the custody episode unless more complex handovers are required.

| Criterion | A dated relationship | B LOAN + line | C custody episode |
|---|---|---|---|
| Independent loan identity | Weak | Yes | Yes |
| Different dates per artifact | Possible | Yes | Yes |
| Condition evidence reference | Awkward | Direct | Direct |
| Complexity | Low | Medium | High |

**Decision:** Alternative B best matches the stated requirements.

**Separate LENDER and employee?** Separate unrelated records can duplicate a curator who lends a personal object. Use shared PARTY/PERSON identity, with EMPLOYEE and LENDER roles. CURATOR is an employee role, not a second person. Custody and condition evidence remain linked to LOAN_OBJECT, never to an employee identity.

---

## Task 2 – Entities, attributes and keys (2 marks)

| Entity | Primary key | Attributes / types |
|---|---|---|
| PARTY | party_id | party_type, created_at |
| PERSON | person_id | given, middle, family name, email |
| ORGANIZATION | organization_id | name, registration number |
| EMPLOYEE | employee_id | person_id, employee_no, role |
| LENDER | lender_id | party_id, lender_code, registered_at |
| COLLECTION_UNIT | unit_id | unit_name |
| COLLECTION_TYPE | type_id | type_name, description |
| ARTIFACT | artifact_id | accession_no, title, unit_id, type_id |
| EXHIBITION | exhibition_id | code, name, start/end |
| DISPLAY_SLOT | exhibition_id + slot_no | location, capacity |
| LOAN | loan_id | lender_id, created_by, loan_date, status |
| LOAN_OBJECT | loan_id + artifact_id | received, due, returned, line_value |
| CONDITION_REPORT | report_id | custody key, type, date, grade, notes |
| PLACEMENT | placement_id | custody key, exhibition slot, dates |
| ARTIFACT_OWNER | artifact_id + owner_party_id + valid_from | share, valid_to |
| PARTY_PHONE | party_id + phone_no | phone_type |
| CONTACT_TARGET | contact_target_id | person or organization target |

Simple attributes include accession_no and due_date. Composite name is decomposed into given/middle/family. Phone numbers are multivalued. Current custody, overdue flag and ownership totals are derived. Collection type is coded and has its own description.

DISPLAY_SLOT is weak: slot_no is unique only inside its owning exhibition. Its full key is (exhibition_id, slot_no), not slot_no alone or exhibition name. Generated numeric IDs and UNIQUE business keys prevent collisions. Do not use MAX(id)+1 in concurrent application code.

---

## Task 3 – Relationships, bounds and ternary test (6 marks)

- LENDER 1:N LOAN: each loan has exactly one lender; a lender may have zero or many loans.
- LOAN 1:N LOAN_OBJECT: draft loan may temporarily have zero lines; a finalised loan must have one or more; each line belongs to exactly one loan.
- ARTIFACT 1:N LOAN_OBJECT: artifact has zero or many historical custody lines; each line refers to one artifact. At most one active line per artifact.
- LOAN_OBJECT 1:N CONDITION_REPORT: a custody line may have zero or many reports; each report belongs to exactly one line.
- EXHIBITION 1:N DISPLAY_SLOT: each slot belongs to exactly one exhibition.
- PLACEMENT connects one custody line to one owner-scoped display slot over a time interval.
- ARTIFACT M:N PARTY through ARTIFACT_OWNER, with share and validity dates.

Agreement facts (loan_date/status) belong on LOAN. Received/due/returned dates belong on LOAN_OBJECT. Placement dates belong on PLACEMENT. Legal ownership share and validity belong on ARTIFACT_OWNER. Report type/date/grade belong on CONDITION_REPORT.

**Ternary relationship example:** “curator C coordinates lender L for exhibition E.” Tuples: (L1,C1,E1), (L1,C2,E2), (L2,C1,E2). Binary projections contain (L1,C1),(L1,C2),(L2,C1); (L1,E1),(L1,E2),(L2,E2); (C1,E1),(C2,E2),(C1,E2). Joining projections can invent (L1,C1,E2), so the ternary fact is not reconstructed losslessly by its binary projections. Use a ternary relation only if this coordination fact is independently required. Otherwise LOAN and PLACEMENT store the actual operational facts.

---

## Task 4 – ER diagram (4 marks)

See [DIAGRAMS.md](DIAGRAMS.md). The diagram includes separate paths for borrowed custody, condition evidence, exhibition placement and legal ownership. DISPLAY_SLOT is drawn as a weak entity with an identifying relationship to EXHIBITION; underline slot_no as partial key. Show total participation of DISPLAY_SLOT in EXHIBITION. Include a legend for cardinality and participation.

---

## Task 5 – EER specialization and union category (3 marks)

PARTY is a shared identity supertype with PERSON and ORGANIZATION subtypes. PERSON may be an EMPLOYEE and/or LENDER. EMPLOYEE uses a role discriminator: CURATOR, REGISTRAR or SUPPORT. CURATOR and REGISTRAR are disjoint employee roles in this implementation; specialization is partial because SUPPORT employees may exist. A curator who lends privately has one PERSON identity with both roles.

A notification contact may be a PERSON or ORGANIZATION. CONTACT_TARGET is a union/category over those entity types. The relational design uses a target discriminator and exactly one nullable FK. A wide table containing every possible lender/employee/contact field creates NULLs, duplicated identities and update anomalies.

---

## Task 6 – Weak entity and attribute mapping (3 marks)

DISPLAY_SLOT is dependent on EXHIBITION and keyed by (exhibition_id, slot_no). PARTY_PHONE stores one phone per row. PERSON name is composite and decomposed. Current-owner share total, custody status and overdue status are derived from source rows/dates. COLLECTION_TYPE is a coded entity because it has its own description and is referenced by artifacts. Do not store comma-separated phone values or duplicate derived summaries.

---

## Task 7 – EER-to-relational mapping (4 marks)

Strong entities become relations with their own PKs. Weak DISPLAY_SLOT includes exhibition_id in its composite PK. The LENDER–LOAN 1:N FK is on LOAN. M:N ownership becomes ARTIFACT_OWNER with share and validity attributes. Placement becomes PLACEMENT with FKs to LOAN_OBJECT and DISPLAY_SLOT. Multivalued phones become PARTY_PHONE. PERSON/EMPLOYEE roles use EMPLOYEE with a role discriminator; CURATOR and REGISTRAR are filtered views. Historical loan, custody and report rows use RESTRICT deletion to preserve evidence. See [schema.sql](../database/schema.sql) for full PK/FK definitions.

---

## Task 8 – DDL and generated data (4 marks)

Use MySQL 8.0.16+ and InnoDB. DDL is in database/schema.sql. The generator creates deterministic workloads for 100, 1,000, 10,000 and 100,000 lenders using seed 4211. Parent IDs are generated before dependent rows and CSVs are written in FK order. The schema remains fixed while instances scale. A lender gets a party identity, one loan and two loan-object lines; 90% of custody lines receive a condition report in this synthetic workload.

Row-level checks include valid date order, positive share percentages and exactly one contact target type. Cross-row rules cannot be safely expressed as simple CHECK constraints: ownership shares must total 100 per artifact, ownership periods must not overlap, slot placements must respect capacity and time, artifacts must not have simultaneous active loans, and finalised loans must contain lines. Use transaction-safe triggers/procedures/application transactions. The validation script captures actual MySQL error code, SQLSTATE and message for rejected writes.

---

## Task 9 – Eight operational queries and anomalies (3 marks)

Queries in database/queries.sql:
1. overdue open custody;
2. artifacts with no condition evidence;
3. custody history for an artifact;
4. loan contents and lender;
5. active exhibition placements;
6. current owners and shares;
7. curators who are also lenders;
8. multi-artifact loans and open line count.

The anti-join query uses NOT EXISTS, so artifacts without condition evidence are included. Empty results are valid output and must be shown. Flat LOAN rows cause update anomaly (lender data repeated), insertion anomaly (cannot record lender until an artifact loan exists) and deletion anomaly (deleting the final artifact row can erase lender/loan facts). Separate entities avoid these anomalies. Use benchmark.py to record result count, explicit JOIN count and median elapsed time for each workload size; no unrun timing is claimed here.

---

## Task 10 – File, hierarchical, network, relational models (4 marks)

**File model:** separate files duplicate artifact descriptions and due dates; cross-file updates need custom code.  
**Hierarchical model:** LENDER→LOAN→LOAN_OBJECT→CONDITION_REPORT is a natural tree, but artifacts and curators participating in several loans/exhibitions create repeated paths and awkward shared ownership.  
**Network model:** owner-member sets support multiple links but retrieval depends on navigational paths and is less flexible than declarative SQL.  
**Relational model:** independent relations and SQL joins represent M:N and temporal relationships without duplicating entities.

Query trace A (overdue custody): scan file loan records; navigate lender→loan→line in hierarchical/network models; join LOAN and LOAN_OBJECT and filter due_date in relational SQL. Query trace B (artifacts without reports): compare artifact and report files; traverse artifact/custody/report branches; or use relational NOT EXISTS.

Three-schema architecture: external views for registrar/curator/planner; conceptual museum model; internal InnoDB pages, indexes, buffer pool and query execution. Concurrent transactions use locks/isolation, logging and recovery. Unique constraints prevent duplicate business keys; cross-row scheduling and ownership rules need serialised transactions.

---

## Task 11 – Recommendation (4 marks)

Recommend Alternative B: independent LOAN, artifact-level LOAN_OBJECT custody, condition reports tied to the custody line, and separate placement. It preserves different due/return dates per artifact and permits successive loans. Ownership is independent from custody. Row constraints and FK rules protect local integrity; temporal and aggregate rules require transaction-safe checks. At 100,000 lenders, indexes on foreign keys, artifact IDs, due dates and report joins are important. Compare actual query plans and medians rather than assuming a performance gain.

---

## Task 12 – Shared ownership and changing shares (8 marks)

**Impact analysis:** a single owner_id cannot represent several legal owners. Ownership becomes M:N and temporal. Add ARTIFACT_OWNER(artifact_id, owner_party_id, valid_from, valid_to, share_percent). Keep stable party_id and artifact_id. LOAN and LOAN_OBJECT still describe custody; the lender may be an owner, agent or authorised party.

**Evaluate original design:** LOAN remains valid because it records the loan agreement. LOAN_OBJECT remains valid because it records custody per artifact. Only the ownership representation must change. Rejected Alternative A still struggles with independent loan occurrence identity; Alternative C can model more handovers but still needs ARTIFACT_OWNER.

**Redesign and migration:** close existing owner rows and insert new version rows; never overwrite past ownership. Example: from Jan 1, P1 owns 60% and P2 40%; from Jul 1, P1 owns 50%, P2 30%, P3 20%. A loan received Jun 1 and returned Sep 1 remains the same custody line. Migration steps: (1) map each verified old owner to PARTY; (2) create a 100% ARTIFACT_OWNER row for the verified effective date; (3) do not invent historical owners/dates; flag uncertain history; (4) preserve loan, custody, condition and placement keys; (5) reconcile totals and intervals.

**Evidence and cost:** detect current share totals not equal to 100%, overlapping ownership intervals and artifacts missing required owner rows. Compare custody keys/dates and report counts before and after migration to prove custody evidence did not change. Existing loan/custody views remain stable; a current ownership view exposes owner shares. Cost is one association table, indexes, temporal validation and extra joins, justified by the new legal requirement.

### Conclusion
The best design keeps artifact identity, legal ownership, museum custody, exhibition placement and condition evidence separate but connected. Extend the original LOAN/LOAN_OBJECT design with time-versioned ARTIFACT_OWNER rather than replacing the custody model.

### Before submission
Add name/register number/date. Run the SQL and scripts. Insert actual query outputs, MySQL errors and median timings. Redraw Chen notation if required by the lecturer. Be ready to explain each design choice in your own words.
