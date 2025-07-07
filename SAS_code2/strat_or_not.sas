/* Assign a library reference to the NWTSCO dataset directory */
libname mydata '/home/u62057975/NWTSCO/';

/* Macro to run three types of Cox proportional hazards models and compare fit statistics */
%macro phreg_models(data=, time=, event=, desc=);

    /* Print a note to the SAS log for tracking */
    %put NOTE: Running PHREG models for &desc;

    /* Suppress default ODS output to avoid clutter from individual model tables */
    ods exclude all;

    /* ==============================
       Model 1: Study as Covariate
       ============================== */
    /* Capture fit statistics into a dataset named fit_cov */
    ods output FitStatistics=fit_cov;

    /* Cox PH model with study as a covariate */
    proc phreg data=&data;
        class study(ref="3") histol(ref="0") stage(ref="1") / param=ref;
        model &time*&event(0) = age tumdiam histol stage study;
    run;

    /* Add model label to the fit statistics dataset */
    data fit_cov;
        set fit_cov;
        model = "Study as Covariate";
    run;

    /* ==============================
       Model 2: Stratified by Study
       ============================== */
    /* Capture fit statistics into a dataset named fit_strat */
    ods output FitStatistics=fit_strat;

    /* Cox PH model with stratification by study (allows different baseline hazards) */
    proc phreg data=&data;
        class histol(ref="0") stage(ref="1") / param=ref;
        model &time*&event(0) = age tumdiam histol stage;
        strata study;
    run;

    /* Add model label to the fit statistics dataset */
    data fit_strat;
        set fit_strat;
        model = "Stratified by Study";
    run;

    /* ============================================
       Model 3: Stratified + Study Interactions
       ============================================ */
    /* Capture fit statistics into a dataset named fit_interact */
    ods output FitStatistics=fit_interact;

    /* Cox PH model stratified by study, with interaction terms between study and covariates */
    proc phreg data=&data;
        class histol(ref="0") stage(ref="1") / param=ref;
        model &time*&event(0) = age tumdiam histol stage study
                                age*study tumdiam*study histol*study stage*study;
        strata study;
    run;

    /* Add model label to the fit statistics dataset */
    data fit_interact;
        set fit_interact;
        model = "Stratified + Interactions";
    run;

    /* Re-enable ODS output for final result display */
    ods exclude none;

    /* Combine all fit statistics into one dataset for comparison */
    data all_fit;
        set fit_cov fit_strat fit_interact;
    run;

    /* Print combined fit statistics table: Model name, Criterion (AIC, -2LogL, etc.), and value */
    proc print data=all_fit label noobs;
        title "Model Fit Statistics: &desc";
        var model criterion withcovariates;
    run;

    /* Clean up intermediate datasets from WORK library */
    proc datasets lib=work nolist;
        delete fit_cov fit_strat fit_interact;
    quit;

%mend;


/* For time to death */
%phreg_models(data=mydata.nwtsco_cat, time=tsur, event=dead, desc=Time to Death);

/* For time to relapse */
%phreg_models(data=mydata.nwtsco_cat, time=trel, event=relaps, desc=Time to Relapse);

/* For time from relapse to death */
data nwtsco_rel_to_death;
    set mydata.nwtsco_cat;
    where relaps = 1 and tsur >= trel;
    time_diff = tsur - trel;
    event_between = dead;
run;

%phreg_models(data=nwtsco_rel_to_death, time=time_diff, event=event_between, desc=Time from Relapse to Death);
