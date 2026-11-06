-- MySQL 8.0.16+ / InnoDB
CREATE DATABASE IF NOT EXISTS meridian_museum CHARACTER SET utf8mb4;
USE meridian_museum;
SET FOREIGN_KEY_CHECKS=0;
DROP VIEW IF EXISTS current_artifact_owners;
DROP VIEW IF EXISTS active_custody;
DROP VIEW IF EXISTS curator;
DROP VIEW IF EXISTS registrar;
DROP TABLE IF EXISTS party_contact,contact_target,condition_report,placement,artifact_owner,display_slot,loan_object,loan,exhibition,artifact,collection_type,collection_unit,party_phone,lender,employee,organization,person,party;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE party(
 party_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 party_type ENUM('PERSON','ORGANIZATION') NOT NULL,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE person(
 person_id BIGINT UNSIGNED PRIMARY KEY,
 given_name VARCHAR(80) NOT NULL,middle_name VARCHAR(80),family_name VARCHAR(80) NOT NULL,email VARCHAR(254) UNIQUE,
 FOREIGN KEY(person_id) REFERENCES party(party_id) ON DELETE RESTRICT
) ENGINE=InnoDB;
CREATE TABLE organization(
 organization_id BIGINT UNSIGNED PRIMARY KEY,organization_name VARCHAR(180) NOT NULL,registration_no VARCHAR(80) UNIQUE,
 FOREIGN KEY(organization_id) REFERENCES party(party_id) ON DELETE RESTRICT
) ENGINE=InnoDB;
CREATE TABLE employee(
 employee_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,person_id BIGINT UNSIGNED NOT NULL UNIQUE,
 employee_no VARCHAR(30) NOT NULL UNIQUE,role ENUM('CURATOR','REGISTRAR','SUPPORT') NOT NULL,hired_on DATE,
 FOREIGN KEY(person_id) REFERENCES person(person_id) ON DELETE RESTRICT
) ENGINE=InnoDB;
CREATE VIEW curator AS SELECT employee_id,person_id,employee_no FROM employee WHERE role='CURATOR';
CREATE VIEW registrar AS SELECT employee_id,person_id,employee_no FROM employee WHERE role='REGISTRAR';
CREATE TABLE lender(
 lender_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,party_id BIGINT UNSIGNED NOT NULL UNIQUE,
 lender_code VARCHAR(30) NOT NULL UNIQUE,registered_at DATETIME NOT NULL,
 FOREIGN KEY(party_id) REFERENCES party(party_id) ON DELETE RESTRICT
) ENGINE=InnoDB;
CREATE TABLE party_phone(
 party_id BIGINT UNSIGNED NOT NULL,phone_no VARCHAR(30) NOT NULL,
 phone_type ENUM('MOBILE','WORK','HOME','OTHER') DEFAULT 'OTHER',
 PRIMARY KEY(party_id,phone_no),FOREIGN KEY(party_id) REFERENCES party(party_id) ON DELETE RESTRICT
) ENGINE=InnoDB;
CREATE TABLE contact_target(
 contact_target_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 target_type ENUM('PERSON','ORGANIZATION') NOT NULL,person_id BIGINT UNSIGNED,organization_id BIGINT UNSIGNED,
 CHECK((target_type='PERSON' AND person_id IS NOT NULL AND organization_id IS NULL) OR
       (target_type='ORGANIZATION' AND organization_id IS NOT NULL AND person_id IS NULL)),
 FOREIGN KEY(person_id) REFERENCES person(person_id) ON DELETE RESTRICT,
 FOREIGN KEY(organization_id) REFERENCES organization(organization_id) ON DELETE RESTRICT
) ENGINE=InnoDB;
CREATE TABLE party_contact(
 party_id BIGINT UNSIGNED NOT NULL,contact_target_id BIGINT UNSIGNED NOT NULL,
 purpose ENUM('NOTICE','BILLING','EMERGENCY','OTHER') NOT NULL,
 PRIMARY KEY(party_id,contact_target_id,purpose),
 FOREIGN KEY(party_id) REFERENCES party(party_id) ON DELETE RESTRICT,
 FOREIGN KEY(contact_target_id) REFERENCES contact_target(contact_target_id) ON DELETE RESTRICT
) ENGINE=InnoDB;
CREATE TABLE collection_unit(
 unit_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,unit_name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;
CREATE TABLE collection_type(
 collection_type_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 type_name VARCHAR(80) NOT NULL UNIQUE,description VARCHAR(255)
) ENGINE=InnoDB;
CREATE TABLE artifact(
 artifact_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,accession_no VARCHAR(40) NOT NULL UNIQUE,
 title VARCHAR(200) NOT NULL,unit_id SMALLINT UNSIGNED NOT NULL,
 collection_type_id SMALLINT UNSIGNED NOT NULL,acquired_on DATE,
 FOREIGN KEY(unit_id) REFERENCES collection_unit(unit_id) ON DELETE RESTRICT,
 FOREIGN KEY(collection_type_id) REFERENCES collection_type(collection_type_id) ON DELETE RESTRICT,
 INDEX ix_artifact_type(collection_type_id)
) ENGINE=InnoDB;
CREATE TABLE exhibition(
 exhibition_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,exhibition_code VARCHAR(30) NOT NULL UNIQUE,
 exhibition_name VARCHAR(180) NOT NULL,start_date DATE NOT NULL,end_date DATE NOT NULL,
 CHECK(end_date>=start_date)
) ENGINE=InnoDB;
-- Weak entity: local slot number is unique only within its exhibition.
CREATE TABLE display_slot(
 exhibition_id BIGINT UNSIGNED NOT NULL,slot_no SMALLINT UNSIGNED NOT NULL,
 location_label VARCHAR(100) NOT NULL,capacity SMALLINT UNSIGNED NOT NULL DEFAULT 1,
 PRIMARY KEY(exhibition_id,slot_no),CHECK(capacity>0),
 FOREIGN KEY(exhibition_id) REFERENCES exhibition(exhibition_id) ON DELETE RESTRICT
) ENGINE=InnoDB;
CREATE TABLE loan(
 loan_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,loan_code VARCHAR(40) NOT NULL UNIQUE,
 lender_id BIGINT UNSIGNED NOT NULL,created_by_employee_id BIGINT UNSIGNED NOT NULL,
 loan_date DATE NOT NULL,agreement_status ENUM('DRAFT','ACTIVE','CLOSED','CANCELLED') DEFAULT 'DRAFT',
 notes VARCHAR(500),
 FOREIGN KEY(lender_id) REFERENCES lender(lender_id) ON DELETE RESTRICT,
 FOREIGN KEY(created_by_employee_id) REFERENCES employee(employee_id) ON DELETE RESTRICT,
 INDEX ix_loan_lender_date(lender_id,loan_date),INDEX ix_loan_status(agreement_status)
) ENGINE=InnoDB;
CREATE TABLE loan_object(
 loan_id BIGINT UNSIGNED NOT NULL,artifact_id BIGINT UNSIGNED NOT NULL,
 received_at DATETIME NOT NULL,due_date DATETIME NOT NULL,returned_at DATETIME,line_value DECIMAL(14,2),
 active_artifact_id BIGINT UNSIGNED GENERATED ALWAYS AS(CASE WHEN returned_at IS NULL THEN artifact_id ELSE NULL END) STORED,
 PRIMARY KEY(loan_id,artifact_id),UNIQUE KEY uq_one_active_custody(active_artifact_id),
 CHECK(due_date>=received_at AND (returned_at IS NULL OR returned_at>=received_at)),
 CHECK(line_value IS NULL OR line_value>=0),
 FOREIGN KEY(loan_id) REFERENCES loan(loan_id) ON DELETE RESTRICT,
 FOREIGN KEY(artifact_id) REFERENCES artifact(artifact_id) ON DELETE RESTRICT,
 INDEX ix_line_artifact_date(artifact_id,received_at),INDEX ix_line_due(due_date,returned_at)
) ENGINE=InnoDB;
CREATE TABLE condition_report(
 report_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,loan_id BIGINT UNSIGNED NOT NULL,artifact_id BIGINT UNSIGNED NOT NULL,
 report_type ENUM('INTAKE','PERIODIC','DAMAGE','OUTGOING') NOT NULL,report_date DATETIME NOT NULL,
 condition_grade ENUM('EXCELLENT','GOOD','FAIR','POOR','CRITICAL') NOT NULL,report_notes TEXT,
 recorded_by_employee_id BIGINT UNSIGNED NOT NULL,
 FOREIGN KEY(loan_id,artifact_id) REFERENCES loan_object(loan_id,artifact_id) ON DELETE RESTRICT,
 FOREIGN KEY(recorded_by_employee_id) REFERENCES employee(employee_id) ON DELETE RESTRICT,
 INDEX ix_report_custody_date(loan_id,artifact_id,report_date)
) ENGINE=InnoDB;
CREATE TABLE placement(
 placement_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,loan_id BIGINT UNSIGNED NOT NULL,artifact_id BIGINT UNSIGNED NOT NULL,
 exhibition_id BIGINT UNSIGNED NOT NULL,slot_no SMALLINT UNSIGNED NOT NULL,
 placed_from DATETIME NOT NULL,placed_to DATETIME,
 CHECK(placed_to IS NULL OR placed_to>=placed_from),
 FOREIGN KEY(loan_id,artifact_id) REFERENCES loan_object(loan_id,artifact_id) ON DELETE RESTRICT,
 FOREIGN KEY(exhibition_id,slot_no) REFERENCES display_slot(exhibition_id,slot_no) ON DELETE RESTRICT,
 INDEX ix_placement_slot_time(exhibition_id,slot_no,placed_from,placed_to)
) ENGINE=InnoDB;
CREATE TABLE artifact_owner(
 artifact_id BIGINT UNSIGNED NOT NULL,owner_party_id BIGINT UNSIGNED NOT NULL,valid_from DATE NOT NULL,
 valid_to DATE,share_percent DECIMAL(5,2) NOT NULL,
 PRIMARY KEY(artifact_id,owner_party_id,valid_from),
 CHECK(share_percent>0 AND share_percent<=100),CHECK(valid_to IS NULL OR valid_to>=valid_from),
 FOREIGN KEY(artifact_id) REFERENCES artifact(artifact_id) ON DELETE RESTRICT,
 FOREIGN KEY(owner_party_id) REFERENCES party(party_id) ON DELETE RESTRICT,
 INDEX ix_owner_party(owner_party_id,artifact_id),INDEX ix_owner_current(artifact_id,valid_to)
) ENGINE=InnoDB;
CREATE VIEW current_artifact_owners AS
 SELECT artifact_id,owner_party_id,share_percent,valid_from FROM artifact_owner WHERE valid_to IS NULL;
CREATE VIEW active_custody AS
 SELECT x.loan_id,x.artifact_id,l.lender_id,x.received_at,x.due_date
 FROM loan_object x JOIN loan l ON l.loan_id=x.loan_id WHERE x.returned_at IS NULL;

-- Cross-row rules need transactional procedures/triggers/application validation:
-- ownership shares total 100 per artifact; owner intervals do not overlap;
-- slot capacity/time ranges do not conflict; a finalised loan has >=1 line.
