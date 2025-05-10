-- @Author: Dr. Akshaya Tharankini A

-- DATA ANALYSIS USING MySQL ON  MIMIC-III Clinical Database 
	-- This analysis is performed ON  the MIMIC-III database, which contains de-identified health data.
	-- The dataset is intended strictly for academic AND research purposes.

-- 1. Which diagnoses have seen more than on e patient come back? 
	-- (we consider diagnoses in which at least two patients have come back)
SELECT a1.DIAGNOSIS, COUNT(DISTINCT(a1.SUBJECT_ID)) AS UNIQ_SUBJ_COUNT, COUNT(a1.HADM_ID) AS UNIQ_VISIT_COUNT
FROM ADMISSIONS a1
WHERE SUBJECT_ID = (
	SELECT a2.SUBJECT_ID
	FROM ADMISSIONS a2
    	WHERE a1.DIAGNOSIS = a2.DIAGNOSIS
		AND a1.SUBJECT_ID = a2.SUBJECT_ID
	GROUP BY a2.DIAGNOSIS, a2.SUBJECT_ID
    	HAVING COUNT(HADM_ID) >= 2
)
AND a1.DIAGNOSIS <> 'NEWBORN'
GROUP BY a1.DIAGNOSIS
HAVING UNIQ_SUBJ_COUNT >= 2
ORDER BY COUNT(DISTINCT(a1.SUBJECT_ID)) DESC;

-- 2. The Number of patients by gender with Heart Failure Conditions?
SELECT gender,DIAGNOSIS, COUNT(*) AS 'Count of Patients'
FROM patients INNER JOIN admissions USING(SUBJECT_ID)
WHERE DIAGNOSIS  like  '%Heart Failure%'
GROUP BY gender;

-- 3. Retrieves count of Heart Failure Cases in sort by month and year
SELECT
	YEAR(adm.ADMITTIME) AS ADMIT_YEAR,
	MONTH(adm.ADMITTIME) AS ADMIT_MONTH,
    	CONCAT(MONTH(adm.ADMITTIME),'-',YEAR(adm.ADMITTIME)) AS DT,
    	COUNT(*) AS ADMIT_COUNT
FROM
ADMISSIONS adm, ICUSTAYS icu
WHERE
adm.SUBJECT_ID = icu.SUBJECT_ID
    AND adm.HADM_ID = icu.HADM_ID
	AND adm.DIAGNOSIS LIKE '%HEART%FAILURE%'
GROUP BY ADMIT_YEAR ASC, ADMIT_MONTH ASC, DT ASC;

-- 4. The highest no.of subjects identified for diagnosis for each ethnicity      
SELECT S2.ETHNICITY,S2.DIAGNOSIS,S2.S_COUNT FROM
(SELECT ETHNICITY,MAX(S_COUNT) AS MAXCOUNT FROM
      (SELECT ETHNICITY,DIAGNOSIS,COUNT(*) AS S_COUNT
         FROM ADMISSIONS
     GROUP BY  ETHNICITY,DIAGNOSIS 
       HAVING DIAGNOSIS<>'NEWBORN')S1
 GROUP BY ETHNICITY
)M
INNER JOIN
      (SELECT ETHNICITY,DIAGNOSIS,COUNT(*) AS S_COUNT
         FROM ADMISSIONS
     GROUP BY ETHNICITY,DIAGNOSIS 
       HAVING DIAGNOSIS<>'NEWBORN')S2
On (S2.ETHNICITY=M.ETHNICITY AND S2.S_COUNT=M.MAXCOUNT)
ORDER BY 1,2;

