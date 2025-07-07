%macro split_by_study(lib=work, dataset=nwtsco);
    /* Create subset dataset for study=3 */
    data &lib..nwtsco3;
        set &lib..&dataset;      /* Read original dataset from specified library */
        if study = 3;            /* Keep only records where study equals 3 */
    run;

    /* Create subset dataset for study=4 */
    data &lib..nwtsco4;
        set &lib..&dataset;      /* Read original dataset from specified library */
        if study = 4;            /* Keep only records where study equals 4 */
    run;
%mend split_by_study;

/* Assign library reference to the folder containing NWTSCO dataset */
libname mydata '/home/u62057975/NWTSCO/';

/* Call the macro to split nwtsco dataset stored in mydata library */
%split_by_study(lib=mydata, dataset=nwtsco);

/* Display first 5 observations of subset nwtsco3 */
proc print data=mydata.nwtsco3(obs=5); run;

/* Display first 5 observations of subset nwtsco4 */
proc print data=mydata.nwtsco4(obs=5); run;

