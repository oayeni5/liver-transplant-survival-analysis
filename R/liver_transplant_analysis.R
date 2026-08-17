# ============================================================
# Liver Transplant Outcomes: R Survival Analysis Workflow
# Portfolio Project
# Oluwakemi Ayeni
# ============================================================

# This project demonstrates an R-based workflow for preparing
# liver transplant data and conducting survival analyses.
#
# The original research used restricted clinical registry data.
# This public portfolio version uses synthetic data and does not
# contain patient-level data or original diagnosis-code mappings.


# ============================================================
# 1. Load Packages
# ============================================================

library(dplyr)
library(survival)
library(survminer)
library(gtsummary)


# ============================================================
# 2. Import Synthetic Data
# ============================================================

# Synthetic data are used so the complete workflow can be
# demonstrated without sharing restricted clinical data.

liver_data <- read.csv(
  "data/synthetic_liver_transplant_data.csv"
)

# Convert date variables to R date format
liver_data <- liver_data %>%
  mutate(
    TX_DATE = as.Date(TX_DATE),
    FOLLOWUP_DATE = as.Date(FOLLOWUP_DATE)
  )


# ============================================================
# 3. Build Analysis Cohort
# ============================================================

# Keep records with a transplant date
liver_tx <- liver_data %>%
  filter(!is.na(TX_DATE))


# Sort records by patient and transplant date,
# then keep the first transplant for each patient
first_lt <- liver_tx %>%
  arrange(PATIENT_ID, TX_DATE) %>%
  group_by(PATIENT_ID) %>%
  slice(1) %>%
  ungroup()


# Exclude patients with a previous transplant
primary_lt <- first_lt %>%
  filter(PREVIOUS_TRANSPLANT == 0)


# Restrict the cohort to the study period
study_period <- primary_lt %>%
  filter(
    TX_DATE >= as.Date("2002-03-01"),
    TX_DATE <= as.Date("2021-12-31")
  )


# ============================================================
# 4. Create Derived Variables
# ============================================================

analysis_data <- study_period %>%
  mutate(

    # Autoimmune liver disease indicator
    Autoimmune = case_when(
      DISEASE_GROUP %in% c("PBC", "PSC", "AIH") ~ 1,
      DISEASE_GROUP == "Other" ~ 0,
      TRUE ~ NA_real_
    ),

    # Pediatric/adult indicator
    ped = case_when(
      AGE < 18 ~ 1,
      AGE >= 18 ~ 0,
      TRUE ~ NA_real_
    ),

    # Follow-up time in years
    followup_years =
      as.numeric(
        difftime(
          FOLLOWUP_DATE,
          TX_DATE,
          units = "days"
        )
      ) / 365.25,

    # BMI category
    bmicat = case_when(
      BMI < 18.5 ~ 1,
      BMI >= 18.5 & BMI < 25 ~ 2,
      BMI >= 25 & BMI < 30 ~ 3,
      BMI >= 30 & BMI < 35 ~ 4,
      BMI >= 35 ~ 5,
      TRUE ~ NA_real_
    ),

    # Diabetes indicator
    diabetes = case_when(
      DIABETES == "Yes" ~ 1,
      DIABETES == "No" ~ 0,
      TRUE ~ NA_real_
    ),

    # Dialysis indicator
    dialysis = case_when(
      DIALYSIS == "Yes" ~ 1,
      DIALYSIS == "No" ~ 0,
      TRUE ~ NA_real_
    ),

    # Simultaneous liver-kidney transplant indicator
    slk = case_when(
      SLK == "Yes" ~ 1,
      SLK == "No" ~ 0,
      TRUE ~ NA_real_
    )
  )


# ============================================================
# 5. Data Quality Checks
# ============================================================

# Review the size of the final analytic cohort
nrow(analysis_data)


# Review selected categorical variables
qc_vars <- c(
  "DISEASE_GROUP",
  "Autoimmune",
  "ped",
  "GENDER",
  "RACE_ETHNICITY",
  "bmicat",
  "diabetes",
  "dialysis",
  "slk",
  "LATE_GRAFT_LOSS"
)


qc_tables <- lapply(qc_vars, function(v) {
  table(
    analysis_data[[v]],
    useNA = "ifany"
  )
})

names(qc_tables) <- qc_vars

qc_tables


# Review continuous variables
summary(analysis_data$AGE)
summary(analysis_data$BMI)
summary(analysis_data$followup_years)


# Check for impossible follow-up values
analysis_data %>%
  filter(followup_years < 0)


# ============================================================
# 6. Prepare Readable Labels
# ============================================================