-- 5.A# Retrieves all observations made on  patient who all diagnosed with heart failure
             SELECT I.SUBJECT_ID AS 'SUBJECT ID', I.HADM_ID AS 'H.ADM ID', I.ICUSTAY_ID AS          
                      'ICUSTAY ID',DI.ICD9_CODE AS 'ICD9 CODE',DI.SEQ_NUM AS 'ORDER OF   
                      OBS',DID.LONG_TITLE AS 'OBSERVATION',GENDER AS 'GENDER',
                      AGE_GROUP 
             FROM ICUSTAYS I INNER JOIN PATIENTS P ON  I.SUBJECT_ID=P.SUBJECT_ID
              INNER JOIN AAA_AGE AG ON  I.SUBJECT_ID=AG.SUBJECT_ID
              INNER JOIN DIAGNOSES_ICD DI ON  
                   DI.SUBJECT_ID=I.SUBJECT_ID AND DI.HADM_ID=I.HADM_ID
             INNER JOIN D_ICD_DIAGNOSES DID ON  DID.ICD9_CODE=DI.ICD9_CODE 
             INNER JOIN ADMISSIONS A ON  DI.SUBJECT_ID=A.SUBJECT_ID AND     
                  DI.HADM_ID=A.HADM_ID AND A.DIAGNOSIS LIKE '%HEART%FAILURE%';

                    
-- 5. B# Top 15 frequent observations for heart failure patients in ICU with %male and %female                    
(SELECT ICD9_CODE AS 'INTL.DISEasE CODE',LONG_TITLE AS 'NAME OF THE OBSERVATION',CNT AS 'NO.OF SUBJECTS OBSERVED',MALECNT,FEMALECNT,ROUND((MALECNT/CNT*100),2) AS '%MALE',ROUND((FEMALECNT/CNT*100),2) AS '%FEMALE' 
        FROM 
        (SELECT DID.ICD9_CODE,DID.LONG_TITLE,COUNT(*) AS CNT,
                 sum(case
		    When GENDER='M'
			  THEN 1 ELSE 0
		  end) AS MALECNT,
	     sum(case
		    When GENDER='F'
			  THEN 1 ELSE 0
		   end) AS FEMALECNT
         FROM ICUSTAYS I 
          INNER JOIN DIAGNOSES_ICD DI ON  DI.SUBJECT_ID=I.SUBJECT_ID AND 
                                                          DI.HADM_ID=I.HADM_ID
          INNER JOIN PATIENTS P ON  DI.SUBJECT_ID=P.SUBJECT_ID
          INNER JOIN D_ICD_DIAGNOSES DID ON  DID.ICD9_CODE=DI.ICD9_CODE 
          INNER JOIN ADMISSIONS A ON  DI.SUBJECT_ID=A.SUBJECT_ID AND   
                                                DI.HADM_ID=A.HADM_ID 
                   AND A.DIAGNOSIS LIKE '%HEART%FAILURE%'
         GROUP BY DID.LONG_TITLE)ICUOBS
          ORDER BY CNT DESC
                        limit 15);           

-- 6.A# Retrieves all procedures made on  patient who all diagnosed with heart failure                    
SELECT I.SUBJECT_ID AS 'SUBJECT ID', I.HADM_ID AS 'H.ADM ID', I.ICUSTAY_ID AS  
           'ICUSTAY ID',PI.ICD9_CODE AS 'ICD9 CODE',PI.SEQ_NUM AS 'ORDER OF 
           PROCEDURE',DIP.LONG_TITLE AS  'PROCEDURE TITLE',GENDER AS 'GENDER',
          AGE_GROUP
  FROM ICUSTAYS I 
    INNER JOIN PATIENTS P ON  I.SUBJECT_ID=P.SUBJECT_ID
    INNER JOIN AAA_AGE AG ON  I.SUBJECT_ID=AG.SUBJECT_ID
    INNER JOIN PROCEDURES_ICD PI ON  PI.SUBJECT_ID=I.SUBJECT_ID AND  
                                                      PI.HADM_ID=I.HADM_ID
    INNER JOIN D_ICD_PROCEDURES DIP ON  DIP.ICD9_CODE=PI.ICD9_CODE 
   INNER JOIN ADMISSIONS A ON  PI.SUBJECT_ID=A.SUBJECT_ID AND PI.HADM_ID=A.HADM_ID 
  AND A.DIAGNOSIS LIKE '%HEART%FAILURE%';
    
