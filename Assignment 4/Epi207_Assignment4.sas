/*******************************************************************************************************
Name: Epi207_Assignment4.sas
Date: 03/16/22
Created by: Yang Cheng Hu
Purpose: This code is the revised version of the SAS file, "Epi207_Assignment2_PartC_FINAL.sas". The main
		 revisions in this file includes additional notes and more detailed descriptions, a summary text
		 at the start of the code, and minor format changes to the code. The revisions are based on the 
		 feedback provided by Assignment 3.
Analysis:The current code aims to investigate the following hypothses: 1. What is the association between 
		 appendicular skeletal muscle mass (ASM) per body weight and hypertension (HT) among Korean adults 
		 aged 25 to 60 years? 2. Is there a correlation between appendicular skeletal muscle mass per body 
		 weight and mean arterial blood pressure (MAP) among Korean adults aged 25 to 60 years? This project 
		 used dataset collected by Kim et al., which comprised of health checkup records for the South
		 Korean population.
NOTE: Data from the project is available at https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8562854/#sec017
*******************************************************************************************************/

/* Set working directory */
%let workdir = MYPATH;
libname epi207 "&workdir";

/* Load in data */
proc import datafile="&workdir.\pone.0248856.s001" 
			dbms=xlsx 
			out=data 
			replace;
run;

proc contents data=data varnum;
run;

/*Setup data*/
/*Filter age 25-60 years and select needed varibles*/
DATA outdata;
	SET data;
	where 25<=age & age <=60;
	KEEP ID 
		 Sex 
		 Age 
		 HT 
		 DM 
		 DysL_ 
		 bexam_wc 
		 bexam_BMI 
		 ASM_Wt_
		 shx_smoke_yn
		 shx_alcohol_yn
		 mhx_HT_yn
		 bexam_BP_diastolic
		 bexam_BP_systolic;
RUN;

/* Study population n=10759 with no missing*/
PROC CONTENTS data=outdata VARNUM;
RUN;

/*Format data set*/
Option fmtsearch=(epi207);
PROC FORMAT;
	value Sex 	1='Male'
				2='Female';
	value YN	0='No'
				1='Yes';
	value BMIgr low-<18.5 = '0'
				18.5-22.9 = '1'
				23-24.9	  = '2'
				25-high   = '3';
	value BMItx 0 = 'Under weight (BMI <18.5 kg/m^2)'
				1 = 'Normal (BMI 18.5-22.9 kg/m^2)'
				2 = 'Overweight (BMI 23-24.9 kg/m^2)'
				3 = 'Obesity (BMI >=25 kg/m^2)';
RUN;	

/* Create variables for BMI, MAP, and ASM% (per 10%) */
DATA outdata2;
	set outdata;
	BMIgr = put(bexam_BMI, BMIgr.);
	BMIgr2 = input(BMIgr,8.);
	MAP = bexam_BP_diastolic + (1/3 * (bexam_BP_systolic - bexam_BP_diastolic));
	ASM_10 = ASM_Wt_/10;
	drop BMIgr;
RUN;

PROC CONTENTS data=outdata2 VARNUM;
RUN;

/* Put on labels */
DATA outdata_label;
SET outdata2(rename=(BMIgr2=BMIgr));

Label	ID 					= "ID"
		Sex 				= "Sex (1=Male, 2=Female)"
		Age  				= "Age (years)"
		mhx_HT_yn			= "Medical history of hypertension"
		HT  				= "Hypertension (0=No, 1=Yes)"
		DM  				= "Diabetes (0=No, 1=Yes)"
		DysL_  				= "Dyslipidemia (0=No, 1=Yes)"
		bexam_wc  			= "Waist circumference (cm)"
		bexam_BMI  			= "Body mass index (kg/m^2)"
		ASM_Wt_ 			= "Appendicular skeletal muscle mass (%)"
		shx_smoke_yn		= "History of smoking (0=No, 1=Yes)"
		shx_alcohol_yn 		= "History of alcohol intake (0=No, 1=Yes)"
		BMIgr				= "Obesity status according to BMI"
		bexam_BP_diastolic 	= "Diastolic blood pressure (mmHg)"
		bexam_BP_systolic	= "Systolic blood pressure (mmHg)"
		MAP					= "Mean arterial blood pressure (mmHg)"
		ASM_10				= "Re-scaled ASM%, 1 unit = 10% ASM"
