%macro summary_stats_three(lib=work, var_class_ds=);

    /* Step 1: Load variable classifications (excluding 'STUDY') */
    proc sql noprint;
        select name, var_type
        into :var1-:var999, :type1-:type999
        from &lib..&var_class_ds
        where upcase(name) ne "STUDY";
        %let nvars = &sqlobs;
    quit;

    %let datasets = nwtsco nwtsco3 nwtsco4;

    /* Step 2: Initialize base tables for appending */
    data freq_all;
        length Dataset $32 Variable $64 Category $200 count percent 8;
        call missing(of _all_);
        stop;
    run;

    data stats_all;
        length Dataset $32 Variable $64 n mean stddev 8;
        call missing(of _all_);
        stop;
    run;

    /* Step 3: Loop through datasets and variables */
    %do d = 1 %to 3;
        %let ds = %scan(&datasets, &d);

        %do i = 1 %to &nvars;
            %let var = &&var&i;
            %let type = &&type&i;

            %if &type = Categorical %then %do;

                /* Get frequency table for categorical variable */
                proc freq data=&lib..&ds noprint;
                    tables &var / out=freq_tmp;
                run;

                /* Standardize and label */
                data freq_tmp;
                    length Dataset $32 Variable $64 Category $200 count percent 8;
                    set freq_tmp(keep=&var count percent);
                    Dataset = "&ds";
                    Variable = "&var";
                    Category = vvalue(&var); /* handles numeric or character categories */
                run;

                proc append base=freq_all data=freq_tmp force nowarn; run;

            %end;

            %else %if &type = Continuous %then %do;

                /* Get summary statistics */
                proc means data=&lib..&ds n mean stddev noprint;
                    var &var;
                    output out=stats_tmp(drop=_type_ _freq_) mean=mean stddev=stddev n=n;
                run;

                /* Standardize and label */
                data stats_tmp;
                    length Dataset $32 Variable $64 n mean stddev 8;
                    set stats_tmp(keep=n mean stddev);
                    Dataset = "&ds";
                    Variable = "&var";
                run;

                proc append base=stats_all data=stats_tmp force nowarn; run;

            %end;

        %end;
    %end;

    /* Step 4: Print Combined Tables */

    title "Summary Statistics for Continuous Variables Across Datasets";
    proc print data=stats_all noobs label;
        var Dataset Variable n mean stddev;
        label
            Dataset = "Dataset"
            Variable = "Variable"
            n = "N"
            mean = "Mean"
            stddev = "Standard Deviation";
    run;

    title "Frequency Tables for Categorical Variables by Dataset";
    proc print data=freq_all noobs label;
        var Dataset Variable Category count percent;
        label
            Dataset = "Dataset"
            Variable = "Variable"
            Category = "Category"
            count = "Count"
            percent = "Percent (%)";
    run;

%mend summary_stats_three;

/* Usage */
libname mydata '/home/u62057975/NWTSCO/';
%summary_stats_three(lib=mydata, var_class_ds=var_classification);
