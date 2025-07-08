# Comparing Clinical Trajectories in Wilms Tumor: Multi-State Additive Hazards Models from NWTS-3 and NWTS-4

# 1. Cohort Characterization and Feature Engineering

Performed descriptive analysis of NWTS-3 and NWTS-4 cohorts; identified cohort-specific differences in relapse and post-relapse mortality, reflecting historical treatment improvements.

Categorized tumor diameter (<10 cm, 10–15 cm, >15 cm) and age at diagnosis (<2, 2–4, >4 years) based on nonlinear associations with outcomes; retained histology and stage as categorical predictors.

Created combined and stratified cohorts for downstream modeling to capture both cross-era effects and within-cohort dynamics.

# 2. Cox Proportional Hazards and Model Diagnostics

Fit Cox models to assess time-to-event outcomes (relapse, death, post-relapse death); used AIC comparisons and diagnostic plots to evaluate model adequacy.

Detected major violations of the proportional hazards assumption using Schoenfeld residuals, especially for histology and stage; supported by non-parallel Kaplan–Meier plots and time-varying coefficient trends.

# 3. Transition to Accelerated Failure Time (AFT) Models

Adopted AFT models to relax proportional hazards assumptions and directly model survival times.

Selected best-fit distributions using BIC: log-normal for relapse, gamma for time to death, log-normal for post-relapse death.

Identified unfavorable histology and advanced stage as strongest risk factors; protective effects of younger age were cohort-specific; tumor size had limited or inconsistent impact.

# 4. Modeling Time-Varying Covariate Effects with Additive Hazards

Applied Aalen’s additive hazards model to account for covariates with time-varying effects.

Validated significance of time-varying behavior using supremum and Kolmogorov–Smirnov tests.

Found dynamic risk profiles for histology, stage, and age over time; tumor size consistently non-significant across models.

# 5. Multi-State Additive Hazards Modeling

Implemented a three-state illness-death model capturing transitions:
• 1→2 (relapse)
• 1→3 (direct death)
• 2→3 (death after relapse)

Jointly modeled competing and sequential risks to reflect clinical disease progression and capture interdependence between events.

Discovered transition-specific effects: histology most severe for post-relapse death (2→3), stage most impactful on direct death (1→3), and age protective only for early relapse (1→2).

# 6. Simulation and Risk Profile Visualization

Defined ten clinically representative covariate profiles varying in age, tumor size, stage, and histology.

Simulated state occupancy probabilities, revealing cohort differences in time spent relapse-free, relapsed, or deceased.

Visualized transition probabilities and cumulative incidence functions (CIFs) to show event-specific risks over time and highlight treatment-era improvements from NWTS-3 to NWTS-4.

# 7. Clinical and Statistical Interpretation

CIFs confirmed dominant role of unfavorable histology, showing >90% post-relapse mortality and elevated relapse/direct death risks.

Found reduced relapse and direct death in NWTS-4 for favorable histology and early-stage disease, indicating therapeutic progress.

Showed that age and tumor size had complex, sometimes paradoxical effects depending on cohort and transition pathway.

Identified older children with unfavorable histology as a persistently high-risk group in both studies, highlighting unmet clinical needs.

# 8. Reporting and Visualization Outputs

Generated comprehensive tables (e.g., AIC/BIC comparisons, survival model estimates, nonparametric test results) and visualizations (Kaplan–Meier curves, additive hazard plots, state occupancy and CIF curves).

Synthesized findings across modeling approaches to produce a cohesive interpretation of disease progression, treatment response, and risk evolution in Wilms tumor.