;
FORMAT 	Sex 				Sex.;
FORMAT	mhx_HT_yn--DysL_  	YN.;
FORMAT	shx_smoke_yn		YN.;
FORMAT	shx_alcohol_yn		YN.;
FORMAT	BMIgr				Bmitx.;
RUN;

PROC CONTENTS data=outdata_label VARNUM out=outdatalabdes;
RUN;

/*Descriptive statistics for codebook and Table 1*/
PROC FREQ data = outdata_label;
	TABLES 	Sex 
			mhx_HT_yn
			HT 
			DM 
			DysL_ 
			shx_smoke_yn
			shx_alcohol_yn
			BMIgr;
RUN;

PROC MEANS data = outdata_label n mean std median min max nmiss;
	var Age
		bexam_wc
		bexam_BMI
		ASM_Wt_
		bexam_BP_diastolic
		bexam_BP_systolic
		MAP
		ASM_10;
RUN;

/* Logistic regressions (ASM% and HT) */
PROC LOGISTIC DATA=outdata_label;
TITLE "HTN: Crude Model";
MODEL HT (EVENT='Yes') = ASM_Wt_; 
RUN;
TITLE;

PROC LOGISTIC DATA=outdata_label;
MODEL HT (EVENT='Yes') = ASM_Wt_ Sex Age; 
TITLE "HTN: Model 1";
RUN;
TITLE;

PROC LOGISTIC DATA=outdata_label;
TITLE "HTN: Model 2";
MODEL HT (EVENT='Yes') = ASM_Wt_ Sex Age shx_smoke_yn shx_alcohol_yn; 
RUN;
TITLE;

/* Linear regressions (ASM% and MAP) and calculate E-values */
PROC REG DATA=outdata_label
  plots =(DiagnosticsPanel ResidualPlot(smooth));
TITLE "MAP: Crude Model";
MODEL MAP = ASM_10/clb; 
RUN;
QUIT;
TITLE;

PROC REG DATA=outdata_label
  plots =(DiagnosticsPanel ResidualPlot(smooth));
TITLE "MAP: Model 1";
MODEL MAP = ASM_10 Sex Age/clb; 
RUN;
QUIT;
TITLE;

PROC REG DATA=outdata_label;
TITLE "MAP: Model 2"
  plots =(DiagnosticsPanel ResidualPlot(smooth));
MODEL MAP = ASM_10 Sex Age shx_smoke_yn shx_alcohol_yn/clb; 
RUN;
QUIT;
TITLE;

/* Sensitivity analysis for MAP linear regression, excluding history of HTN */
ods graphics on;
PROC REG DATA=outdata_label
  plots =(DiagnosticsPanel ResidualPlot(smooth));
TITLE "MAP: Crude Model";
MODEL MAP = ASM_10/clb; 
RUN;
QUIT;
TITLE;

ods graphics on;
PROC REG DATA=outdata_label
  plots =(DiagnosticsPanel ResidualPlot(smooth));
TITLE "MAP: Model 1";
MODEL MAP = ASM_10 Sex Age/clb; 
RUN;
QUIT;
TITLE;

ods graphics on
  plots =(DiagnosticsPanel ResidualPlot(smooth));
PROC REG DATA=outdata_label;
TITLE "MAP: Model 2";
MODEL MAP = ASM_10 Sex Age shx_smoke_yn shx_alcohol_yn/clb; 
RUN;
QUIT;
TITLE;

/* Data visualization (Figure 3) */

proc sgplot data=outdata_label;
title "Scatterplot ASM & MAP by Sex";
  reg x=ASM_Wt_ y=MAP / group=Sex;
run;
title;


