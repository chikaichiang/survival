%macro classify_vars(lib=work, dataset=, threshold=10, outds=);
    /*
    Macro: classify_vars
    Purpose: Classify numeric variables in a dataset as either 'Categorical' or 'Continuous'.
             - Variables with all integer values and unique count <= threshold are 'Categorical'.
             - Others are 'Continuous'.
    Parameters:
        lib       = Library where the dataset is stored (default: work).
        dataset   = Name of the dataset to analyze.
        threshold = Maximum number of unique values to consider a variable categorical (default: 10).
        outds     = (Optional) Output dataset to save the classification results.
    */

    /* Extract variable metadata (variable names and types) */
    proc contents data=&lib..&dataset out=varinfo(keep=name type) noprint;
    run;

    /* Select all numeric variables (type=1) and store their names in macro variable num_vars */
    proc sql noprint;
        select name into :num_vars separated by ' '
        from varinfo where type=1;
    quit;

    /* Initialize an empty dataset to store classification results */
    data var_classification;
        length name $32;
        call missing(name, unique_count, all_integer);
        stop;
    run;

    /* Count how many numeric variables to process */
    %let n=%sysfunc(countw(&num_vars));

    /* Loop through each numeric variable to analyze its properties */
    %do i=1 %to &n;
        %let var=%scan(&num_vars, &i);

        /* Calculate number of unique values for the variable */
        proc sql noprint;
            select count(distinct &var) into :uniq_val trimmed
            from &lib..&dataset;
        quit;

        /* Check if all values are integers by computing max absolute difference
           between the value and its rounded value (ignoring missing values) */
        proc sql noprint;
            select max(abs(&var - round(&var))) format=best32. into :max_diff trimmed
            from &lib..&dataset
            where &var is not null;
        quit;

        /* Create a temporary dataset with current variable's stats */
        data temp;
            length name $32;
            name="&var";
            unique_count=&uniq_val;
            all_integer=(&max_diff < 1e-8); /* 1 if all integer, else 0 */
        run;

        /* Append temporary results to the main classification dataset */
        proc append base=var_classification data=temp force; run;
    %end;

    /* Assign variable type based on integer status and unique count */
    data var_classification;
        set var_classification;
        length var_type $12;
        if all_integer=1 and unique_count <= &threshold then var_type="Categorical";
        else var_type="Continuous";
    run;

    /* If output dataset name is specified, save the classification results */
    %if %length(&outds) %then %do;
        data &outds;
            set var_classification;
        run;
    %end;

    /* Print the classification table for review */
    proc print data=var_classification noobs label;
        var name var_type unique_count all_integer;
        label 
            name = "Variable"
            var_type = "Variable Type"
            unique_count = "Unique Values"
            all_integer = "All Integer (1=Yes, 0=No)";
    run;

%mend classify_vars;


/* Example usage */
libname mydata '/home/u62057975/NWTSCO/';
%classify_vars(lib=mydata, dataset=nwtsco, threshold=10, outds=mydata.var_classification);





