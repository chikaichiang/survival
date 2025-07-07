%macro lifereg_diag(
    data=,           /* Input dataset */
    time=,           /* Time-to-event variable */
    event=,          /* Event indicator (0 = censored) */
    predictors=,     /* Predictor variables for the model */
    dist=lognormal,  /* Distribution to use in the model (default is lognormal) */
    classvars=,      /* Class variables (optional) */
    by=,             /* BY-group variable(s), e.g. study (optional) */
    out=,            /* Name of the output dataset for residuals */
    label=           /* Label used in plot titles */
);

    /* Step 1: Fit the LIFEREG model with specified distribution and output standardized residuals */
    proc lifereg data=&data;
        %if %length(&by) %then %do;
            by &by; /* Perform separate models for each BY group if specified */
        %end;
        %if %length(&classvars) %then %do;
            class &classvars; /* Use class statement if categorical predictors are provided */
        %end;
        model &time*&event(0) = &predictors / dist=&dist; /* Fit the survival model */
        output out=&out xbeta=xbeta sres=sresid; /* Output linear predictor and standardized residuals */
    run;

    /* Step 2: Plot standardized residuals vs. linear predictor (XBETA) */
	proc means data=&out noprint;
    	var xbeta sresid;
    	output out=_axis_limits 
       		min=xbeta_min sresid_min 
        	max=xbeta_max sresid_max;
	run;

	data _null_;
    	set _axis_limits;
    	/* Add buffer (e.g., ±0.5) for better plot aesthetics */
    	call symputx('xbeta_min', floor(xbeta_min) - 0.5);
    	call symputx('xbeta_max', ceil(xbeta_max) + 0.5);
    	call symputx('sresid_min', floor(sresid_min) - 0.5);
    	call symputx('sresid_max', ceil(sresid_max) + 0.5);
	run;

	/* Step 3: Plot standardized residuals vs. linear predictor (XBETA) */
	%if %length(&by) %then %do;
    	proc sgpanel data=&out noautolegend;
        		panelby &by / columns=2 spacing=10 novarname headerattrs=(size=10 weight=bold);
        		styleattrs datacontrastcolors=(black);
        		scatter x=xbeta y=sresid /
            	markerattrs=(symbol=circlefilled size=6 color=darkblue) transparency=0.6;
        	refline 0 / axis=y lineattrs=(color=red pattern=shortdash);

        	colaxis label="Linear Predictor (XBETA)"
                labelattrs=(size=12 weight=bold)
                valueattrs=(size=10)
                min=&xbeta_min max=&xbeta_max;

        	rowaxis label="Standardized Residuals"
                labelattrs=(size=12 weight=bold)
                valueattrs=(size=10)
                min=&sresid_min max=&sresid_max;

        	title "Residuals vs Linear Predictor: &label";
        	title2;
    	run;
	%end;


    /* Step 3: Histogram of standardized residuals with normal density overlay */
    proc sgpanel data=&out noautolegend;
        panelby &by / columns=2 spacing=10 novarname headerattrs=(size=10 weight=bold);
        styleattrs datacontrastcolors=(black);
        histogram sresid / nbins=20 fillattrs=(color=darkblue transparency=0.2); /* Histogram */
        density sresid / type=normal lineattrs=(color=red pattern=solid thickness=1); /* Normal overlay */
        colaxis label="Standardized Residuals"
                labelattrs=(size=12 weight=bold)
                valueattrs=(size=10);
        rowaxis label="Frequency"
                labelattrs=(size=12 weight=bold)
                valueattrs=(size=10);
        title "Histogram of Standardized Residuals: &label";
        title2;
    run;

    /* Step 4: Prepare data for Q-Q plot */
    proc sort data=&out; by &by; run; /* Sort by BY-group */

    proc rank data=&out out=qq_prep ties=mean;
        by &by;
        var sresid;
        ranks sres_rank; /* Rank standardized residuals */
    run;

    /* Count number of observations per BY group */
    data qq_plot;
        set qq_prep;
        by &by;
        if first.&by then count = 0;
        count + 1;
        retain n;
        if last.&by then do;
            n = count;
            output;
        end;
    run;

    /* Merge ranks with total count to compute theoretical quantiles */
    proc sql;
        create table qq_final as
        select a.*, 
               probit((a.sres_rank - 0.5) / b.n) as theoretical_quantile /* Compute normal quantiles */
        from qq_prep as a
        inner join qq_plot as b
            on a.&by = b.&by;
    quit;

    /* Step 5: Q-Q plot comparing empirical residuals to normal distribution */
    proc sgpanel data=qq_final noautolegend;
    	panelby &by / columns=2 spacing=10 novarname headerattrs=(size=10 weight=bold);
    	styleattrs datacontrastcolors=(black);
    	scatter x=theoretical_quantile y=sresid /
        	markerattrs=(symbol=circlefilled size=6 color=darkblue) transparency=0.5;
    	lineparm x=0 y=0 slope=1 / lineattrs=(color=red pattern=shortdash thickness=1.5);
    	colaxis label="Theoretical Quantiles"
            labelattrs=(size=12 weight=bold)
            valueattrs=(size=10)
            values=(-4 to 4 by 1);  /* <- added axis control */
    	rowaxis label="Empirical Residuals"
            labelattrs=(size=12 weight=bold)
            valueattrs=(size=10)
            values=(-4 to 4 by 1);  /* <- added axis control */
    	title "Normal Q-Q Plot of Standardized Residuals: &label";
    	title2;
	run;