analysis_data_labeled <- analysis_data %>%
  mutate(

    Autoimmune = factor(
      Autoimmune,
      levels = c(0, 1),
      labels = c(
        "Non-autoimmune",
        "Autoimmune"
      )
    ),

    ped = factor(
      ped,
      levels = c(0, 1),
      labels = c(
        "Adult",
        "Pediatric"
      )
    ),

    bmicat = factor(
      bmicat,
      levels = c(1, 2, 3, 4, 5),
      labels = c(
        "<18.5",
        "18.5-24.9",
        "25-29.9",
        "30-34.9",
        ">=35"
      )
    ),

    diabetes = factor(
      diabetes,
      levels = c(0, 1),
      labels = c("No", "Yes")
    ),

    dialysis = factor(
      dialysis,
      levels = c(0, 1),
      labels = c("No", "Yes")
    ),

    slk = factor(
      slk,
      levels = c(0, 1),
      labels = c("No", "Yes")
    )
  )


# ============================================================
# 7. Descriptive Statistics
# ============================================================

# Generate baseline characteristics by autoimmune status
tbl1 <- analysis_data_labeled %>%
  select(
    Autoimmune,
    AGE,
    ped,
    GENDER,
    RACE_ETHNICITY,
    bmicat,
    diabetes,
    dialysis,
    slk,
    LATE_GRAFT_LOSS,
    followup_years
  ) %>%

  tbl_summary(
    by = Autoimmune,

    statistic = list(
      all_continuous() ~
        "{median} ({p25}, {p75})"
    ),

    label = list(
      AGE ~ "Recipient Age (years)",
      ped ~ "Pediatric Status",
      GENDER ~ "Gender",
      RACE_ETHNICITY ~ "Race/Ethnicity",
      bmicat ~ "BMI Category",
      diabetes ~ "Diabetes",
      dialysis ~ "Dialysis",
      slk ~ "Simultaneous Liver-Kidney Transplant",
      LATE_GRAFT_LOSS ~ "Late Graft Loss",
      followup_years ~ "Follow-up Time (years)"
    )
  ) %>%

  add_p()

tbl1


# ============================================================
# 8. Kaplan-Meier Survival Analysis
# ============================================================

# Restrict this example to adult patients
km_adults <- analysis_data_labeled %>%
  filter(ped == "Adult")


# Fit Kaplan-Meier model
km_fit_adults <- survfit(
  Surv(
    followup_years,
    LATE_GRAFT_LOSS
  ) ~ Autoimmune,
  data = km_adults
)


# Plot cumulative probability of late graft loss
ggsurvplot(
  km_fit_adults,
  data = km_adults,
  fun = "event",
  risk.table = TRUE,
  pval = TRUE,
  conf.int = TRUE,

  title =
    "Late Graft Loss in Adults by Autoimmune Status",

  xlab =
    "Time Since Transplant (Years)",

  ylab =
    "Probability of Late Graft Loss",

  legend.title = "",

  legend.labs = c(
    "Non-autoimmune",
    "Autoimmune"
  )
)


# ============================================================
# 9. Cox Proportional Hazards Regression
# ============================================================

# Prepare categorical variables and reference groups
cox_data <- analysis_data %>%
  mutate(

    DISEASE_GROUP = factor(
      DISEASE_GROUP,
      levels = c(
        "Other",
        "PBC",
        "PSC",
        "AIH"
      )
    ),

    GENDER = factor(
      GENDER
    ),

    bmicat = factor(
      bmicat,
      levels = c(2, 1, 3, 4, 5),
      labels = c(
        "18.5-24.9",
        "<18.5",
        "25-29.9",
        "30-34.9",
        ">=35"
      )
    ),

    diabetes = factor(
      diabetes,
      levels = c(0, 1),
      labels = c("No", "Yes")
    ),

    dialysis = factor(
      dialysis,
      levels = c(0, 1),
      labels = c("No", "Yes")
    ),

    slk = factor(
      slk,
      levels = c(0, 1),
      labels = c("No", "Yes")
    )
  )


# ============================================================
# 10. Univariable Cox Regression
# ============================================================

tbl_uv <- tbl_uvregression(
  data = cox_data,
  method = coxph,

  y = Surv(
    followup_years,
    LATE_GRAFT_LOSS
  ),

  include = c(
    DISEASE_GROUP,
    AGE,
    GENDER,
    bmicat,
    diabetes,
    dialysis,
    slk
  ),

  exponentiate = TRUE
)

tbl_uv


# ============================================================
# 11. Multivariable Cox Regression
# ============================================================

cox_model_multivariable <- coxph(

  Surv(
    followup_years,
    LATE_GRAFT_LOSS
  ) ~

    DISEASE_GROUP +
    AGE +
    bmicat +
    diabetes +
    dialysis +
    slk,

  data = cox_data
)


# Create formatted multivariable regression table
tbl_mv <- tbl_regression(
  cox_model_multivariable,
  exponentiate = TRUE
)

tbl_mv


# ============================================================
# 12. Combine Cox Regression Results
# ============================================================

tbl_joint <- tbl_merge(

  tbls = list(
    tbl_uv,
    tbl_mv
  ),

  tab_spanner = c(
    "**Univariable Cox Regression**",
    "**Multivariable Cox Regression**"
  )
)

tbl_joint
