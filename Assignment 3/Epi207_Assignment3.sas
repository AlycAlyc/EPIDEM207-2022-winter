/*******************************************************************************************************
Name: Epi207_Assignment3.sas
Date: 03/04/22
Created by: Yang Cheng Hu
Purpose: This code is used to answer questions on Assignment 3 for the EPI 207 class, which focused on 
		 reproducing all tables (and possibly figures) shown in the group project by Yancen Pan and 
		 Melissa Soohoo. The project aims to investigate the overall and sex-stratified relationship 
		 between smoking status and mortality in a general population sample of adults in Germany across 
		 different levels of adjustment.
NOTE: Data from the project is available at https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8562854/#sec017
*******************************************************************************************************/

libname hw3 "\\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 8\Dataset and formats\";

%let MacroDir= \\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 3\Homework\Table_1_Macro\Table1;
%let results = \\Client\H$\Desktop\UCLA\2022\2022 Winter\207\Week 8\Reproduced tables; 

/* Specify the data format */
Option fmtsearch=(hw3);

/*** TABLE 1 ***/

/* For this part, I will use the Table 1 macro provided in this class follow-up with slight manuaul modification
   to remove p-values. */
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

/* Call the Table 1 Macro (DO NOT REPLICATE THE P-VALUE.) */
%Table1(DSName=hw3.John_clean2,
        GroupVar=Smoke,
        NumVars=age,
        FreqVars=female age_grp edu lifetime_aab alc_cons death_status mort health COD CVD_mort CA_mort,
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
        Out=John_Table1,
        Out1way=)

*options mprint  symbolgen mlogic;
run;

ods pdf file="&results.\John_Table1_output.pdf";
title 'Table 1. Clinical characteristics according to ASM% quartiles';
%Table1Print(DSname=John_Table1,Space=Y)
ods pdf close;
run;

/* Before loaging in the dataset, apply the provided formats */
DATA john_clean3; set hw3.john_clean2;
	format  lifetime_aab lifef.  
			edu eduf. 
			age_grp agef. 
			health healthf. 
			COD codf. 
			Smoke smkf.
			alc_cons consf.
	;
RUN;


/*** Table 2 ***/
/* Setup models */
%let covar2 = age female;
%let covar3 = health alc_cons edu;

/* Test for proportional hazard assumption*/
%MACRO proptest(out);
PROC PHREG data =hw3.john_clean2;
title "Test for proportionality assumption: Crude model";
	format smoke;
	class smoke (ref= "0")  ;
	model futime*&out (0) = smoke smkt/ rl ties=efron; 
		smkt = smoke*log(futime);
		proportionality_test: test smkt;
	ods output TestStmts = PropTest_mod1_&out;
RUN;  

PROC PHREG data =hw3.john_clean2;
title "Test for proportionality assumption: Model 2";
	format smoke;
	class smoke (ref= "0")  ;
	model futime*&out (0) = smoke age female smkt aget femalet/ rl ties=efron; 
		smkt = smoke*log(futime);
		aget = age*log(futime);
		femalet = female*log(futime);
		proportionality_test: test smkt, aget, femalet;
	ods output TestStmts = PropTest_mod2_&out;
RUN;  

PROC PHREG data =hw3.john_clean2;
title "Test for proportionality assumption: Model 3";
	format smoke;
	class smoke (ref= "0")  ;
	model futime*&out (0) = smoke age female health alc_cons edu 
							smkt aget femalet healtht alc_const edut/ rl ties=efron; 
		smkt = smoke*log(futime);
		aget = age*log(futime);
		femalet = female*log(futime);
		healtht = health*log(futime); 
		alc_const = alc_cons*log(futime);
		edut = edu*log(futime);
		proportionality_test: test smkt, aget, femalet, health, alc_const, edut;
	ods output TestStmts = PropTest_mod3_&out;
RUN;  
%MEND proptest;
%proptest(mort);
%proptest(cvd_mort);
%proptest(ca_mort);

DATA hw3.PropTests; 
	set PropTest_mod1_mort 		PropTest_mod2_mort 		PropTest_mod3_mort
		PropTest_mod1_cvd_mort  PropTest_mod2_cvd_mort  PropTest_mod3_cvd_mort
		PropTest_mod1_ca_mort 	PropTest_mod2_ca_mort 	PropTest_mod3_CA_mort
		indsname=mod;
	drop status label;
	model = tranwrd(mod,"WORK.","");
RUN;

