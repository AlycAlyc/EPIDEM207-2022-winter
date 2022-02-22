
%let workdir = C:\Users\Ken Kitayama\Dropbox\Dropbox\UCLA FSPH\2021-2022\Winter 21-22\EPI 209 - Reproducibility in Epidemiologic Research\Assignments\Assignment 2;
libname epi207 "&workdir";

/* Load data */
proc import datafile="C:\Users\Ken Kitayama\Dropbox\Dropbox\UCLA FSPH\2021-2022\Winter 21-22\EPI 209 - Reproducibility in Epidemiologic Research\Assignments\Assignment 2\Data\pone.0248856.s001" dbms=xlsx out=data replace;
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

/*n=10759*/
PROC CONTENTS data=outdata VARNUM;
RUN;

/*Format data set*/

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

PROC LOGISTIC DATA=outdata_label;
TITLE "HTN: Model 3";
MODEL HT (EVENT='Yes') = ASM_Wt_ Sex Age shx_smoke_yn shx_alcohol_yn bexam_bmi bexam_wc; 
RUN;
TITLE;

PROC LOGISTIC DATA=outdata_label;
TITLE "HTN: Model 4";
MODEL HT (EVENT='Yes') = ASM_Wt_ Sex Age shx_smoke_yn shx_alcohol_yn bexam_bmi bexam_wc DysL_ dm; 
ods output ParameterEstimates=OutEst
OddsRatios=OutOR;
RUN;
TITLE;

/* Linear regressions (ASM% and MAP) */
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