-- 6.B# Top 15 frequent procedures for heart failure patients in ICU with %male and %female                    
(SELECT ICD9_CODE AS 'INTL.PROCEDURE CODE',LONG_TITLE AS 'NAME OF THE       
            PROCEDURE',CNT AS 'NO.OF SUBJECTS', 
            MALECNT,FEMALECNT,ROUND((MALECNT/CNT*100),2) AS '%MALE', 
            ROUND((FEMALECNT/CNT*100),2) AS '%FEMALE' 
        FROM 
        (SELECT DIP.ICD9_CODE,DID.LONG_TITLE,COUNT(*) AS CNT,
                 sum(case
		    When GENDER='M'
			  THEN 1 ELSE 0
		  end) AS MALECNT,
	     sum(case
		    When GENDER='F'
			  THEN 1 ELSE 0
		   end) AS FEMALECNT
         FROM ICUSTAYS I 
           INNER JOIN PROCEDURES_ICD PI ON  PI.SUBJECT_ID=I.SUBJECT_ID AND 
                                                          PI.HADM_ID=I.HADM_ID
          INNER JOIN PATIENTS P ON  PI.SUBJECT_ID=P.SUBJECT_ID
         INNER JOIN D_ICD_PROCEDURES DIP ON  DIP.ICD9_CODE=PI.ICD9_CODE 
         INNER JOIN ADMISSIONS A ON  PI.SUBJECT_ID=A.SUBJECT_ID AND   
                                                PI.HADM_ID=A.HADM_ID 
                   AND A.DIAGNOSIS LIKE '%HEART%FAILURE%'
         GROUP BY DID.LONG_TITLE)ICUPROC
          ORDER BY CNT DESC
                        limit 15);         

-- 7.A# No.of Heart failure Patients who died in ICU in each year
 SELECT DATE_FORMAT(DOD, '%Y') AS 'YEAR', CNT AS 'NO.OF DEATHS'
    FROM 
(SELECT  I.SUBJECT_ID,I.HADM_ID,I.ICUSTAY_ID,GENDER,FIRST_CAREUNIT,INTIME,OUTTIME,DOD,COUNT(*) AS CNT
    FROM ICUSTAYS I  INNER JOIN PATIENTS P ON  I.SUBJECT_ID=P.SUBJECT_ID
                     INNER JOIN ADMISSIONS A ON  I.SUBJECT_ID=A.SUBJECT_ID AND I.HADM_ID=A.HADM_ID 
                    AND A.DIAGNOSIS LIKE '%HEART%FAILURE%'
    WHERE DATE_FORMAT(OUTTIME, '%Y-%m-%d') = DATE_FORMAT(DOD, '%Y-%m-%d')
    GROUP BY  DATE_FORMAT(DOD,  '%Y'))ICUDEATH
     ORDER BY YEAR;


-- 7B# Mortality rate for patients in ICU, male or female
SELECT CNT AS 'NO. OF HEART FAILURE PATIENTS DIED WHILE IN ICU',MALECNT AS  
           'MALE',FEMALECNT AS 'FEMALE',ROUND((MALECNT/CNT*100),2) AS 
           '%MALE',ROUND((FEMALECNT/CNT*100),2) AS '%FEMALE'
 FROM
        (SELECT COUNT(*) AS CNT,
                 sum(case
		    When GENDER='M'
			  THEN 1 ELSE 0
		  end) AS MALECNT,
	     sum(case
		    When GENDER='F'
			  THEN 1 ELSE 0
		   end) AS FEMALECNT
         FROM ICUSTAYS I 
                  INNER JOIN PATIENTS P ON  I.SUBJECT_ID=P.SUBJECT_ID
                 INNER JOIN ADMISSIONS A ON  I.SUBJECT_ID=A.SUBJECT_ID AND 
                                                       I.HADM_ID=A.HADM_ID 
              AND A.DIAGNOSIS LIKE '%HEART%FAILURE%'
          WHERE DATE_FORMAT(OUTTIME, '%Y-%m-%d') = DATE_FORMAT(DOD,   
                     '%Y-%m-%d')         
            )ICUDEATH;  
  
