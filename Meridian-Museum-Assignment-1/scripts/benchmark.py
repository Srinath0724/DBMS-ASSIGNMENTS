#!/usr/bin/env python3
"""Measure medians on a loaded population; run once for each population."""
import argparse,csv,os,statistics,time
from pathlib import Path
import mysql.connector
Q={
"Q1_overdue":"SELECT loan_id,artifact_id FROM loan_object WHERE returned_at IS NULL AND due_date<CURRENT_TIMESTAMP",
"Q2_no_report":"SELECT a.artifact_id FROM artifact a WHERE NOT EXISTS(SELECT 1 FROM loan_object x JOIN condition_report r ON r.loan_id=x.loan_id AND r.artifact_id=x.artifact_id WHERE x.artifact_id=a.artifact_id)",
"Q4_loan_lines":"SELECT l.loan_id,x.artifact_id FROM loan l JOIN loan_object x ON x.loan_id=l.loan_id",
"Q5_placements":"SELECT p.placement_id FROM placement p JOIN display_slot s ON s.exhibition_id=p.exhibition_id AND s.slot_no=p.slot_no WHERE p.placed_to IS NULL OR p.placed_to>=CURRENT_TIMESTAMP",
"Q6_owners":"SELECT artifact_id,owner_party_id FROM current_artifact_owners",
"Q7_curator_lender":"SELECT e.employee_id FROM employee e JOIN lender l ON l.party_id=e.person_id WHERE e.role='CURATOR'",
"Q8_multi_line":"SELECT loan_id FROM loan_object GROUP BY loan_id HAVING COUNT(*)>1"}
def main():
 p=argparse.ArgumentParser();p.add_argument("--host",default="localhost");p.add_argument("--port",type=int,default=3306);p.add_argument("--user",default="root");p.add_argument("--password",default="");p.add_argument("--database",default="meridian_museum");p.add_argument("--population",type=int,required=True,choices=[100,1000,10000,100000]);p.add_argument("--repeats",type=int,default=7);p.add_argument("--output",default="results/benchmark.csv");a=p.parse_args()
 c=mysql.connector.connect(host=a.host,port=a.port,user=a.user,password=a.password or os.getenv("MYSQL_PWD",""),database=a.database);cur=c.cursor();rows=[]
 for name,sql in Q.items():
  samples=[];count=0
  for _ in range(a.repeats):
   t=time.perf_counter();cur.execute(sql);res=cur.fetchall();samples.append((time.perf_counter()-t)*1000);count=len(res)
  rows.append({"population":a.population,"query":name,"result_count":count,"explicit_join_count":sql.upper().count(" JOIN "),"repeats":a.repeats,"median_ms":round(statistics.median(samples),3),"samples_ms":";".join(f"{x:.3f}" for x in samples)})
 out=Path(a.output);out.parent.mkdir(parents=True,exist_ok=True);new=not out.exists()
 with out.open("a",newline="",encoding="utf-8") as f:
  w=csv.DictWriter(f,fieldnames=rows[0].keys())
  if new:w.writeheader()
  w.writerows(rows)
 print("Appended",len(rows),"measurements to",out);cur.close();c.close()
if __name__=="__main__":main()
