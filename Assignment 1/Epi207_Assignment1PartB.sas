/*******************************************************************************************************
Name: Epi207_Assignment1PartB.sas
Date: 01/17/22
Created by: Yang Cheng Hu
Purpose: This code is used to answer questions on Part B of the Assignment 1 for the EPI 207 class,
		 which focused on generating the data dictionary and codebook for the dataset in Part A. 
		 Note that the variable set here is limited to those presented in Table 1. of the original 
		 article (source: https://journals.lww.com/cancernursingonline/Fulltext/2017/11000/Associat
		 ion_Between_Sarcopenia_and_Metabolic.7.aspx). 
Note: Epi207_Assignment1PartA.sas is required for this code to work.
*******************************************************************************************************/

/************************************************************************/
/*CODE FROM "Epi207_Assignment1PartA.sas". PLEASE RUN BEFORE PROCEEDING.*/
/************************************************************************/
/* Import the original Excel file and convert it to a SAS file. */
PROC IMPORT datafile="\\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 1\Homework\journal.pone.0248856.s001.xlsx" 
	out=Kim dbms=xlsx;
RUN;
libname desk "\\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 1\Homework";
DATA desk.kim; set kim; RUN;

/* Question 7: PROC CONTENTS. */
PROC CONTENTS data = desk.Kim; 
RUN;

/* Question 11: create another dataset that only contain variables displayed in Table 1 of the article. */
Option fmtsearch=(desk);
PROC FORMAT lib = desk;
	value Gender		  1  = "Male"
						  2  = "Female"
						  ;
	value Question		  1	 = "Yes"
						  0	 = "No"
						  ;
	value Obese_st		  1  = "Underweight(BMI<18.5kg/m^2)"
						  2	 = "Normal (BMI 18.5–22.9kg/m^2)"
						  3  = "Overweight(BMI 23–24.9kg/m^2)"
						  4  = "Obesity(BMI<=25kg/m^2)"
						  ;
RUN;

DATA desk.Kim_table_1; set Kim;
/* Since the variable "HOMA-IR" and "obese status" in Table 1 was not found in the dataset, we calculate it using the definition given in the article.*/
	length HOMA_IR 6. Ob_stat 6.;
		HOMA_IR = (glu*insulin)/405;

		Ob_stat = .;
	if bexam_BMI >= 25.0 then Ob_stat = 4;
		else if 23.0 <= bexam_BMI < 25.0 then Ob_stat = 3;
		else if 18.5 <= bexam_BMI < 23.0 then Ob_stat = 2;
		else if 0 <= bexam_BMI < 18.5 then Ob_stat = 1;


/* Also, add in labels for variables based on the description. */
	keep	ID Sex Age bexam_wt bexam_BMI bexam_wc bexam_BP_systolic bexam_BP_diastolic VFA_cm2 ASM_kg ASM_Wt_ chol HDL LDL
			TG glu GOT GPT uric_acid HbA1c insulin HOMA_IR CRP MS HT DM Ob_stat shx_smoke_yn shx_alcohol_yn
	; 
	label	ID					=	"ID number"
			Sex					=	"Gender"
			Age					=	"Age(yr)"
			bexam_wt			=	"Weight(kg)"
			bexam_BMI			=	"Body mass index(BMI,kg/m^2)"
			bexam_wc			=	"Waist circumference(cm)"
			bexam_BP_systolic	=	"Systolic blood pressure(mmHg)"
			bexam_BP_diastolic	=	"Diastolic blood pressure(mmHg)"
			VFA_cm2				=	"Visceral fat area(cm2)"
			ASM_kg				=	"ASM(kg)"
			ASM_Wt_				=	"ASM%"
			chol				=	"Cholesterol(mg/dL)"
			HDL					=	"HDL(mg/dL)"
			LDL					=	"LDL(mg/dL)"
			TG					=	"Triglyceride(mg/dL)"
			glu					=	"Glucose (mg/dL)"
			GOT					=	"AST(IU/L)"
			GPT					=	"ALT(IU/L)"
			uric_acid			=	"Uric acid(mg/dL)"
			HbA1c				=	"HbA1c(%)"
			insulin				=	"Insulin"
			HOMA_IR				=	"HOMA-IR"
			CRP					=	"C-reactive protein(mg/dL)"
			MS					=	"Metabolic syndrome"
			HT					=	"Hypertension"
			DM					=	"Diabetes mellitus"
			Ob_stat				=	"Obese status"
			shx_smoke_yn		=	"Smoking"
			shx_alcohol_yn		=	"Alcohol intake"
	;
	Format	ID 6.0 Sex Gender. Age 14.10 bexam_wt 4.1 bexam_BMI 3.1 bexam_wc 4.0 bexam_BP_systolic bexam_BP_diastolic 3.0 
			VFA_cm2 8.4 ASM_kg 10.5 ASM_Wt_ 14.10 chol HDL LDL TG glu GOT GPT 3.0 uric_acid HbA1c insulin 2.1 HOMA_IR 14.10 
			CRP 5.2 MS HT DM Question. Ob_stat Obese_st. shx_smoke_yn shx_alcohol_yn Question.
	;
