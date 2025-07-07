%macro km_plot(
    data=,           /* Input dataset containing survival data */
    groupvar=,       /* Grouping variable for stratification in KM plot (e.g., treatment group) */
    timevar=,        /* Time-to-event variable */
    censorvar=,      /* Censoring indicator variable (0 = censored, 1 = event) */
    event_label=,    /* Label for the event/time used in titles and axis labels */
    outdsn=,         /* Output dataset name to save log-rank test results */
    plot=YES,        /* Flag to control whether to produce KM survival plot (YES/NO) */
    saveplotdata=NO, /* Flag to save KM plot data for further customization (YES/NO) */
    plotds=          /* Name of dataset to save KM survival plot data (used if saveplotdata=YES) */
);

    /* Local macro variable to store the PROC LIFETEST plots option */
    %local plotopt;

    /* 
    Set plots option dynamically based on user input:
    If &plot=YES (case-insensitive), enable survival plot with confidence limits,
    otherwise disable plotting.
    */
    %let plotopt = %sysfunc(ifc(%upcase(&plot)=YES, plots=survival(cl), plots=none));

    /* 
    Limit ODS output to only display the Homogeneity Tests (log-rank test results)
    to avoid clutter in output.
    */
    ods select HomTests;

    /* 
    If user wants to save the log-rank test results and KM plot data:
      - Save HomTests output to dataset &outdsn
      - Save SurvivalPlot output to dataset &plotds
    Else
      - Save only HomTests output to &outdsn
    */
    %if %upcase(&saveplotdata)=YES %then %do;
        ods output HomTests=&outdsn SurvivalPlot=&plotds;
    %end;
    %else %do;
        ods output HomTests=&outdsn;
    %end;

    /* 
    Run PROC LIFETEST to perform Kaplan-Meier survival estimation and log-rank test:
      - TIME statement defines survival time and censoring variable (0=censored)
      - STRATA statement defines groups for survival curves and tests
      - Use &plotopt to control plot generation
      - Title describes the test by group variable and event label
    */
    proc lifetest data=&data &plotopt;
        time &timevar * &censorvar(0);
        strata &groupvar;
        title "Log-Rank Test for &event_label by &groupvar";
    run;

    /* Reset ODS output selection to all for subsequent output */
    ods select all;

    /* 
    If the user requests both saving plot data and plotting:
      - Create a temporary dataset _plotds_ to customize plot labels
      - Capitalize the strata variable labels for better aesthetics
      - Use PROC SGPLOT to create a high-quality KM plot with:
          * step plot of survival curves by group with distinct colors and line patterns
          * shaded bands representing 95% confidence intervals
          * legend positioned inside bottom right
          * labeled axes with grids
          * descriptive title and footnote explaining the shaded area
    */
    %if %upcase(&saveplotdata)=YES and %upcase(&plot)=YES %then %do;

        /* Capitalize strata labels for nicer legend */
        data _plotds_;
            set &plotds;
            StratumCap = propcase(Stratum); /* Convert first letter of each word to uppercase */
        run;

        proc sgplot data=_plotds_ noborder;
            styleattrs 
                datacontrastcolors=(black blue darkred gray forestgreen darkorange) 
                datalinepatterns=(solid shortdash longdash dot shortdashdot);

            /* Survival step function plot grouped by strata */
            step x=Time y=Survival / group=StratumCap name="Surv" lineattrs=(thickness=2);

            /* Confidence interval band with transparency */
            band x=Time lower=SDF_LCL upper=SDF_UCL / group=StratumCap transparency=0.4 fillattrs=(color=lightgray);

            /* Legend for survival curves */
            keylegend "Surv" / location=inside position=bottomleft across=1;

            /* X and Y axis labels with grids */
            xaxis label="&event_label Time (Years)" grid;
            yaxis label="Survival Probability" values=(0 to 1 by 0.1) grid;

            /* Plot title */
            title "Kaplan-Meier Curve for &event_label by %sysfunc(propcase(&groupvar))";

            /* Footnote to explain shaded confidence interval */
            footnote j=l "Shaded area represents 95% confidence interval.";
        run;

    %end;

%mend;



/* Assign library to dataset location */
libname mydata '/home/u62057975/NWTSCO/';

%km_plot(
    data=mydata.nwtsco_cat,                  /* Input dataset */
    groupvar=study,                      /* Stratification variable */
    timevar=trel,                        /* Time to event */
    censorvar=relaps,                    /* Censoring variable (0 = censored) */
    event_label=Time to Relapse,         /* Label for the plot title */
    outdsn=RelapseTest,                  /* Output dataset for log-rank test */
    plot=YES,                            /* Show plot */
    saveplotdata=YES,                    /* Save plot data */
    plotds=RelapseKM                     /* Name of the plot dataset */
);

%km_plot(
    data=mydata.nwtsco_cat,                  /* Input dataset */
    groupvar=study,                      /* Stratification variable */
    timevar=tsur,                        /* Time to event */
    censorvar=dead,                    /* Censoring variable (0 = censored) */
    event_label=Time to Death,         /* Label for the plot title */
    outdsn=DeathTest,                  /* Output dataset for log-rank test */
    plot=YES,                            /* Show plot */
    saveplotdata=YES,                    /* Save plot data */
    plotds=DeathKM                     /* Name of the plot dataset */
);

/* Prepare dataset for time between relapse and death analysis */
data nwtsco_rel_to_death;
    set mydata.nwtsco_cat;
    where relaps = 1 and tsur >= trel;  /* Include only patients who relapsed before death */
    
    time_diff = tsur - trel;            /* Calculate time interval from relapse to death */
    event_between = dead;               /* Event indicator for death in this interval */
run;

%km_plot(
    data=nwtsco_rel_to_death,                  /* Input dataset */
    groupvar=study,                      /* Stratification variable */
    timevar=time_diff,                        /* Time to event */
    censorvar=event_between,                    /* Censoring variable (0 = censored) */
    event_label=Time from Relpase to Death,         /* Label for the plot title */
    outdsn=RelapseToDeathTest,                  /* Output dataset for log-rank test */
    plot=YES,                            /* Show plot */
    saveplotdata=YES,                    /* Save plot data */
    plotds=RelapseToDeathKM                     /* Name of the plot dataset */
);

