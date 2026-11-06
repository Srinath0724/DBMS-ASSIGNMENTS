#!/usr/bin/env python3
"""Create deterministic CSV workloads (100/1k/10k/100k lenders), seed 4211."""
import argparse,csv,random
from pathlib import Path
from datetime import datetime,timedelta
FIRST=["Aarav","Ananya","Arjun","Diya","Ishaan","Kavya","Meera","Rohan"]
LAST=["Rao","Sharma","Iyer","Khan","Nair","Patel","Das","Menon"]

def put(folder,name,rows,cols):
 with (folder/name).open("w",newline="",encoding="utf-8") as f:
  w=csv.DictWriter(f,fieldnames=cols);w.writeheader();w.writerows(rows)

def generate(n,seed,out):
 r=random.Random(seed);d=Path(out)/f"lenders_{n}";d.mkdir(parents=True,exist_ok=True)
 party=[];person=[];org=[];lender=[];phone=[];employee=[];units=[];types=[]
 artifacts=[];exhibitions=[];slots=[];loans=[];lines=[];owners=[];reports=[];placements=[]
 for i in range(1,9):units.append(dict(unit_id=i,unit_name=f"Collection Unit {i}"))
 for i,x in enumerate(["Sculpture","Painting","Manuscript"],1):types.append(dict(collection_type_id=i,type_name=x,description=x+" collection"))
 person_ids=[]
 for i in range(1,n+1):
  isorg=i%10==0;party.append(dict(party_id=i,party_type="ORGANIZATION" if isorg else "PERSON"))
  lender.append(dict(lender_id=i,party_id=i,lender_code=f"L-{i:06d}",registered_at="2026-01-01 09:00:00"))
  phone.append(dict(party_id=i,phone_no=f"+910000{i:07d}",phone_type="MOBILE"))
  if isorg:org.append(dict(organization_id=i,organization_name=f"Heritage Trust {i}",registration_no=f"REG-{i:08d}"))
  else:
   person_ids.append(i);person.append(dict(person_id=i,given_name=r.choice(FIRST),middle_name="",family_name=r.choice(LAST),email=f"person{i}@example.test"))
 for e in range(1,36):
  if e<=min(5,len(person_ids)):pid=person_ids[e-1]
  else:
   pid=n+e;party.append(dict(party_id=pid,party_type="PERSON"))
   person.append(dict(person_id=pid,given_name=r.choice(FIRST),middle_name="",family_name=r.choice(LAST),email=f"employee{e}@example.test"))
  employee.append(dict(employee_id=e,person_id=pid,employee_no=f"EMP-{e:03d}",role="CURATOR" if e<=30 else "REGISTRAR",hired_on="2022-01-01"))
 aid=0
 for i in range(1,n+1):
  loans.append(dict(loan_id=i,loan_code=f"LN-{i:07d}",lender_id=i,created_by_employee_id=31+(i%5),loan_date="2026-01-01",agreement_status="ACTIVE",notes="Synthetic"))
  for j in range(2):
   aid+=1;unit=(aid-1)%8+1;typ=(aid-1)%3+1
   artifacts.append(dict(artifact_id=aid,accession_no=f"MM-{aid:08d}",title=f"Synthetic artifact {aid}",unit_id=unit,collection_type_id=typ,acquired_on="2020-01-01"))
   recv=datetime(2026,1,1,10)+timedelta(days=i%90);due=recv+timedelta(days=90)
   ret=(recv+timedelta(days=75)).strftime("%Y-%m-%d %H:%M:%S") if i%4==0 else ""
   lines.append(dict(loan_id=i,artifact_id=aid,received_at=recv.strftime("%Y-%m-%d %H:%M:%S"),due_date=due.strftime("%Y-%m-%d %H:%M:%S"),returned_at=ret,line_value="1000.00"))
   owners.append(dict(artifact_id=aid,owner_party_id=i,valid_from="2020-01-01",valid_to="",share_percent="100.00"))
   if aid%10:reports.append(dict(report_id=aid,loan_id=i,artifact_id=aid,report_type="INTAKE",report_date=recv.strftime("%Y-%m-%d %H:%M:%S"),condition_grade="GOOD",report_notes="Synthetic intake",recorded_by_employee_id=31+(i%5)))
 for e in range(1,9):
  exhibitions.append(dict(exhibition_id=e,exhibition_code=f"EX-{e:03d}",exhibition_name=f"Meridian Exhibition {e}",start_date="2026-01-01",end_date="2026-12-31"))
  for s in range(1,21):slots.append(dict(exhibition_id=e,slot_no=s,location_label=f"Gallery {e} / Slot {s}",capacity=1))
 for a in range(1,min(aid,160)+1):
  placements.append(dict(placement_id=a,loan_id=(a-1)//2+1,artifact_id=a,exhibition_id=(a-1)//20+1,slot_no=(a-1)%20+1,placed_from="2026-01-02 09:00:00",placed_to=""))
 schemas={
 "party.csv":(party,"party_id party_type"),"person.csv":(person,"person_id given_name middle_name family_name email"),
 "organization.csv":(org,"organization_id organization_name registration_no"),"employee.csv":(employee,"employee_id person_id employee_no role hired_on"),
 "lender.csv":(lender,"lender_id party_id lender_code registered_at"),"party_phone.csv":(phone,"party_id phone_no phone_type"),
 "collection_unit.csv":(units,"unit_id unit_name"),"collection_type.csv":(types,"collection_type_id type_name description"),
 "artifact.csv":(artifacts,"artifact_id accession_no title unit_id collection_type_id acquired_on"),
 "exhibition.csv":(exhibitions,"exhibition_id exhibition_code exhibition_name start_date end_date"),
 "display_slot.csv":(slots,"exhibition_id slot_no location_label capacity"),
 "loan.csv":(loans,"loan_id loan_code lender_id created_by_employee_id loan_date agreement_status notes"),
 "loan_object.csv":(lines,"loan_id artifact_id received_at due_date returned_at line_value"),
 "artifact_owner.csv":(owners,"artifact_id owner_party_id valid_from valid_to share_percent"),
 "condition_report.csv":(reports,"report_id loan_id artifact_id report_type report_date condition_grade report_notes recorded_by_employee_id"),
 "placement.csv":(placements,"placement_id loan_id artifact_id exhibition_id slot_no placed_from placed_to")}
 for name,(rows,cols) in schemas.items():put(d,name,rows,cols.split())
 (d/"LOAD_ORDER.txt").write_text("\n".join(schemas)+"\nLoad parent rows before dependent rows; blank nullable cells as NULL.\n",encoding="utf-8")
 return d
if __name__=="__main__":
 p=argparse.ArgumentParser();p.add_argument("--lenders",type=int,choices=[100,1000,10000,100000],default=100);p.add_argument("--seed",type=int,default=4211);p.add_argument("--output",default="data");a=p.parse_args()
 print("Generated:",generate(a.lenders,a.seed,a.output).resolve(),"CSV only; load before measuring MySQL.")
