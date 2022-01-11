/*******************************************************************************************************
Name: Epi207_Assignment1PartA.sas
Date: 01/10/22
Created by: Yang Cheng Hu
Purpose: This code is used to answer questions on Part A of the Assignment 1 for the EPI 207 class,
		 which focused on exploring the provided data (source: https://journals.plos.org/plosone/article
		 ?id=10.1371/journal.pone.0248856) and basic GitHub functionality.
*******************************************************************************************************/

/* Import the original Excel file and convert it to a SAS file. */
PROC IMPORT datafile="\\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 1\Homework\journal.pone.0248856.s001.xlsx" 
	out=Kim dbms=xlsx;
RUN;
libname desk "\\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 1\Homework";
DATA desk.Kim; set Kim;

/* Question 7: PROC CONTENTS. */
PROC CONTENTS data = desk.Kim; 
RUN;

/* Question 11: create another dataset that only contain variables displayed in Table 1 of the article. */
Option fmtsearch=(desk);
PROC FORMAT lib = desk;
	value Gender		  1  = "Male"
						  2  = "Female"
						  .  = "Missing";
	value Question		  1	 = "Yes"
						  0	 = "No"
						  .  = "Missing";
	value Obese_st		  1  = "Underweight(BMI<18.5kg/m^2)"
						  2	 = "Normal (BMI 18.5–22.9kg/m^2)"
						  3  = "Overweight(BMI 23–24.9kg/m^2)"
						  4  = "Obesity(BMI<=25kg/m^2)"
						  .  = "Missing";
RUN;

DATA desk.Kim_table_1; set desk.Kim;
/* Since the variable "HOMA-IR" and "obese status" in Table 1 was not found in the dataset, we calculate it using the definition given in the article.*/
	length HOMA_IR 6. Ob_stat 6.;
		HOMA_IR = (glu*insulin)/405;

	if bexam_BMI <= 25.0 then Ob_stat = 4;
		else if 23.0 <= bexam_BMI < 25.0 then Ob_stat = 3;
		else if 18.5 <= bexam_BMI < 23.0 then Ob_stat = 2;
		else if bexam_BMI < 18.5 then Ob_stat = 1;
		else Ob_stat = .;

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
