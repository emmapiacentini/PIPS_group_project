# PIPS_group_project (Focusing on anxiety risk)

This repository contains an analysis of how daily social media use and main platform relate to teenage anxiety, controlling for age, gender and sleep, plus an interactive Shiny app that turns the results into an individual anxiety risk estimate. We created it for our group project in the Programming in Psychological Science course of the Research Master Psychology at the University of Amsterdam.

The project fits and checks a linear regression (with a test of platform as a whole, collinearity checks and residual plots), visualises the results, and lets users explore the models in a Shiny app: you enter your daily social media use and sleep and see your predicted anxiety score, risk band and probability of high anxiety.

> **Note:** the app is an educational tool, not a diagnostic instrument. It reflects associations in one cross-sectional dataset, not causes.

## Citation

```text
[Beekhani, S. (n.d.). Teen social media usage & mental health [Data set]. Kaggle. Retrieved October 19, 2026, from https://www.kaggle.com/datasets/sureshbeekhani/teen-social-media-usage-and-mental-health]
```
## Getting started

Clone the repository:

```bash
git clone <your-repository-url>
cd pips-anxiety-risk
```

The project requires R 4.1 or newer; RStudio is recommended. Install the required packages once:

```r
install.packages(c("ggplot2", "shiny", "knitr", "rmarkdown"))
```

Open `main.Rmd` in RStudio (with the repository folder as working directory) and run its chunks from top to bottom, or knit it. The Shiny chunk is only evaluated when run interactively and is skipped while knitting. Stop the app before running the remaining chunks.

## Repository structure

```text
pips-anxiety-risk/
├── data/
│   └── Teen_Mental_Health_Dataset.csv   # teenagers, 12 variables
├── src/
│   ├── data.R                 # load packages, read and prepare the data
│   ├── analysis_and_plots.R   # regression, checks and plots
│   └── app.R                  # reduced models, risk estimates and Shiny app
├── main.Rmd                   # main deliverable
└── README.md
```
## Using the project

`main.Rmd` guides you through:

1. Loading and describing the data.
2. Fitting `anxiety_level ~ daily_social_media_hours + platform_usage + age + gender + sleep_hours` and interpreting it, including a nested F test for platform, variance inflation factors and residual plots.
3. Two plots: anxiety against social media hours by platform, and a coefficient plot.
4. Fitting the reduced models behind the app (social media hours + sleep) and example risk predictions.
5. Launching the Shiny app.

The app can also be started outside the document, from the repository root:

```bash
Rscript -e 'source("src/data.R"); shiny::runApp(source("src/app.R")$value, launch.browser = TRUE)'
```
Risk bands are defined on the predicted 1-10 anxiety score: 1-3 low, 4-6 moderate, 7-10 high. These are conventions of this project, not clinical cut-offs.

## Dependencies

R packages: ggplot2 (figures), shiny (app), knitr and rmarkdown (main document). All statistics (linear and logistic regression, nested F test, variance inflation factors) use base R.

## Data

`data/Teen_Mental_Health_Dataset.csv` contains age, gender, daily social media hours, main platform, sleep hours, screen time before sleep, academic performance, physical activity, social interaction level, stress level, anxiety level (1-10) and depression risk. The analysis uses age, gender, daily social media hours, platform, sleep hours and anxiety level.

```text
[https://www.kaggle.com/datasets/sureshbeekhani/teen-social-media-usage-and-mental-health]
```
## Limitations

The data are cross-sectional, so the results are associations and not causal effects. The dataset's relationships are unusually clean (for example, platform has no association with anxiety), so it may be simulated; treat the results as a demonstration of the method.

## References

Keles, B., McCrae, N., & Grealish, A. (2020). A systematic review: The influence of social media on depression, anxiety and psychological distress in adolescents. *International Journal of Adolescence and Youth, 25*(1), 79-93. https://doi.org/10.1080/02673843.2019.1590851

Orben, A., & Przybylski, A. K. (2019). The association between adolescent well-being and digital technology use. *Nature Human Behaviour, 3*, 173-182. https://doi.org/10.1038/s41562-018-0506-1

Woods, H. C., & Scott, H. (2016). #Sleepyteen: Social media use in adolescence is associated with poor sleep quality, anxiety, depression and low self-esteem. *Journal of Adolescence, 51*, 41-49. https://doi.org/10.1016/j.adolescence.2016.05.008

