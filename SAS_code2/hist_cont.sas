/* Macro to generate histogram with density curve */
%macro plot_histogram(data=, var=);

    /* Set default x-axis label based on variable name, capitalized */
    %let xlabel = %sysfunc(propcase(&var));

    /* Customize x-axis label for known variables with units */
    %if %upcase(&var) = TUMDIAM %then %let xlabel = Tumor Diameter (cm);
    %else %if %upcase(&var) = AGE %then %let xlabel = Age at Diagnosis (years);

    /* Begin plot: suppress automatic legend to keep figure clean */
    proc sgplot data=&data noautolegend;

        /* Plot histogram with solid steelblue bars (no transparency) */
        histogram &var / fillattrs=(color=steelblue transparency=0.0);

        /* Overlay kernel density curve in red for smooth distribution shape */
        density &var / type=kernel lineattrs=(color=red thickness=1.5);

        /* Configure x-axis: proper label with formatting, hint for good tick marks, and grid lines */
        xaxis label="&xlabel"
              labelattrs=(weight=normal size=10pt)
              valueshint
              grid;

        /* Configure y-axis: label and light grid lines for frequency count */
        yaxis label="Frequency"
              labelattrs=(weight=normal size=10pt)
              grid;

        /* Remove title for cleaner, figure-caption-driven plots (e.g., for JASA submission) */
        title;

    run;
%mend plot_histogram;

/* Assign library to dataset location */
libname mydata '/home/u62057975/NWTSCO/';

/* Tumor diameter in cm */
%plot_histogram(data=mydata.nwtsco, var=tumdiam);

/* Age at diagnosis in years */
%plot_histogram(data=mydata.nwtsco, var=age);



