/* Define a macro to assess the functional form of a predictor using Martingale residuals */
%macro martingale_check(data=, time=, event=, martin_resid_pred=, desc=);

    /* Log message to track macro execution in log window */
    %put NOTE: Running Martingale residual check for &desc;

    /* Step 1: Fit a reduced Cox proportional hazards model 
       Exclude the predictor of interest (&martin_resid_pred) to assess its proper functional form */
    proc phreg data=&data;
        model &time*&event(0) = tumdiam histol stage; /* Include known covariates, exclude test predictor */
        strata study; /* Stratify by study for confounding control */
        output out=resids resmart=martingale; /* Output Martingale residuals */
    run;

    /* Step 2: Generate Martingale residual plot to assess nonlinearity of the excluded predictor */
	proc sgplot data=resids;
    	scatter x=&martin_resid_pred y=martingale / 
            markerattrs=(symbol=circlefilled size=6 color=gray); /* Raw residuals */
    	loess x=&martin_resid_pred y=martingale / 
            smooth=0.5 
            lineattrs=(thickness=2 color=black); /* LOESS smooth to reveal trend */
    	refline 0 / axis=y lineattrs=(pattern=shortdash color=red); /* Reference line at 0 */
    	xaxis label="&martin_resid_pred" labelattrs=(weight=bold size=11);
    	yaxis label="Martingale Residuals" labelattrs=(weight=bold size=11);
    	title font='Arial' height=12pt bold 
            "Martingale Residuals vs. &martin_resid_pred — &desc"; /* Dynamic and polished title */
	run;

    /* Step 3: Clean up the temporary dataset with residuals */
    proc datasets lib=work nolist;
        delete resids;
    quit;

%mend;


/* Assign library reference to NWTSCO dataset folder */
libname mydata '/home/u62057975/NWTSCO/';

/* Run Martingale residual check for Time to Relapse endpoint */
%martingale_check(
    data=mydata.nwtsco_cat,
    time=trel,
    event=relaps,
    martin_resid_pred=age,
    desc=Time to Relapse
);

/* Run Martingale residual check for Time to Death endpoint */
%martingale_check(
    data=mydata.nwtsco_cat,
    time=tsur,
    event=dead,
    martin_resid_pred=age,
    desc=Time to Death
);

/* Prepare dataset to evaluate time between relapse and death */
data nwtsco_rel_to_death;
    set mydata.nwtsco_cat;
    where relaps = 1 and tsur >= trel;  /* Include patients who relapsed before dying */
    time_diff = tsur - trel;            /* Define time between relapse and death */
    event_between = dead;               /* Event indicator remains death */
run;

/* Run Martingale residual check for Time from Relapse to Death */
%martingale_check(
    data=nwtsco_rel_to_death,
    time=time_diff,
    event=event_between,
    martin_resid_pred=age,
    desc=Time from Relapse to Death
);




%macro aic_comparison(
    data=,          /* Input dataset */
    time=,          /* Time variable (e.g., tsur, trel, or time_diff) */
    event=,         /* Event indicator variable (e.g., dead, relaps, event_between) */
    desc=           /* Description to annotate output and titles */
);

    %put NOTE: Running AIC and -2 Log L comparison for &desc;

    /* Suppress all default ODS output temporarily */
    ods exclude all;

    /* ----- Model 1: Continuous Tumor Diameter ----- */
    ods output FitStatistics=aic_cont;  /* Save fit statistics to a dataset */
    proc phreg data=&data;
        class histol(ref="0") stage(ref="1") age_group(ref="<2 yrs") / param=ref;
        model &time*&event(0) = age_group tumdiam histol stage;
        strata study;
    run;

    /* Add model description for continuous model */
    data aic_cont;
        length model $60;
        set aic_cont;
        model = "&desc - Continuous Size";
    run;

    /* ----- Model 2: Categorical Tumor Size Group ----- */
    ods output FitStatistics=aic_cat;
    proc phreg data=&data;
        class histol(ref="0") stage(ref="1") age_group(ref="<2 yrs") size_group(ref="<10 cm") / param=ref;
        model &time*&event(0) = age_group size_group histol stage;
        strata study;
    run;

    /* Add model description for categorical model */
    data aic_cat;
        length model $60;
        set aic_cat;
        model = "&desc - Categorical Size";
    run;

    /* Restore ODS output */
    ods exclude none;

    /* Combine both models and retain only AIC and -2 Log L rows */
    data all_aic;
        length model $60;
        set aic_cont aic_cat;
        where criterion in ("AIC", "-2 LOG L");
    run;

    /* Sort for proper transposition by model */
    proc sort data=all_aic;
        by model;
    run;

    /* Transpose to convert rows to columns (wide format) */
    proc transpose data=all_aic out=aic_wide(drop=_name_) prefix=stat_;
        by model;
        id criterion;
        var withcovariates;
    run;

    /* Rename problematic variable names to valid SAS identifiers */
    data aic_wide_clean;
        set aic_wide(rename=('stat_-2 LOG L'n=LogL stat_AIC=AIC));
        keep model AIC LogL;
    run;

    /* Print final clean table for AIC and -2 Log Likelihood */
    proc print data=aic_wide_clean label noobs;
        title "AIC and -2 Log Likelihood Comparison for &desc";
        label
            model = "Model Description"
            AIC = "AIC"
            LogL = "-2 Log Likelihood";
    run;

    /* Cleanup intermediate datasets to avoid clutter */
    proc datasets lib=work nolist;
        delete aic_cont aic_cat all_aic aic_wide aic_wide_clean;
    quit;

%mend;


/* Time to Death */
%aic_comparison(
    data=mydata.nwtsco_cat,
    time=tsur,
    event=dead,
    desc=Time to Death
);

/* Time to Relapse */
%aic_comparison(
    data=mydata.nwtsco_cat,
    time=trel,
    event=relaps,
    desc=Time to Relapse
);

/* Relapse to Death */
%aic_comparison(
    data=nwtsco_rel_to_death,
    time=time_diff,
    event=event_between,
    desc=Time from Relapse to Death
);
