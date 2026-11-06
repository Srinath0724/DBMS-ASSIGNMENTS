USE meridian_museum;
-- Q1 Overdue open custody lines
SELECT l.loan_code,x.artifact_id,x.due_date,le.lender_code
FROM loan_object x JOIN loan l ON l.loan_id=x.loan_id
JOIN lender le ON le.lender_id=l.lender_id
WHERE x.returned_at IS NULL AND x.due_date<CURRENT_TIMESTAMP ORDER BY x.due_date;
-- Q2 Artifacts without any condition evidence (empty result is still a result)
SELECT a.artifact_id,a.accession_no,a.title FROM artifact a
WHERE NOT EXISTS(SELECT 1 FROM loan_object x JOIN condition_report r
 ON r.loan_id=x.loan_id AND r.artifact_id=x.artifact_id WHERE x.artifact_id=a.artifact_id);
-- Q3 Custody history for artifact 1 (change parameter as required)
SELECT a.accession_no,l.loan_code,le.lender_code,x.received_at,x.due_date,x.returned_at
FROM artifact a JOIN loan_object x ON x.artifact_id=a.artifact_id
JOIN loan l ON l.loan_id=x.loan_id JOIN lender le ON le.lender_id=l.lender_id
WHERE a.artifact_id=1 ORDER BY x.received_at;
-- Q4 Loan contents and lender
SELECT l.loan_code,le.lender_code,x.artifact_id,x.received_at,x.due_date,x.returned_at
FROM loan l JOIN lender le ON le.lender_id=l.lender_id
JOIN loan_object x ON x.loan_id=l.loan_id ORDER BY l.loan_id,x.artifact_id;
-- Q5 Current exhibition placements
SELECT e.exhibition_name,s.slot_no,s.location_label,a.accession_no,l.loan_code,p.placed_from
FROM placement p JOIN exhibition e ON e.exhibition_id=p.exhibition_id
JOIN display_slot s ON s.exhibition_id=p.exhibition_id AND s.slot_no=p.slot_no
JOIN loan_object x ON x.loan_id=p.loan_id AND x.artifact_id=p.artifact_id
JOIN artifact a ON a.artifact_id=x.artifact_id JOIN loan l ON l.loan_id=x.loan_id
WHERE p.placed_to IS NULL OR p.placed_to>=CURRENT_TIMESTAMP;
-- Q6 Current ownership shares (separate from loan custody)
SELECT a.accession_no,o.owner_party_id,o.share_percent,o.valid_from
FROM current_artifact_owners o JOIN artifact a ON a.artifact_id=o.artifact_id;
-- Q7 Curators who also have lender role using shared identity
SELECT e.employee_no,p.given_name,p.family_name,l.lender_code
FROM employee e JOIN person p ON p.person_id=e.person_id
JOIN lender l ON l.party_id=p.person_id WHERE e.role='CURATOR';
-- Q8 Multi-artifact loans
SELECT loan_id,COUNT(*) AS artifact_line_count,
SUM(returned_at IS NULL) AS open_custody_lines FROM loan_object
GROUP BY loan_id HAVING COUNT(*)>1;