-- 8. To check if there are any neonates(<1 year old) with heart failure in ICU
SELECT I.SUBJECT_ID AS  'SUBJECT ID', I.HADM_ID AS 'H.ADM ID', I.ICUSTAY_ID AS 
          'ICUSTAY ID',P.GENDER AS 'GENDER',AGE_GROUP
  FROM ICUSTAYS I  INNER JOIN PATIENTS P ON  I.SUBJECT_ID=P.SUBJECT_ID
                     INNER JOIN AAA_AGE AG ON  I.SUBJECT_ID=AG.SUBJECT_ID
                     INNER JOIN ADMISSIONS A ON  I.SUBJECT_ID=A.SUBJECT_ID AND   
                          I.HADM_ID=A.HADM_ID 
                    AND A.DIAGNOSIS LIKE '%HEART%FAILURE%'
                   AND AGE_GROUP='NEONATE';

-- 9. Retrieves count and Description of caregivers for Congestive Heart Failure ICU patients
SELECT DISTINCT
descRIPTION, COUNT(*) AS COUNT_CG
FROM
	ADMISSIONS adm, ICUSTAYS icu, CHARTEVENTS chtev, CAREGIVERS care
WHERE
     	  adm.SUBJECT_ID = icu.SUBJECT_ID
    AND adm.HADM_ID = icu.HADM_ID
    AND icu.ICUSTAY_ID = chtev.ICUSTAY_ID
    AND chtev.CGID = care.CGID
    AND adm.DIAGNOSIS LIKE '%HEART%FAILURE%'
    AND Description IS NOT NULL
GROUP BY Description
ORDER BY COUNT_CG DESC;

-- 10. Pulling all HADM_ID that were not present in the ICUSTAY table
SELECT *
FROM
	ADMISSIONS adm
    LEFT JOIN
    ICUSTAYS icu
    ON  (adm.HADM_ID = icu.HADM_ID AND adm.SUBJECT_ID = icu.SUBJECT_ID)
WHERE
	icu.ICUSTAY_ID IS NULL
    AND adm.DIAGNOSIS LIKE '%HEART%FAILURE%';

-- 11. - What were the number of returning ICU patients with Heart Failure?
-- query gives a high level of how many unique patients returned at least ON ce AND the total number of visits
SELECT a1.DIAGNOSIS, COUNT(DISTINCT(a1.SUBJECT_ID)) AS UNIQ_SUBJ_COUNT, COUNT(a1.HADM_ID) AS UNIQ_VISIT_COUNT
FROM ADMISSIONS a1
	INNER JOIN (
		SELECT SUBJECT_ID, DIAGNOSIS
		FROM ADMISSIONS
		GROUP BY DIAGNOSIS, SUBJECT_ID
		HAVING COUNT(HADM_ID) >= 2
	) AS a2
WHERE a1.SUBJECT_ID = a2.SUBJECT_ID
	AND a1.DIAGNOSIS = a2.DIAGNOSIS
	AND a1.DIAGNOSIS LIKE '%HEART%FAILURE%'
GROUP BY a1.DIAGNOSIS
HAVING UNIQ_SUBJ_COUNT >= 2
ORDER BY COUNT(DISTINCT(a1.SUBJECT_ID)) DESC;

-- shows how many subjects for each number of times someone came back (distribution)
SELECT SUBJECT_ID, COUNT(HADM_ID) AS UNIQ_VISIT_COUNT
FROM ADMISSIONS
WHERE DIAGNOSIS LIKE '%HEART%FAILURE%'
GROUP BY SUBJECT_ID
HAVING UNIQ_VISIT_COUNT >= 2;

