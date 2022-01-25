/*******************************************************************************************************
Name: Epi207_Assignment1PartC.sas
Date: 01/25/22
Created by: Yang Cheng Hu
Purpose: This code is used to answer questions on Part C of the Assignment 1 for the EPI 207 class,
		 which focused on preproducing all tables (and possibly figures) shown in the original 
		 article (source: https://journals.lww.com/cancernursingonline/Fulltext/2017/11000/Associat
		 ion_Between_Sarcopenia_and_Metabolic.7.aspx). Table 1 will be generated by using the Table 1
		 macro developed by UCSF CTSI Consultation Services.
*******************************************************************************************************/

/*** Question 3. ***/
libname desk "\\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 1\Homework";
/*** Table 1 ***/
/* The following code are modified from the Table 1 macro sample file. */
options nodate nocenter ls = 147 ps = 47 orientation = landscape;

/** change this to location where you saved the .sas files**/
%let MacroDir=\\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 3\Homework\Table_1_Macro\Table1;
%let results=\\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 3\Homework;

filename tab1  "&MacroDir./Table1.sas";
%include tab1;

/***********************/
/****UTILITY SASJOBS****/
/***********************/
filename tab1prt  "&MacroDir./Table1Print.sas";
%include tab1prt;

filename npar1way  "&MacroDir./Npar1way.sas";
%include npar1way;

filename CheckVar  "&MacroDir./CheckVar.sas";
%include CheckVar;

filename Uni  "&MacroDir./Univariate.sas";
%include Uni;

filename Varlist  "&MacroDir./Varlist.sas";
%include Varlist;

filename Words  "&MacroDir./Words.sas";
%include Words;

filename Append  "&MacroDir./Append.sas";
%include Append;

/** specify folder in which to store results***/

%let results=\\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 3\Homework;

/* Specify the data format */
Option fmtsearch=(desk);
PROC FORMAT lib = desk;
	value Gender		  1  = "Male"
						  2  = "Female"
						  ;
	value Question		  1	 = "Yes"
						  0	 = "No"
						  ;
	value Obese_st		  1  = "Underweight(BMI<18.5kg/m^2)"
						  2	 = "Normal (BMI 18.5�22.9kg/m^2)"
						  3  = "Overweight(BMI 23�24.9kg/m^2)"
						  4  = "Obesity(BMI>=25kg/m^2)"
						  ;
	value Quartile		  0  = "Q1"
						  1  = "Q2"
						  2  = "Q3"
						  3  = "Q4"
						  ;
	value Age_Grp		  1  = "20-29"
						  2  = "30-39"
						  3  = "40-49"
						  4  = "50-59"
						  5  = "60-69"
						  6  = "70-"
						  ;
RUN;

/* Create a new variable nameed "Quartile", which represent the quartile groups of ASW, since it appeared in Table 1. */
PROC RANK data=desk.Kim_table_1 out=desk.Kim_table_1_ASW_Q groups=4;
    var ASM_Wt_;
    ranks Quartile;
RUN;

DATA desk.Kim_table_1_ASW_Q; set desk.Kim_table_1_ASW_Q;
	label Quartile	=	"ASM% quartiles";
	format Quartile Quartile.;
RUN;


/* Call the Table 1 Macro (DO NOT REPLICATE THE P-VALUE.) */
%Table1(DSName=desk.Kim_table_1_ASW_Q,
        GroupVar=Quartile,
        NumVars=Age bexam_wt bexam_BMI bexam_wc bexam_BP_systolic bexam_BP_diastolic VFA_cm2 ASM_kg ASM_Wt_ chol HDL HDL
				TG glu GOT GPT uric_acid HbA1c insulin HOMA_IR CRP,
        FreqVars=Sex MS HT DM Ob_stat shx_smoke_yn shx_alcohol_yn,
        Mean=Y,
        Median=N,
        Total=RC,
        P=N,
        Fisher=,
        KW=,
        FreqCell=N(RP),
        Missing=Y,
        Print=N,
        Label=L,
        Out=Kim_Table1,
        Out1way=)

*options mprint  symbolgen mlogic;
run;

ods pdf file="&results.\Kim_Table1_output.pdf";
title 'Table 1. Clinical characteristics according to ASM% quartiles';
%Table1Print(DSname=Kim_Table1,Space=Y)
ods pdf close;
run;

