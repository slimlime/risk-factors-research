********************************************************************************
*
*	Do-file:		an_multivariable_cox_models.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		egdata.dta
*
*	Data created:	None
*
*	Other output:	Log file:  an_multivariable_cox_models.log
*
********************************************************************************
*
*	Purpose:		This do-file performs multivariable (fully adjusted) 
*					Cox models. 
*  
********************************************************************************
*	
*	Stata routines needed:	stbrier	  
*
********************************************************************************




* Open a log file
capture log close
log using "an_multivariable_cox_models", text replace

use egdata, clear
************************************************************************************************************
*!!!! TEMP FIX FOR DODGY DUMMY DATA 
noi di in red _n "*************************************************************************************" ///
	_n "NOTE TEMPORARY DATA MANIP PRESENT FOR TESTING: DELETE FROM DOFILE BEFORE RUNNING LIVE" ///
	_n "*************************************************************************************"
by patient_id: keep if _n==1
replace chronic_kidney_disease=1 if uniform()<0.01
replace neurological_condition=1 if uniform()<0.01
************************************************************************************************************

************************************
*Get composite outcome (nb this may be better added to cr_...;)
gen stime_composite = min(stime_itu, stime_died)
gen composite = (died|itu)
************************************


******************************
*  Multivariable Cox models  *
******************************

*DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basecoxmodel
prog define basecoxmodel
	syntax , age(string) bmi(string) [ethnicity(real 0)] 

	if `ethnicity'==1 local ethnicity "i.ethnicity"
	else local ethnicity

	stcox 	`age' 							///
			i.male 							///
			`bmi'							///
			i.smoke 						///
			`ethnicity'						///
			i.imd 							///
			i.bpcat 						///
			i.chronic_respiratory_disease 	///
			i.asthma 						///
			i.chronic_cardiac_disease 		///
			i.diabetes 						///
			i.cancer 	/*NB UPDATE*/		///
			i.chronic_liver_disease 		///
			i.neurological_condition 		///
			i.chronic_kidney_disease 		///
			i.organ_transplant 				///
			i.spleen 						///
			i.ra_sle_psoriasis  			///
			/*endocrine?*/					///
			/*immunosuppression?*/			///
			, strata(stp)
end



foreach outcome of any hosp died itu composite{

stset stime_`outcome', fail(`outcome') enter(enter_date) origin(enter_date) id(patient_id) 

*Age spline model
basecoxmodel, age("age1 age2 age3")  bmi("ib2.bmicat") ethnicity(0)
estimates save ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_noeth, replace
estat concordance /*c-statistic*/
	
*Age group model
basecoxmodel, age("i.agegroup")  bmi("ib2.bmicat") ethnicity(0)
estimates save ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agegroup_bmicat_noeth, replace
estat concordance /*c-statistic*/

*Complete case ethnicity model
basecoxmodel, age("age1 age2 age3")  bmi("ib2.bmicat") ethnicity(1)
estimates save ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_CCeth, replace
estat concordance /*c-statistic*/
 

************************************************************************
* Add IBS 

* Calculate at 60 days
*
*stbrier, bt(60) efron

/*
stbrier age1 age2 age3 male i.bmicat i.smoke							///
		resp asthma heart diabetes cancer liver neuro_dis kidney_dis 	///
		transplant spleen immunosup hypertension autoimmune sle 		///
		endocrine														///
		, shared(stp) bt(60) 											///
		ipcw(age1 age2 age3 male i.bmicat i.smoke						///
		resp asthma heart diabetes cancer liver neuro_dis kidney_dis 	///
		transplant spleen immunosup hypertension autoimmune sle 		///
		endocrine)
*/

* Simple model just to try:
/*
stbrier age1 age2 age3 male 											///
		, shared(stp) bt(60) 											///
		ipcw(age1 age2 age3 male)
*/
************************************************************************

} /*end of looping round outcomes*/

* Close log file  (bootstrapping likely to take a while)
log close





/*   Add bootstrapping to correct C-statistic for overoptimism     */

* ADD BOOTSTRAP HERE!



