/* Macro to categorize continuous variables: age and tumor diameter */
%macro categorize_cont(inlib=, infile=, outds=);
    data &outds;
        set &inlib..&infile;

        /* Define length for new character variable age_group */
        length age_group $10;
        /* Categorize age into clinically relevant groups for Wilms tumor */
        if age < 2 then age_group = "<2 yrs";
        else if 2 <= age <= 4 then age_group = "2–4 yrs";
        else if age > 4 then age_group = ">4 yrs";

        /* Define length for new character variable size_group */
        length size_group $10;
        /* Categorize tumor diameter into clinically meaningful size groups */
        if tumdiam < 10 then size_group = "<10 cm";
        else if 10 <= tumdiam <= 15 then size_group = "10–15 cm";
        else if tumdiam > 15 then size_group = ">15 cm";
    run;
%mend categorize_cont;

/* Call macro to create categorized dataset from original NWTSCO data */
%categorize_cont(inlib=mydata, infile=nwtsco, outds=nwtsco_categorized);

/* Macro to split dataset into subsets by study cohort */
%macro split_by_study(data=, outlib=work, prefix=);
    data &outlib..&prefix._cat &outlib..&prefix._cat3 &outlib..&prefix._cat4;
        set &data;

        /* Output full dataset with categorized variables */
        output &outlib..&prefix._cat;

        /* Output study 3 subset */
        if study = 3 then output &outlib..&prefix._cat3;
        /* Output study 4 subset */
        else if study = 4 then output &outlib..&prefix._cat4;
    run;
%mend split_by_study;

/* Split categorized dataset by study cohorts */
%split_by_study(data=nwtsco_categorized, outlib=mydata, prefix=nwtsco);

/* Assign library reference to NWTSCO data directory */
libname mydata '/home/u62057975/NWTSCO/';

/* Generate frequency and percentage distributions for combined cohort */
proc freq data=mydata.nwtsco_cat;
    tables age_group size_group /;
    title "Frequency and Percentage Distribution of Age Group and Tumor Diameter Group - All Studies";
run;

/* Generate frequency and percentage distributions for study 3 cohort */
proc freq data=mydata.nwtsco_cat3;
    tables age_group size_group /;
    title "Frequency and Percentage Distribution of Age Group and Tumor Diameter Group - Study 3";
run;

/* Generate frequency and percentage distributions for study 4 cohort */
proc freq data=mydata.nwtsco_cat4;
    tables age_group size_group /;
    title "Frequency and Percentage Distribution of Age Group and Tumor Diameter Group - Study 4";
run;