/*** Figure 3 ***/
/* First, calculate the proportion of MS for each ASM quartile group. */
/* Save the result as work.temp */
PROC SUMMARY data=desk.Kim_table_1_ASW_Q nway;
	class Quartile;
	var MS;
	output out=temp mean= uclm=uclm;
RUN;

/* Add the significant signs on bar Q2-Q4. */
DATA dlabel; set temp;
	if (Quartile ne 0) then dlabel = "*";
	else dlabel=" ";
	label MS	= "Metabolic syndrome (%)";
	format MS 4.2;
RUN;

/* Generate the bar chart. */
ods pdf file="&results.\Kim_Fig3_output.pdf";
title 'Fig 3. Prevalence of metabolic syndrome according to ASM% (appendicular skeletal muscle mass x 100/Weight) quartiles.';
PROC SGPLOT data=dlabel;
	vbarparm category=Quartile response=MS / datalabel=dlabel /*groupdisplay=cluster*/ barwidth = 0.2;
RUN;
ods pdf close;

/*** Table 2 ***/
/* Pull variable "Sarco_ASM_Wt%", the variable representing sarcopenia, from the original data for modeling. */
/* Pull variable "Obestity" and "DysL_" since they were included in some of the models. */
PROC SQL;
	create table Kim_table_2 as
	select a.*, b. Sarco_ASM_Wt_, b. Obesity, b. DysL_
	from desk.Kim_table_1 a, desk.Kim b
	where a.ID = b.ID;
QUIT;

/* Run all models listed in Table 2 */
/* Create a macro with the following inputs: ModelNames = The name of the model outputs
											 VariablesToAdjust = a list of variables for adjustment
											 ClassVar = indicating which variable(s) from the VariablesToAdjust input is(are) categorical*/
%MACRO Kim_models(ModelNames=,VariablesToAdjust=,ClassVar=);
PROC LOGISTIC data = Kim_table_2;
	class Sarco_ASM_Wt_ (param = ref ref = "0") &ClassVar;
	model MS (event = "Yes") = Sarco_ASM_Wt_ &VariablesToAdjust;
	ods output OddsRatios=&ModelNames._OR;
	ods output ParameterEstimates=&ModelNames._Pe (where=(Variable = "Sarco_ASM_Wt_"));
RUN;
DATA &ModelNames._OR; set &ModelNames._OR (obs = 1); RUN;
PROC SQL;
	create table &ModelNames as
	select a.*, b. ProbChiSq
	from &ModelNames._OR a, &ModelNames._Pe b;
QUIT;
%MEND Kim_models;

%Kim_models(ModelNames=Crude,VariablesToAdjust=,ClassVar=);
%Kim_models(ModelNames=Model1,VariablesToAdjust=Age Sex,ClassVar=Sex);
%Kim_models(ModelNames=Model2,VariablesToAdjust=Age Sex Obesity,ClassVar=Sex Obesity);
%Kim_models(ModelNames=Model3,VariablesToAdjust=Age Sex Obesity HT DM DysL_,ClassVar=Sex Obesity HT DM DysL_);
%Kim_models(ModelNames=Model4,VariablesToAdjust=Age Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn,ClassVar=Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn);
%Kim_models(ModelNames=Model5,VariablesToAdjust=Age Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn CRP,ClassVar=Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn);

/* Combine all results */
title "Table 2. Association between metabolic syndrome and sarcopenia.";
DATA desk.Table2; 
	retain model OddsRatioEst LowerCL UpperCL ProbChiSq;
	set Crude Model1 Model2 Model3 Model4 Model5 indsname=mod;
	drop Effect;
	model = tranwrd(mod,"WORK.","");
RUN;

/*** Table 3 ***/
/* Pull in variable "Lean", the variable represents underweight. */
PROC SQL;
	create table Kim_table_3 as
	select a.*, b.Lean, b.VFA_
	from Kim_table_2 a, desk.Kim b
	where a.ID = b.ID;
QUIT;

%MACRO Kim_strat(Stratify=);
PROC LOGISTIC data = Kim_table_3 (where = (&Stratify = 1));
	class Sarco_ASM_Wt_ (param = ref ref = "0");
	model MS (event = "Yes") = Sarco_ASM_Wt_;
	ods output OddsRatios=&Stratify._OR1(where=(Effect = "Sarco_ASM_Wt_ 1 vs 0"));
	ods output ParameterEstimates=&Stratify._Pe1 (where=(Variable = "Sarco_ASM_Wt_"));