-- 12. - returns the age groups that the subjects are in
CREATE TABLE  AAA_FIRST_ADMISSION_TIME as
	SELECT
	  p.subject_id, p.dob, p.gender, MIN(a.admittime) AS first_admittime,MIN( ROUND( (cast(admittime AS date) - cast(dob AS date)) / 365.242,2) ) AS first_admit_age
	FROM patients p
	INNER JOIN admissions a
	ON p.subject_id = a.subject_id
	GROUP BY p.subject_id, p.dob, p.gender
	ORDER BY p.subject_id;

CREATE TABLE AAA_AGE as
	SELECT
	  subject_id, dob, gender, first_admittime, first_admit_age,
	CASE
-- all ages > 89 in the database were replaced with 300
-- we check using > 100 AS a conservative threshold to ensure we capture all these patients
		  WHEN first_admit_age > 100 THEN '>89'
		  WHEN first_admit_age >= 14 THEN 'adult'
		  WHEN first_admit_age <= 1 THEN 'neonate'
		  ELSE 'middle'
		  END AS age_group
	FROM AAA_FIRST_ADMISSION_TIME;
    
SELECT age_group, gender, COUNT(subject_id) AS NumberOfPatients
FROM AAA_AGE
GROUP BY age_group, gender;

-- 13. - returns the top drugs prescribed for heart failure patients in ICU
-- A. to find all drugs given to each subject
SELECT I.SUBJECT_ID AS 'SUBJECT ID', I.HADM_ID AS 'H.ADM ID', I.ICUSTAY_ID AS 'ICUSTAY ID',P.GENDER AS 'GENDER',AGE_GROUP,DRUG,STARTDATE,ENDDATE
   FROM ICUSTAYS I  INNER JOIN PATIENTS P ON  I.SUBJECT_ID=P.SUBJECT_ID
                                   INNER JOIN AAA_AGE AG ON  I.SUBJECT_ID=AG.SUBJECT_ID
                                   INNER JOIN PRESCRIPTIONS PR ON  PR.SUBJECT_ID=I.SUBJECT_ID AND       
                                                                                     PR.HADM_ID=I.HADM_ID
                                   INNER JOIN ADMISSIONS A ON  PR.SUBJECT_ID=A.SUBJECT_ID AND 
                                                                                  PR.HADM_ID=A.HADM_ID 
                                   AND A.DIAGNOSIS LIKE '%HEART%FAILURE%';
                    
-- B. Top 15 drugs given to heart failure patients in ICU                    
    (SELECT DRUG AS 'DRUG NAME',CNT AS 'NO.OF SUBJECTS PRESCRIBED'
                 FROM 
                 (SELECT DRUG,COUNT(*) AS CNT
                     FROM ICUSTAYS I 
                                      INNER JOIN PATIENTS P ON  I.SUBJECT_ID=P.SUBJECT_ID
                                      INNER JOIN PRESCRIPTIONS PR ON  PR.SUBJECT_ID=I.SUBJECT_ID AND  
                                                                                        PR.HADM_ID=I.HADM_ID
                                      INNER JOIN ADMISSIONS A ON  I.SUBJECT_ID=A.SUBJECT_ID AND 
                                                                               I.HADM_ID=A.HADM_ID 
                                      AND A.DIAGNOSIS LIKE '%HEART%FAILURE%'
                    GROUP BY DRUG)ICUDRUG
          ORDER BY CNT DESC
          LIMIT 15);  

-- 14.1 What is the gender distribution for patients with Heart Failure? 
SELECT DISTINCT(DIAGNOSIS),gender, COUNT(*) AS 'COUNT of Patients'
FROM patients  INNER JOIN admissions USING(SUBJECT_ID)
WHERE diagnosis like '%Heart Failure%'
GROUP BY gender; 

