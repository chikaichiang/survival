%macro recode_ref(input=, output=, var=, ref=, outvar=, prefix=Z_);
	
	/* Macro to recode a categorical variable so that a specified reference level is sorted last alphabetically.
    This is useful in modeling procedures (like PROC LIFEREG) where the reference level is automatically
    determined by sorting order (e.g., last level in alphabetical order). */

    data &output;
        set &input;

        /* Define new character variable with fixed length */
        length &outvar $10;

        /* If the value matches the reference level, prepend prefix to push it last in sort order */
        if &var = "&ref" then &outvar = "&prefix.&ref";

        /* Otherwise, retain original value */
        else &outvar = &var;
    run;

%mend;


/* Assign a library reference to your dataset location */
libname mydata '/home/u62057975/NWTSCO/';

/* Recode 'stage' so that value 1 becomes reference (appears last alphabetically via prefix "Z_") */
%recode_ref(
  input=mydata.nwtsco_cat,
  output=mydata.nwtsco_cat_ordered,
  var=stage,
  ref=1,
  outvar=stage_ordered
);

/* Recode 'age_group' so that "<2 yrs" is reference */
%recode_ref(
  input=mydata.nwtsco_cat_ordered,
  output=mydata.nwtsco_cat_ordered,
  var=age_group,
  ref=%str(<2 yrs),
  outvar=age_group_ordered
);

/* Recode 'size_group' so that "<10 cm" is reference */
%recode_ref(
  input=mydata.nwtsco_cat_ordered,
  output=mydata.nwtsco_cat_ordered,
  var=size_group,
  ref=%str(<10 cm),
  outvar=size_group_ordered
);

/* Recode 'histol' so that value 0 is reference */
%recode_ref(
  input=mydata.nwtsco_cat_ordered,
  output=mydata.nwtsco_cat_ordered,
  var=histol,
  ref=0,
  outvar=histol_ordered
);
