libname mydata '/home/u62057975/NWTSCO';


/**********************************************************************************************
  Macro: exploratory_assoc_plots
  
  Purpose:
  --------
  This macro performs exploratory pairwise association analyses among mixed variable types 
  (continuous, ordinal, and categorical) in a given dataset. It calculates and visualizes:

    1. Spearman correlations for continuous and ordinal variables
    2. Chi-square statistics for categorical variable pairs
    3. Point-biserial (Pearson) correlations for continuous vs binary variables

  These analyses assist in assessing predictor redundancy and guide covariate selection 
  for multivariable modeling in survival and multi-state analyses.

  Input Parameters:
  -----------------
  data = <libname.dataset>  
        The input dataset containing the variables of interest. This dataset must contain 
        the following variables (with or without these exact names):

          - age, specwgt, tumdiam, stage, study, instit, histol

  Variable Renaming Inside Macro:
  ------------------------------
  The macro renames variables internally to standardized names for clarity and consistency:

    age              -> age_at_diagnosis (continuous)
    specwgt          -> specimen_weight  (continuous)
    tumdiam          -> tumor_diameter   (continuous)
    stage            -> tumor_stage      (ordinal)
    study            -> study_group      (binary/categorical)
    instit           -> institutional_histology (categorical)
    histol           -> central_path_histology (categorical)

  Methodology:
  ------------
  - Spearman correlations calculated using PROC CORR with SPEARMAN option for continuous/ordinal pairs.
  - Chi-square tests calculated via PROC FREQ for categorical pairs.
  - Point-biserial correlations calculated as Pearson correlations between continuous and binary variables.
  - For visualization, ranked horizontal bar plots are generated using PROC SGPLOT with data sorted by 
    absolute values of association statistics, coloring bars by association type.

  Outputs:
  --------
  - Three horizontal bar plots showing ranked association strengths for:
      * Continuous/ordinal variables (Spearman correlations)
      * Categorical variables (Chi-square statistics)
      * Continuous vs binary variables (Point-biserial correlations)

  Usage Example:
  --------------
    %exploratory_assoc_plots(data=mydata.nwtsco);

**********************************************************************************************/

%macro exploratory_assoc_plots(data=);

  %local lib ds;
  %let lib = %scan(&data,1,'.');
  %let ds  = %scan(&data,2,'.');

  /*---------------------------------------------------------
   Step 1: Rename Variables for Clarity and Consistency
  ---------------------------------------------------------*/
  data work.nwts;
    set &data(rename=(
      age     = age_at_diagnosis
      specwgt = specimen_weight
      tumdiam = tumor_diameter
      stage   = tumor_stage
      study   = study_group
      instit  = institutional_histology
      histol  = central_path_histology
    ));
  run;

  ods exclude all;

  /*---------------------------------------------------------
   Step 2: Spearman Correlation - Continuous and Ordinal Variables
  ---------------------------------------------------------*/
  proc corr data=work.nwts spearman noprob outp=work.spearman_raw;
    var age_at_diagnosis specimen_weight tumor_diameter tumor_stage;
  run;

  data work.spearman;
    set work.spearman_raw;
    if _TYPE_ = "CORR" and _NAME_ ne "";
    array vars {*} age_at_diagnosis specimen_weight tumor_diameter tumor_stage;
    do i = 1 to dim(vars);
      var2 = vname(vars[i]);
      if _NAME_ < var2 then do;
        pair = catx(" — ", _NAME_, var2);
        stat = vars[i];
        abs_stat = abs(stat);
        output;
      end;
    end;
    keep pair stat abs_stat;
  run;

  /*---------------------------------------------------------
   Step 3: Chi-Squared Test for Associations Among Categorical Variables
  ---------------------------------------------------------*/
  ods output ChiSq=work.chisq_raw;
  proc freq data=work.nwts;
    tables study_group*institutional_histology
           study_group*central_path_histology
           study_group*tumor_stage
           institutional_histology*central_path_histology
           institutional_histology*tumor_stage
           central_path_histology*tumor_stage / chisq;
  run;

  data work.chisq;
    set work.chisq_raw(where=(Statistic="Chi-Square"));
    length pair_label $50;
    length table_clean $50;
    table_clean = tranwrd(Table, 'Table', '');
    pair_label = cats(scan(table_clean, 1, "*"), " — ", scan(table_clean, 2, "*"));
    stat = Value;
    abs_stat = abs(stat);
    keep pair_label stat abs_stat;
  run;

  /*---------------------------------------------------------
   Step 4: Point-Biserial Correlation (Pearson) Between Continuous and Binary Variables
  ---------------------------------------------------------*/
  proc corr data=work.nwts pearson noprob outp=work.pb_raw;
    var age_at_diagnosis specimen_weight tumor_diameter;
    with study_group institutional_histology central_path_histology;
  run;

  data work.pointbiserial;
    set work.pb_raw;
    if _TYPE_ = "CORR" and _NAME_ ne "";
    length pair $50;
    array cont_vars {*} age_at_diagnosis specimen_weight tumor_diameter;
    do i = 1 to dim(cont_vars);
      pair = catx(" — ", _NAME_, vname(cont_vars[i]));
      stat = cont_vars[i];
      abs_stat = abs(stat);
      output;
    end;
    keep pair stat abs_stat;
  run;

  ods exclude none;

  /*---------------------------------------------------------
   Step 5: Visualizations - Ranked Horizontal Bar Plots for Each Association Type
  ---------------------------------------------------------*/

  /* Spearman Correlations */
  proc sort data=work.spearman out=work.spearman_sorted;
    by descending abs_stat;
  run;

  proc sgplot data=work.spearman_sorted;
    hbar pair / response=stat datalabel datalabelattrs=(size=8)
                fillattrs=(color=CX4682B4) barwidth=0.6;
    yaxis display=(nolabel) discreteorder=data;
    xaxis label="Spearman Correlation";
    title "Ranked Spearman Correlations (Continuous/Ordinal Variables)";
  run;

  /* Chi-Square Associations */
  proc sort data=work.chisq out=work.chisq_sorted;
    by descending abs_stat;
  run;

  proc sgplot data=work.chisq_sorted;
    title "Ranked Chi-Square Associations for Categorical Predictors";
    hbar pair_label / response=stat datalabel datalabelattrs=(size=8)
                     fillattrs=(color=CXCD5C5C) barwidth=0.6;
    yaxis display=(nolabel) discreteorder=data;
    xaxis label="Chi-Square Statistic";
  run;

  /* Point-Biserial Correlations */
  proc sort data=work.pointbiserial out=work.pb_sorted;
    by descending abs_stat;
  run;

  proc sgplot data=work.pb_sorted;
    hbar pair / response=stat datalabel datalabelattrs=(size=8)
                fillattrs=(color=CX6BAE44) barwidth=0.6;
    yaxis display=(nolabel) discreteorder=data;
    xaxis label="Point-Biserial (Pearson) Correlation";
    title "Ranked Point-Biserial Correlations (Continuous vs Binary)";
  run;

%mend exploratory_assoc_plots;

%exploratory_assoc_plots(data=mydata.nwtsco);

