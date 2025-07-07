/* Macro to run AFT model (PROC LIFEREG) grouped by a BY variable */
%macro run_lifereg_by_group(
    data=,                     /* Fully qualified dataset name (e.g., mylib.dataset or just dataset) */
    time=,                     /* Time-to-event variable */
    event=,                    /* Event indicator variable (1=event, 0=censored) */
    covars=,                   /* Covariate variables to include in the model */
    dist=weibull,              /* Distribution type for the AFT model */
    byvar=                     /* Grouping variable (e.g., study ID) */
);

    /* Sort the dataset by the grouping variable to enable BY-group processing */
    proc sort data=&data;
        by &byvar;
    run;

    /* Restrict output to only show Fit Statistics (for model comparison) */
    ods select FitStatistics;

    /* Run parametric survival regression using the specified distribution */
    proc lifereg data=&data;
        by &byvar;                         /* Perform model fitting separately for each group */
        class &covars;                    /* Specify categorical variables */
        model &time*&event(0) = &covars   /* Define time, censoring, and covariates */
            / dist=&dist;                 /* Specify chosen distribution (e.g., Weibull) */
    run;

    /* Re-enable default ODS output after selective suppression */
    ods select all;

%mend;

/* Define a library reference to the data directory */
libname mydata '/home/u62057975/NWTSCO/';

/* Create a new dataset for patients who relapsed before death */
/* Compute time from relapse to death and keep the death indicator */
data nwtsco_rel_to_death;
    set mydata.nwtsco_cat_ordered;
    where relaps = 1 and tsur >= trel;     /* Ensure relapse occurred before death */
    time_diff = tsur - trel;               /* Calculate time from relapse to death */
    event_between = dead;                  /* Death is the event of interest */
run;

/* Run models with different AFT distributions for model selection via Fit Statistics */
%run_lifereg_by_group(
    data=nwtsco_rel_to_death,
    time=time_diff,
    event=event_between,
    covars=age_group_ordered size_group_ordered histol_ordered stage_ordered,
    dist=weibull,
    byvar=study
);

%run_lifereg_by_group(
    data=nwtsco_rel_to_death,
    time=time_diff,
    event=event_between,
    covars=age_group_ordered size_group_ordered histol_ordered stage_ordered,
    dist=exp,
    byvar=study
);

%run_lifereg_by_group(
    data=nwtsco_rel_to_death,
    time=time_diff,
    event=event_between,
    covars=age_group_ordered size_group_ordered histol_ordered stage_ordered,
    dist=lognormal,
    byvar=study
);

%run_lifereg_by_group(
    data=nwtsco_rel_to_death,
    time=time_diff,
    event=event_between,
    covars=age_group_ordered size_group_ordered histol_ordered stage_ordered,
    dist=llogistic,
    byvar=study
);

%run_lifereg_by_group(
    data=nwtsco_rel_to_death,
    time=time_diff,
    event=event_between,
    covars=age_group_ordered size_group_ordered histol_ordered stage_ordered,
    dist=normal,
    byvar=study
);

%run_lifereg_by_group(
    data=nwtsco_rel_to_death,
    time=time_diff,
    event=event_between,
    covars=age_group_ordered size_group_ordered histol_ordered stage_ordered,
    dist=gamma,
    byvar=study
);