%mend;


/* Define library location for the dataset */
libname mydata '/home/u62057975/NWTSCO/';

/* Run LIFEREG model for time to death using lognormal distribution */
%lifereg_diag(
    data=mydata.nwtsco_cat_ordered,              /* Input dataset */
    time=tsur,                                    /* Time to death */
    event=dead,                                   /* Death indicator (0 = censored) */
    predictors=age_group_ordered size_group_ordered histol_ordered stage_ordered,  /* Covariates */
    dist=lognormal,                               /* Distribution: lognormal */
    classvars=age_group_ordered size_group_ordered histol_ordered stage_ordered,   /* Class variables */
    by=study,                                     /* Run model separately for each study */
    out=res_out_death,                            /* Output dataset with residuals */
    label=Time to Death                           /* Label for plots */
);

/* Run LIFEREG model for time to relapse using gamma distribution */
%lifereg_diag(
    data=mydata.nwtsco_cat_ordered,
    time=trel,                                    /* Time to relapse */
    event=relaps,                                 /* Relapse indicator (0 = censored) */
    predictors=age_group_ordered size_group_ordered histol_ordered stage_ordered,
    dist=gamma,                                   /* Distribution: gamma */
    classvars=age_group_ordered size_group_ordered histol_ordered stage_ordered,
    by=study,
    out=res_out_relaps,
    label=Time to Relapse
);

/* Create dataset for time from relapse to death */
data nwtsco_rel_to_death;
    set mydata.nwtsco_cat_ordered;
    where relaps = 1 and tsur >= trel;            /* Keep only patients who relapsed and survived past relapse */
    time_diff = tsur - trel;                      /* Calculate time from relapse to death */
    event_between = dead;                         /* Event of interest is still death */
run;

/* Run LIFEREG model for time from relapse to death using lognormal distribution */
%lifereg_diag(
    data=nwtsco_rel_to_death,
    time=time_diff,                               /* Time interval from relapse to death */
    event=event_between,
    predictors=age_group_ordered size_group_ordered histol_ordered stage_ordered,
    dist=lognormal,
    classvars=age_group_ordered size_group_ordered histol_ordered stage_ordered,
    by=study,
    out=res_out_rel_to_death,
    label=Time from Relapse to Death
);

