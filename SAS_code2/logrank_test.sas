%macro logrank_test(data=, groupvar=, timevar=, censorvar=, event_label=, outdsn=, plot=YES);
    /* 
       Macro: logrank_test
       Purpose: Perform Kaplan-Meier survival analysis and Log-Rank test comparing groups.
       Parameters:
         data      = Input dataset containing survival data
         groupvar  = Grouping variable for comparison (strata)
         timevar   = Time-to-event variable
         censorvar = Censoring indicator variable (0 = censored)
         event_label = Label describing the event/time for the plot title
         outdsn    = Output dataset to store homogeneity (log-rank) test results
         plot      = Option to generate survival plot (YES/NO)
    */
    
    %if %upcase(&plot) = YES %then %do;
        ods select HomTests; /* Show only homogeneity test output, suppress other default outputs */
        
        proc lifetest data=&data plots=survival;
            time &timevar * &censorvar(0);  /* Specify time and censoring variable */
            strata &groupvar;               /* Stratify by grouping variable */
            title "Log-Rank Test for &event_label by &groupvar";
            
            ods output HomTests=&outdsn;    /* Capture homogeneity test results in output dataset */
        run;
        
        ods select all; /* Reset ODS output selection to default */
    %end;
    %else %do;
        ods select HomTests; /* Show only homogeneity test output */
        
        proc lifetest data=&data plots=none;
            time &timevar * &censorvar(0);
            strata &groupvar;
            title "Log-Rank Test for &event_label by &groupvar";
            
            ods output HomTests=&outdsn;
        run;
        
        ods select all; /* Reset ODS output selection */
    %end;
%mend logrank_test;
             
/* Run Log-Rank test for time to relapse by study, no plot */
%logrank_test(
    data=mydata.nwtsco_cat,
    groupvar=study,
    timevar=trel,
    censorvar=relaps,
    event_label=Time to Relapse,
    outdsn=RelapseTest,
    plot=NO
);

/* Run Log-Rank test for time to death by study, no plot */
%logrank_test(
    data=mydata.nwtsco_cat,
    groupvar=study,
    timevar=tsur,
    censorvar=dead,
    event_label=Time to Death,
    outdsn=DeathTest,
    plot=NO
);

/* Prepare dataset for time between relapse and death analysis */
data nwtsco_rel_to_death;
    set mydata.nwtsco_cat;
    where relaps = 1 and tsur > trel;  /* Include only patients who relapsed before death */
    
    time_diff = tsur - trel;            /* Calculate time interval from relapse to death */
    event_between = dead;               /* Event indicator for death in this interval */
run;

/* Run Log-Rank test for time from relapse to death by study, no plot */
%logrank_test(
    data=nwtsco_rel_to_death,
    groupvar=study,
    timevar=time_diff,
    censorvar=event_between,
    event_label=Time from Relapse to Death,
    outdsn=RelapseToDeathTest,
    plot=NO
);



/* Run Log-Rank test for time to relapse by study, no plot */
%logrank_test(
    data=mydata.nwtsco_cat,
    groupvar=study,
    timevar=trel,
    censorvar=relaps,
    event_label=Time to Relapse,
    outdsn=RelapseTest,
    plot=NO
);

/* Run Log-Rank test for time to death by study, no plot */
%logrank_test(
    data=mydata.nwtsco_cat,
    groupvar=study,
    timevar=tsur,
    censorvar=dead,
    event_label=Time to Death,
    outdsn=DeathTest,
    plot=NO
);

/* Prepare dataset for time between relapse and death analysis */
data nwtsco_rel_to_death;
    set mydata.nwtsco_cat;
    where relaps = 1 and tsur > trel;  /* Include only patients who relapsed before death */
    
    time_diff = tsur - trel;            /* Calculate time interval from relapse to death */
    event_between = dead;               /* Event indicator for death in this interval */
run;

/* Run Log-Rank test for time from relapse to death by study, no plot */
%logrank_test(
    data=nwtsco_rel_to_death,
    groupvar=study,
    timevar=time_diff,
    censorvar=event_between,
    event_label=Time from Relapse to Death,
    outdsn=RelapseToDeathTest,
    plot=NO
);