-- 14.2 Total count of patients with Congestive Heart Failure by gender?
SELECT gender, DIAGNOSIS, COUNT(*) AS 'COUNT of Patients'
FROM patients  INNER JOIN admissions USING(SUBJECT_ID)
WHERE DIAGNOSIS = 'Congestive Heart Failure'
GROUP BY gender;

-- 14. 3 Obtain the number of number of days spent at the hospital (Admissions AND ICU) and sort it out by age group? 
 -- ON  average, males were more likely to be admitted to the hospital for  longer periods than females. 
 SELECT SUBJECT_ID, diagnosis, age_group, gender, datediff( DISCHTIME,ADMITTIME) AS 'Duration_of_Stay', datediff(OUTTIME,INTIME) AS Duration_in_ICU
 FROM aaa_age 
  INNER JOIN admissions USING(SUBJECT_ID) 
  INNER JOIN icustays USING(SUBJECT_ID)
WHERE diagnosis = 'Congestive Heart Failure' 
ORDER BY Duration_in_ICU DESC;

-- Ref 14.4 What is the ethnicity distribution for ICU patients with Heart Failure?
SELECT COUNT(ETHNICITY),Ethnicity, Diagnosis, Description, datediff(DISCHTIME,ADMITTIME) AS Duration_of_Stay, datediff(OUTTIME,INTIME) AS Duration_in_ICU
FROM admissions 
INNER JOIN icustays USING(Subject_id)
INNER JOIN drgcodes USING(Subject_id)
WHERE diagnosis = 'Congestive Heart Failure'
GROUP BY ethnicity
ORDER BY ethnicity;

#-14.5 General overview of  ICD Diagnosis, ICD_Procedures and Description of illness of patients admitted into ICU. 
 SELECT DC.SUBJECT_ID,A.HADM_ID, D.ICD9_CODE, D.short_title AS ICD_Diagnosis, P.short_title AS ICD_Procedure, Diagnosis, Description,Insurance,
 datediff( DISCHTIME,ADMITTIME) AS Duration_of_Admission, datediff(OUTTIME,INTIME) AS Duration_in_ICU, COUNT(INSURANCE)
 FROM d_icd_diagnoses D
  INNER JOIN d_icd_procedures P ON  D.ICD9_CODE = P.ICD9_CODE  
  INNER JOIN drgcodes DC ON  P.ICD9_CODE = DC.DRG_CODE  
  INNER JOIN admissions A ON  DC.HADM_ID = A.HADM_ID 
  INNER JOIN icustays IC ON  A.HADM_ID = IC.HADM_ID
 WHERE DIAGNOSIS = 'Congestive Heart Failure' AND  datediff(OUTTIME,INTIME) <> 0 
GROUP BY Description
ORDER BY datediff( DISCHTIME,ADMITTIME) DESC;

#-14.6 Description of ICD Diagnosis, ICD_Procedures, drugs prescription for diagnoses of patients admitted into ICU. 
 SELECT DC.SUBJECT_ID,A.HADM_ID, D.ICD9_CODE, D.short_title AS ICD_Diagnosis, P.short_title AS ICD_Procedure, Diagnosis, Description,Insurance,
 datediff(OUTTIME,INTIME) AS Duration_in_ICU, COUNT(INSURANCE)
 FROM d_icd_diagnoses D
  INNER JOIN d_icd_procedures P ON  D.ICD9_CODE = P.ICD9_CODE  
  INNER JOIN drgcodes DC ON  P.ICD9_CODE = DC.DRG_CODE  
  INNER JOIN admissions A ON  DC.HADM_ID = A.HADM_ID 
  INNER JOIN icustays IC ON  A.HADM_ID = IC.HADM_ID
 WHERE DIAGNOSIS = 'Congestive Heart Failure' AND  datediff(OUTTIME,INTIME) >= 1
GROUP BY Description
ORDER BY Duration_in_ICU DESC;

