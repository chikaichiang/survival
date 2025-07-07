/* Macro to import a CSV file into a specified SAS library and dataset */
%macro import_csv(filename=, dataset=, lib=work);
    proc import datafile="&filename"   /* Path to the CSV file to import */
        out=&lib..&dataset             /* Output dataset name with library reference */
        dbms=csv                      /* Specify that the input file is CSV format */
        replace;                     /* Replace existing dataset if it exists */
        guessingrows=MAX;             /* Scan all rows to guess variable types accurately */
    run;
%mend;

/* Define a permanent SAS library named 'mydata' pointing to the NWTSCO directory */
libname mydata '/home/u62057975/NWTSCO/';

/* Call the import macro to load the CSV file into the 'mydata' library */
%import_csv(filename=/home/u62057975/NWTSCO/nwtsco.csv, dataset=nwtsco, lib=mydata);

/* Print the first 10 observations of the imported dataset for verification */
proc print data=mydata.nwtsco(obs=10); 
run;



