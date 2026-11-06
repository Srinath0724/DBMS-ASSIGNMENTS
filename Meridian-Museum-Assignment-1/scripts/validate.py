#!/usr/bin/env python3
"""Execute the operational queries and capture actual MySQL errors."""
import argparse,json,os,time
from pathlib import Path
import mysql.connector
Q={
"Q1_overdue":"SELECT loan_id,artifact_id,due_date FROM loan_object WHERE returned_at IS NULL AND due_date<CURRENT_TIMESTAMP",
"Q2_no_report":"SELECT a.artifact_id FROM artifact a WHERE NOT EXISTS(SELECT 1 FROM loan_object x JOIN condition_report r ON r.loan_id=x.loan_id AND r.artifact_id=x.artifact_id WHERE x.artifact_id=a.artifact_id)",
"Q3_history":"SELECT * FROM loan_object ORDER BY artifact_id,received_at",
"Q4_loan_lines":"SELECT l.loan_code,x.artifact_id FROM loan l JOIN loan_object x ON x.loan_id=l.loan_id",
"Q5_placements":"SELECT * FROM placement WHERE placed_to IS NULL OR placed_to>=CURRENT_TIMESTAMP",
"Q6_owners":"SELECT * FROM current_artifact_owners",
"Q7_curator_lender":"SELECT e.employee_no,l.lender_code FROM employee e JOIN lender l ON l.party_id=e.person_id WHERE e.role='CURATOR'",
"Q8_multi_line":"SELECT loan_id,COUNT(*) n FROM loan_object GROUP BY loan_id HAVING COUNT(*)>1"}
def main():
 p=argparse.ArgumentParser();p.add_argument("--host",default="localhost");p.add_argument("--port",type=int,default=3306);p.add_argument("--user",default="root");p.add_argument("--password",default="");p.add_argument("--database",default="meridian_museum");p.add_argument("--output",default="results/validation_output.json");a=p.parse_args()
 c=mysql.connector.connect(host=a.host,port=a.port,user=a.user,password=a.password or os.getenv("MYSQL_PWD",""),database=a.database);cur=c.cursor(dictionary=True)
 out={"queries":{},"negative_tests":[]}
 for name,sql in Q.items():
  t=time.perf_counter();cur.execute(sql);rows=cur.fetchall();out["queries"][name]={"row_count":len(rows),"elapsed_ms":round((time.perf_counter()-t)*1000,3),"sample":rows[:10],"empty":not rows}
 tests=[
 ("duplicate_accession","INSERT INTO artifact(accession_no,title,unit_id,collection_type_id) VALUES('MM-00000001','duplicate',1,1)"),
 ("missing_lender","INSERT INTO loan(loan_code,lender_id,created_by_employee_id,loan_date) VALUES('BAD',999999999,1,CURRENT_DATE)"),
 ("bad_dates","INSERT INTO loan_object(loan_id,artifact_id,received_at,due_date) VALUES(1,999999999,'2026-06-02','2026-06-01')"),
 ("bad_contact_union","INSERT INTO contact_target(target_type,person_id,organization_id) VALUES('PERSON',NULL,NULL)")]
 for name,sql in tests:
  try:cur.execute(sql);c.rollback();out["negative_tests"].append({"test":name,"unexpected_success":True})
  except mysql.connector.Error as e:c.rollback();out["negative_tests"].append({"test":name,"errno":e.errno,"sqlstate":e.sqlstate,"message":str(e)})
 Path(a.output).parent.mkdir(parents=True,exist_ok=True);Path(a.output).write_text(json.dumps(out,indent=2,default=str),encoding="utf-8")
 print("Saved actual MySQL observations to",a.output);cur.close();c.close()
if __name__=="__main__":main()