RUN;
PROC SQL;
	create table &Stratify._temp1 as
	select a.*, b. ProbChiSq
	from &Stratify._OR1 a, &Stratify._Pe1 b;
QUIT;

PROC LOGISTIC data = Kim_table_3 (where = (&Stratify = 0));
	class Sarco_ASM_Wt_ (param = ref ref = "0");
	model MS (event = "Yes") = Sarco_ASM_Wt_;
	ods output OddsRatios=&Stratify._OR0(where=(Effect = "Sarco_ASM_Wt_ 1 vs 0"));
	ods output ParameterEstimates=&Stratify._Pe0 (where=(Variable = "Sarco_ASM_Wt_"));
RUN;
PROC SQL;
	create table &Stratify._temp0 as
	select a.*, b. ProbChiSq
	from &Stratify._OR0 a, &Stratify._Pe0 b;
QUIT;

DATA &Stratify; 
	retain stratum OddsRatioEst LowerCL UpperCL ProbChiSq; 
	set &Stratify._temp1 &Stratify._temp0 indsname=strat;
	if strat = upcase("WORK.&Stratify._TEMP1") then stratum = "&Stratify. Yes";
	else if strat = upcase("WORK.&Stratify._TEMP0") then stratum = "&Stratify. No";
	drop Effect;
RUN;
%MEND Kim_strat;

%Kim_strat(Stratify=VFA_);
%Kim_strat(Stratify=Obesity);
/* This part is different (in the Lean =1 part). */
%Kim_strat(Stratify=Lean);
%Kim_strat(Stratify=Sex);

/* Change the stratum values for Sex before merging. */
DATA Sex; set Sex;
	if stratum = "Sex Yes" then stratum = "Male";
	else if stratum = "Sex No" then stratum = "Female";
RUN;

/* Combine all results */
title 'Table 3. Stratified association between metabolic syndrome and sarcopenia.';
DATA desk.Table3; 
	retain Variable stratum OddsRatioEst LowerCL UpperCL ProbChiSq;
	length stratum $20;
	set VFA_ Obesity Lean Sex indsname=mod;
	Variable = tranwrd(mod,"WORK.","");
RUN;

/*** Figure 4 ***/
/* Clustered bar chart of % of MS for different sarcopenia groups, grouped by age group. */
/* Create a binned age variable. */
DATA Kim_fig_4; set Kim_table_3;
		age_gp =.;
	if 20 <= Age < 30 then age_gp = 1;
	else if 30<= Age < 40 then age_gp = 2;
	else if 40<= Age < 50 then age_gp = 3;
	else if 50<= Age < 60 then age_gp = 4;
	else if 60<= Age < 70 then age_gp = 5;
	else if 70<= Age then age_gp = 6;
RUN;

/* Calculate the proportion of MS for each sarcopenia group by age. */
/* Save the result as work.temp */
PROC SUMMARY data = Kim_fig_4 nway;
	class age_gp Sarco_ASM_Wt_;
	var MS;
	output out=temp2 mean= uclm=uclm;
RUN;

/* Add the significant signs on bar with Sarco_ASM_Wt_ = 1 . */
DATA dlabel2; set temp2;
	if (Sarco_ASM_Wt_ = 1) then dlabel = "*";
	else dlabel=" ";
	label MS			= "Metabolic syndrome (%)"
		  age_gp		= "Age group"
		  Sarco_ASM_Wt_ = "sarcopenia"
	;
	format age_gp Age_Grp. Sarco_ASM_Wt_ Question. MS 4.2;
RUN;

/* Generate the bar chart. */
ods pdf file="&results.\Kim_Fig4_output.pdf";
title 'Fig 4. The prevalence of metabolic syndrome in a 10-year age strata according to the presence of sarcopenia.';
PROC SGPLOT data=dlabel2;
	vbarparm category = age_gp response=MS / group = Sarco_ASM_Wt_  datalabel=dlabel groupdisplay=cluster barwidth = 0.4;
RUN;
ods pdf close;

/*** Table 4 ***/
/* Pull in variable "MS_5cri", the variable represents the number of MS criteria an individual met, and categorized it into: */
/* MS_Severe_45: met 4 or 5 criteria. */
/* MS_Severe_5: met all 5 criteria.*/
PROC SQL;
	create table Kim_table_4 as
	select a.*, b. MS_5cri,
		case
			when b. MS_5cri = 5 then 1
			else 0 end as MS_Severe_5,
		case
			when b. MS_5cri = 5 or b. MS_5cri = 4 then 1
			else 0 end as MS_Severe_45
 	from Kim_fig_4 a, desk.Kim b
	where a.ID = b.ID;
