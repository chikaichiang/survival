%macro check_trel_tsur_cross(lib=work, datasets=nwtsco nwtsco3 nwtsco4);

    /* Count the number of datasets provided in the macro call */
    %let nds = %sysfunc(countw(&datasets));

    /* Loop through each dataset */
    %do i = 1 %to &nds;
        %let ds = %scan(&datasets, &i);  /* Get the name of the i-th dataset */

        /* Create a summary table that counts how often trel ≠ tsur */
        proc sql;
            create table check_cross_&ds as
            select 
                relaps, 
                dead,
                /* Count of cases where trel and tsur are not equal */
                sum(case when trel ne tsur then 1 else 0 end) as trel_ne_tsur_count,

                /* Total number of non-missing trel and tsur observations for this group */
                count(*) as total_count,

                /* Percent where trel ≠ tsur, formatted as a percent */
                calculated trel_ne_tsur_count / calculated total_count format=percent8.2 as pct_trel_ne_tsur

            from &lib..&ds

            /* Only include observations with known relapse and death status, and non-missing time values */
            where relaps in (0,1) and dead in (0,1) and trel is not missing and tsur is not missing

            /* Group results by combinations of relaps and dead status */
            group by relaps, dead

            /* Order output for readability */
            order by relaps, dead;
        quit;

        /* Print the summary table */
        title "Check of trel ≠ tsur by relaps and dead in dataset &ds";
        proc print data=check_cross_&ds noobs label;
            var relaps dead trel_ne_tsur_count total_count pct_trel_ne_tsur;
            label 
                relaps = "Relapse Status (0=No,1=Yes)"
                dead = "Dead Status (0=Alive,1=Dead)"
                trel_ne_tsur_count = "Count trel ≠ tsur"
                total_count = "Total Obs"
                pct_trel_ne_tsur = "Percent trel ≠ tsur";
        run;
    %end;

    title; /* Clear titles after loop ends */

%mend check_trel_tsur_cross;

/* Usage */
libname mydata '/home/u62057975/NWTSCO';
%check_trel_tsur_cross(lib=mydata, datasets=nwtsco nwtsco3 nwtsco4);