/* Making Table 2 */
%MACRO phmodel(data, out);
/* Proportional hazard models */
PROC PHREG data =&data.;
title "Proportional hazard model: Model 1";
	format smoke;
	class smoke (ref= "0")  ;
	model futime*&out. (0) = smoke/ rl ties=efron; 
	ods output ParameterEstimates = &data._Mod1_&out.;
RUN;
QUIT;

PROC PHREG data =&data.;
title "Proportional hazard model: Model 2";
	format smoke;
	class smoke (ref= "0");
	model futime*&out. (0) = smoke &covar2/ rl ties=efron; 
	ods output ParameterEstimates = &data._Mod2_&out.(where=(Parameter = "Smoke"));
RUN;
QUIT;

PROC PHREG data =&data.;
title "Proportional hazard model: Model 3";
	format smoke;
	class smoke (ref= "0") &covar3;
	model futime*&out. (0) = smoke &covar2 &covar3/ rl ties=efron; 
	ods output ParameterEstimates = &data._Mod3_&out.(where=(Parameter = "Smoke"));
RUN; 
QUIT;

/* Get the frequencies of event and total number in each smoking group*/
PROC FREQ data = &data.; 
	table  smoke*&out./ nocol nopercent outpct ;
	where &out. ~=.; 
	format smoke;
	ods output CrossTabFreqs = &data._Event_&out.(where = (&out. = 1));
	ods output CrossTabFreqs = &data._Freq_&out.(where = (&out. = .));
RUN;
QUIT;

PROC SQL;
	create table &data._count3_&out. as
	select a.smoke, a.Frequency as tot_freq_&out., b.Frequency as event_num_&out., b.RowPercent,
		case a.smoke
			when 0 then "Never smoker "
			when 1 then "Ever less than daily"
			when 2 then "Former daily "
			when 3 then "Current daily <20 cpd "
			when 4 then "Current daily >=20 cpd"
		end as Smoking_status
	from  &data._Freq_&out. a, &data._Event_&out. b
	where a.smoke = b.smoke;
QUIT;

/* Combining outputs */
DATA &data._PH_models_&out.;
	merge 
		%do i = 1 %to 3;
    	&data._mod&i._&out. (rename=( HazardRatio = &data._&out._HazardRatio_mod&i. 
							  		  HRLowerCL = &data._&out._HRLowerCL_mod&i. 
							  		  HRUpperCL = &data._&out._HRUpperCL_mod&i.))
		%end;
	;
	ClassVal1 = input(ClassVal0, 8.);
	by ClassVal0;
	keep	ClassVal1
		%do i = 1 %to 3;
			&data._&out._HazardRatio_mod&i. &data._&out._HRLowerCL_mod&i. &data._&out._HRUpperCL_mod&i.
		%end;
	;
  	label 
		%do i = 1 %to 3;	
			&data._&out._HazardRatio_mod&i. = "&data._&out._HazardRatio_mod&i."
			&data._&out._HRLowerCL_mod&i.	 = "&data._&out._HRLowerCL_mod&i."
			&data._&out._HRUpperCL_mod&i.	 = "&data._&out._HRUpperCL_mod&i."
		%end;
	;
  	format
		 %do i = 1 %to 3;
			&data._&out._HazardRatio_mod&i. &data._&out._HRLowerCL_mod&i. &data._&out._HRUpperCL_mod&i.
		%end; 8.2
	;
RUN;

PROC SQL;
	create table &data._table2_&out. as
	select	a.*, 
		%do i =1 %to 3;
			b.&data._&out._HazardRatio_mod&i.,
			b.&data._&out._HRLowerCL_mod&i.,
			b.&data._&out._HRUpperCL_mod&i.,
		%end;
		b.ClassVal1
	from &data._count3_&out. a left join &data._PH_models_&out. b
		on a.smoke = b.ClassVal1
;
QUIT;
%MEND phmodel;
%phmodel(john_clean3, mort);
%phmodel(john_clean3, cvd_mort);
%phmodel(john_clean3, ca_mort);

DATA hw3.table2; 
	merge john_clean3_table2_mort
		  john_clean3_table2_cvd_mort
		  john_clean3_table2_ca_mort;
	by smoke;
	drop ClassVal1;
RUN;

PROC EXPORT data = hw3.table2 
			dbms = xlsx
			outfile = "&results.\Table 2 unorganized ver.xlsx"
			replace;
RUN;