QUIT;

/* Macro for running the models. */
/* Yes, I am running out of ideas on how to name these things. */
%MACRO Kim_severe_models(ModelNames=,VariablesToAdjust=,ClassVar=);
PROC LOGISTIC data = Kim_table_4;
	class Sarco_ASM_Wt_ (param = ref ref = "0") &ClassVar;
	model MS_Severe_45 (event = "1") = Sarco_ASM_Wt_ &VariablesToAdjust;
	ods output OddsRatios=&ModelNames._OR_S45;
	ods output ParameterEstimates=&ModelNames._Pe_S45 (where=(Variable = "Sarco_ASM_Wt_"));
RUN;
DATA &ModelNames._OR_S45; set &ModelNames._OR_S45 (obs = 1); RUN;
PROC SQL;
	create table &ModelNames._model_S45 as
	select a.*, b. ProbChiSq
	from &ModelNames._OR_S45 a, &ModelNames._Pe_S45 b;
QUIT;

PROC LOGISTIC data = Kim_table_4;
	class Sarco_ASM_Wt_ (param = ref ref = "0") &ClassVar;
	model MS_Severe_5 (event = "1") = Sarco_ASM_Wt_ &VariablesToAdjust;
	ods output OddsRatios=&ModelNames._OR_S5;
	ods output ParameterEstimates=&ModelNames._Pe_S5 (where=(Variable = "Sarco_ASM_Wt_"));
RUN;
DATA &ModelNames._OR_S5; set &ModelNames._OR_S5 (obs = 1); RUN;
PROC SQL;
	create table &ModelNames._model_S5 as
	select a.*, b. ProbChiSq
	from &ModelNames._OR_S5 a, &ModelNames._Pe_S5 b;
QUIT;

DATA &ModelNames;
	retain Source OddsRatioEst LowerCL UpperCL ProbChiSq;
	set	 &ModelNames._model_S45 &ModelNames._model_S5 indsname=MS_criteria;
	if MS_criteria = upcase("WORK.&ModelNames._model_S45") then Source = "Metabolic syndrome (4 or 5 criteria)";
	else if MS_criteria = upcase("WORK.&ModelNames._model_S5") then Source = "Metabolic syndrome (5 criteria)";
	drop Effect;
RUN;
%MEND Kim_severe_models;

%Kim_severe_models(ModelNames=Crude_S,VariablesToAdjust=,ClassVar=);
%Kim_severe_models(ModelNames=Model1_S,VariablesToAdjust=Age Sex,ClassVar=Sex);
%Kim_severe_models(ModelNames=Model2_S,VariablesToAdjust=Age Sex Obesity,ClassVar=Sex Obesity);
%Kim_severe_models(ModelNames=Model3_S,VariablesToAdjust=Age Sex Obesity HT DM DysL_,ClassVar=Sex Obesity HT DM DysL_);
%Kim_severe_models(ModelNames=Model4_S,VariablesToAdjust=Age Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn,ClassVar=Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn);
%Kim_severe_models(ModelNames=Model5_S,VariablesToAdjust=Age Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn CRP,ClassVar=Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn);

/* Combine all results */
title 'Table 4. Association between severe metabolic syndrome (4 or 5 criteria) and sarcopenia.';
DATA desk.Table4; 
	retain Model Source OddsRatioEst LowerCL UpperCL ProbChiSq;
	length Source $45;
	set Crude_S Model1_S Model2_S Model3_S Model4_S Model5_S indsname=mod;
	Model = tranwrd(mod,"WORK.","");
	by Source;
RUN;

/*** Table 5 ***/
/* Pull in variable "Quartile", the variable represents the quartile group for ASW%. */
PROC SQL;
	create table Kim_table_5 as
	select a.*, b. ASM_Wt__Q4
	from Kim_table_4 a, desk.Kim b
	where a.ID = b.ID
	;
QUIT; 

/* I want more vacation :((( */
%MACRO Kim_Q_Models(ModelNames=,VariablesToAdjust=,ClassVar=);
PROC LOGISTIC data = Kim_table_5;
	class ASM_Wt__Q4 (param =ref ref = "1");
	model MS (event = "Yes") = ASM_Wt__Q4;
	ods output OddsRatios=&ModelNames._OR_Q;
	ods output ParameterEstimates=&ModelNames._Pe_Q;
