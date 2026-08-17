# liver-transplant-survival-analysis
R-based survival analysis workflow for liver transplant outcomes research.

# Liver Transplant Survival Analysis in R

## Overview

This project demonstrates an R-based workflow for analyzing liver transplant outcomes using survival analysis methods.

The original research project used national liver transplant registry data to evaluate outcomes after liver retransplantation among patients with autoimmune liver disease. The workflow included preparing the analytic cohort, creating derived variables, performing data quality checks, and conducting statistical analyses.

> **Note:** The original clinical dataset is not included in this public repository because it contains restricted research data. This repository is intended to demonstrate the analytical workflow and programming approach.

## Research Question

The original study examined whether autoimmune liver disease was associated with long-term graft outcomes following liver retransplantation and whether outcomes differed across autoimmune disease subtypes.

## Analytical Workflow

1. Import and prepare the data
2. Build the analytic cohort using inclusion and exclusion criteria
3. Create derived variables
4. Perform data quality checks
5. Generate descriptive statistics
6. Conduct Kaplan-Meier survival analysis
7. Perform Cox proportional hazards regression
8. Present and interpret the results

## Statistical Methods

- Descriptive statistics
- Kaplan-Meier survival analysis
- Log-rank test
- Cox proportional hazards regression

## Example Output

The Kaplan-Meier analysis below demonstrates the cumulative probability of late graft loss among adult patients in the synthetic dataset, stratified by autoimmune status.

![Kaplan-Meier Survival Curve](outputs/kaplan_meier_curve.png)

> **Note:** This visualization is based entirely on synthetic data created for portfolio demonstration purposes and does not represent actual patient outcomes.
## Programming

- R
- `dplyr`
- `survival`
- `survminer`
- `gtsummary`

## Skills Demonstrated

- Healthcare data preparation
- Analytic cohort development
- Data cleaning and validation
- Derived variable creation
- Survival analysis
- Statistical modeling
- Data visualization
- Reproducible analytical workflows

## How to Run This Project

1. Download or clone this repository.
2. Open the project folder in RStudio.
3. Make sure the `data` folder is located in the project directory.
4. Open `R/liver_transplant_analysis.R`.
5. Run the script from beginning to end.

The script uses the synthetic dataset included in the `data` folder.

## Project Notes

The original research project used restricted clinical registry data. Those data and the original patient-level information are not included in this repository.

A synthetic dataset is provided so the analytical workflow can be demonstrated and reproduced without sharing restricted clinical data.