/*** Table 3 ***/
/* Make two data subsets by gender. */
DATA female; set john_clean3(where = (female = 1));RUN;
DATA male; set john_clean3(where = (female = 0));RUN;

/* Change &covar2 before running the macro */
%let covar2 = age;
%phmodel(female, mort);
%phmodel(male, mort);

DATA female_table2_mort; set female_table2_mort;
	rename tot_freq_mort = fem_freq_mort
		   event_num_mort= fem_event_mort;
RUN;

DATA male_table2_mort; set male_table2_mort;
	rename tot_freq_mort = male_freq_mort
		   event_num_mort= male_event_mort;
RUN;

DATA hw3.table3; 
	merge female_table2_mort
		  male_table2_mort;
	by smoke;
	drop ClassVal1;
RUN;

PROC EXPORT data = hw3.table3 
			dbms = xlsx
			outfile = "&results.\Table 3 unorganized ver.xlsx"
			replace;
RUN;

/*** Supplementary table ***/
%phmodel(female, cvd_mort);
%phmodel(female, ca_mort);
%phmodel(male, cvd_mort);
%phmodel(male, ca_mort);

DATA Female_table2_cvd_mort; set Female_table2_cvd_mort;
	rename tot_freq_cvd_mort = fem_freq_cvd_mort
		   event_num_cvd_mort= fem_event_cvd_mort;
RUN;

DATA male_table2_cvd_mort; set male_table2_cvd_mort;
	rename tot_freq_cvd_mort = male_freq_cvd_mort
		   event_num_cvd_mort= male_event_cvd_mort;
RUN;


DATA Female_table2_ca_mort; set Female_table2_ca_mort;
	rename tot_freq_ca_mort = fem_freq_ca_mort
		   event_num_ca_mort= fem_event_ca_mort;
RUN;

DATA male_table2_ca_mort; set male_table2_ca_mort;
	rename tot_freq_ca_mort = male_freq_ca_mort
		   event_num_ca_mort= male_event_ca_mort;
RUN;

DATA hw3.sup_table; 
	merge Female_table2_cvd_mort
		  male_table2_cvd_mort
		  Female_table2_ca_mort
		  male_table2_ca_mort
		  ;
	by smoke;
	drop ClassVal1;
RUN;

PROC EXPORT data = hw3.sup_table 
			dbms = xlsx
			outfile = "&results.\Supplementary table unorganized ver.xlsx"
			replace;
RUN;

/*** Figure 2 ***/
/*Figure 2 was the age/sex adjusted survival function.
Calculated the reference values based on the whole cohort. 
*/;
ods graphics on; 
ods output survivalplot=_surv2; 
PROC PHREG data = hw3.john_clean2 plots(overlay)=survival ;
	class   smoke (ref='Never smoker') female ;
	model futime*mort (0)= smoke age female  /rl ties=efron ;
	baseline covariates= hw3.john_clean2 out=base/diradj group=smoke;
RUN; 

PROC SGPLOT data =_surv2; 
title "Figure 2. Replicated Age & Sex Adjusted Total Mortality Survival of Smoking Status with Cox proportional hazards regression";
step x=time y=survival/group = smoke; 
styleattrs 	datacontrastcolors= ( navy green red darkorange brown ) 
			datalinepatterns=(solid dash dashdotdot  shortdashdot dot longdash );
keylegend/title= " ";
RUN;; 
ods graphics off;

/*** Figure 3 ***/
/*Figure 3 was the age/sex/education/health status/alcohol consumption adjusted survival function.
Calculated the reference values based on the whole cohort. 
*/;
ods graphics on; 
ods output survivalplot=_surv3; 
PROC PHREG data = hw3.john_clean2 plots(overlay)=survival ;
	class   smoke (ref='Never smoker') female health edu alc_cons;
	model futime*mort (0)= smoke age female health edu alc_cons /rl ties=efron ;
	baseline covariates= hw3.john_clean2 out=base2/diradj group=smoke;
RUN; 

PROC SGPLOT data =_surv3; 
title "Figure 3. Replicated Age, Sex, Educational Level, Self-rated Health & Alcohol Consumption Adjusted Total Mortality Survival of Smoking Status with Cox proportional hazards regression";
step x=time y=survival/group = smoke; 
styleattrs 	datacontrastcolors= ( navy green red darkorange brown ) 
			datalinepatterns=(solid dash dashdotdot  shortdashdot dot longdash );
keylegend/title= " ";
RUN; 
ods graphics off;