RUN;
DATA &ModelNames._OR_Q; set &ModelNames._OR_Q (obs = 3); RUN;
DATA &ModelNames._Pe_Q_1;
    do i = 2,3,4;
        set &ModelNames._Pe_Q point = i;
        output;
    end;
    stop;
RUN;

PROC SQL;
	create table &ModelNames._model_Q as
	select distinct a.*, b. ProbChiSq
	from &ModelNames._OR_Q a, &ModelNames._Pe_Q_1 b;
QUIT;

PROC LOGISTIC data = Kim_table_5;
	model MS (event = "Yes") = ASM_Wt__Q4;
	ods output OddsRatios=&ModelNames._OR_PerQ;
	ods output ParameterEstimates=&ModelNames._Pe_PerQ(where=(Variable="ASM_Wt__Q4"));
RUN;
DATA &ModelNames._OR_PerQ; set &ModelNames._OR_PerQ (obs = 1); RUN;
PROC SQL;
	create table &ModelNames._model_PerQ as
	select a.*, b. ProbChiSq
	from &ModelNames._OR_PerQ a, &ModelNames._Pe_PerQ b;
QUIT;

DATA &ModelNames._Q;
	retain VariableType Effect OddsRatioEst LowerCL UpperCL ProbChiSq; 
	length VariableType $ 45;
	set &ModelNames._model_Q &ModelNames._model_PerQ indsname=q_type;
	if q_type = upcase("WORK.&ModelNames._model_Q") then VariableType = "Categorical quartiles (ref = Q1)";
	else if q_type = upcase("WORK.&ModelNames._model_PerQ") then VariableType = "Per quartile increase";
RUN;

PROC SORT data = &ModelNames._Q nodupkey;
	by Effect;
RUN;
PROC SORT data = &ModelNames._Q; by VariableType; RUN;
%MEND Kim_Q_Models;

%Kim_Q_Models(ModelNames=Unadjusted,VariablesToAdjust=,ClassVar=);
%Kim_Q_Models(ModelNames=Model1,VariablesToAdjust=Age Sex,ClassVar=Sex);
%Kim_Q_Models(ModelNames=Model2,VariablesToAdjust=Age Sex Obesity,ClassVar=Sex Obesity);
%Kim_Q_Models(ModelNames=Model3,VariablesToAdjust=Age Sex Obesity HT DM DysL_,ClassVar=Sex Obesity HT DM DysL_);
%Kim_Q_Models(ModelNames=Model4,VariablesToAdjust=Age Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn,ClassVar=Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn);
%Kim_Q_Models(ModelNames=Model5,VariablesToAdjust=Age Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn CRP,ClassVar=Sex Obesity HT DM DysL_ shx_smoke_yn shx_alcohol_yn);

/* Combine all results */
title 'Table 5. Risk of metabolic syndrome in each quartile of sarcopenia.';
DATA desk.Table5; 
	retain Model VariableType Effect OddsRatioEst LowerCL UpperCL ProbChiSq;
	length VariableType $45;
	set Unadjusted_Q Model1_Q Model2_Q Model3_Q Model4_Q Model5_Q indsname=mod;
	Model = substr(mod,6,6);
	if Model = "UNADJU" then Model = "Unadjusted";
	else Model =Model;
RUN;

/*** Figure 5 ***/
/* Scatterplot of ASM(%) and abdominal muscle area measured by CT(cm^2). */
title 'Fig 5. Correlation between the appendicular skeletal muscle mass (ASM) measured by Inbody 720 and the total abdominal muscle area
measured by computed tomography (CT) scan.';
/* Cannot find variable indicating abdominal muscle area. */

/*** Table Outputs ***/
PROC EXPORT data = desk.Table2 
			dbms = xlsx
			outfile = "&results.\Table 2.xlsx";
RUN;

PROC EXPORT data = desk.Table3 
			dbms = xlsx
			outfile = "&results.\Table 3.xlsx";
RUN;

PROC EXPORT data = desk.Table4 
			dbms = xlsx
			outfile = "&results.\Table 4.xlsx";
RUN;

PROC EXPORT data = desk.Table5
			dbms = xlsx
			outfile = "&results.\Table 5.xlsx";
RUN;