RUN;

/************************************************************************/
/*CODE FROM "Epi207_Assignment1PartA.sas". Code is modified from:       */
/* “Creating a data dictionary using Base SAS®” by Tasha Chapman        */
/************************************************************************/

/* Code set for creating the data dictionary. */
DATA Kim_table_1; set Desk.Kim_table_1; 
RUN;

PROC DATASETS library=work;
	modify Kim_table_1;
		xattr set var
		Age (Unit = "Years")
		bexam_wt (Unit = "Pounds")
 		bexam_BMI (Unit = "kg/m^2")
		bexam_wc (Unit = "Centimeters")
		bexam_BP_systolic (Unit = "mmHg")
		bexam_BP_diastolic (Unit = "mmHg")
		VFA_cm2 (Unit = "cm^2")
		ASM_kg  (Unit = "Kilogram")
		chol (Unit = "mg/dL")
		HDL (Unit = "mg/dL")
		LDL (Unit = "mg/dL")
		TG (Unit = "mg/dL")
		glu (Unit = "mg/dL")
		GOT (Unit = "IU/L")
		GPT (Unit = "IU/L")
		uric_acid (Unit = "mg/dL")
		CRP (Unit = "mg/dL")
		; 
RUN;
QUIT;

ods output variables=varlist;
ods output ExtendedAttributesVar=varlist2;
PROC CONTENTS data=Kim_table_1; 
RUN;

PROC SORT data=varlist2; by attributevariable; 
RUN;

PROC TRANSPOSE data=varlist2 out=varlist2B;
	by attributevariable;
	id extendedattribute;
	var attributecharvalue;
RUN;

PROC DATASETS library=work;
	modify varlist2B;
	rename attributevariable = variable;
RUN;
QUIT;

PROC SORT data=varlist2B; by variable; RUN;
PROC SORT data=varlist; by variable; RUN;

DATA datadictionaryA;
	merge varlist (drop= member pos) varlist2B (drop=_NAME_ _Label_);
	by variable;
RUN;

PROC DATASETS library=work;
	modify datadictionaryA;
		label num = '#'
	variable = 'Variable'
	type = 'Type'
	len = 'Length'
	label = 'Label'
	Unit = 'Unit of measurement'
	;
RUN;
QUIT;

ods tagsets.excelxp file="\\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 2\Homework\Epi207_Assignment1_Dictionary.xls" style=statistical;
PROC PRINT data=datadictionaryA noobs label; RUN;
ods tagsets.excelxp close;

/* Code set for creating the codebook. */
ods tagsets.excelxp file="\\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 2\Homework\Epi207_Assignment1_Codebook.xls" style=statistical;
PROC CONTENTS data = Kim_table_1;
PROC MEANS data = Kim_table_1;
RUN;
ods tagsets.excelxp close;
