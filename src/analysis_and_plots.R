library(ggplot2)

# This script uses the dataset prepared by src/data.R.

# Fit the full model to examine associations while adjusting
# for platform, age, gender and sleep.
model <- lm(
  anxiety_level ~ daily_social_media_hours +
    platform_usage + age + gender + sleep_hours,
  data = data
)
# Display the full model results
print(summary(model))

# Compare this model with the full model to test the
# additional contribution of platform.
model_no_platform <- update(
  model,
  . ~ . - platform_usage
)
# Compare the models with and without platform
print(anova(model_no_platform, model))

# Calculate VIFs for the individual predictor columns
# in the model matrix.
vif_table <- function(model) {
  x <- model.matrix(model)[, -1, drop = FALSE]
  
  vifs <- sapply(seq_len(ncol(x)), function(j) {
    fit <- lm.fit(
      cbind(1, x[, -j, drop = FALSE]),
      x[, j]
    )
    
    r_squared <- 1 -
      sum(fit$residuals^2) /
      sum((x[, j] - mean(x[, j]))^2)
    
    1 / (1 - r_squared)
  })
  
  setNames(round(vifs, 2), colnames(x))
}
# Display VIF values
print(vif_table(model))

# Show residual diagnostics and restore the previous
# graphics settings afterwards.
plot_residual_checks <- function(model) {
  previous_settings <- par(mfrow = c(1, 2))
  on.exit(par(previous_settings))
  
  plot(model, which = 1:2)
}
# Display residual diagnostic plots
plot_residual_checks(model)

# Plot 1: Show the observed relationship within each platform.
# These trend lines are not adjusted for the other predictors.
p_scatter <- ggplot(
  data,
  aes(
    x = daily_social_media_hours,
    y = anxiety_level,
    colour = platform_usage
  )
) +
  geom_point(alpha = 0.25) +
  geom_smooth(method = "lm", formula = y ~ x) +
  labs(
    title = "Social media use and anxiety by platform",
    subtitle = "Lines show unadjusted trends with 95% confidence intervals",
    x = "Daily social media use (hours)",
    y = "Anxiety level (1–10)",
    colour = "Main platform"
  ) +
  theme_minimal()
# Display the scatterplot
print(p_scatter)

# Extract coefficients and their confidence intervals
# from the adjusted regression model.
coefficient_intervals <- confint(model)

coefs <- data.frame(
  term = names(coef(model)),
  estimate = unname(coef(model)),
  low = coefficient_intervals[, 1],
  high = coefficient_intervals[, 2],
  row.names = NULL
)

# Focus the plot on predictors rather than the intercept.
coefs <- coefs[coefs$term != "(Intercept)", ]


# Plot 2: Show adjusted regression coefficients.
# The dashed line marks a coefficient of zero.
p_coefs <- ggplot(
  coefs,
  aes(x = term, y = estimate)
) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    colour = "grey50"
  ) +
  geom_pointrange(
    aes(ymin = low, ymax = high)
  ) +
  coord_flip() +
  labs(
    title = "Regression coefficients for anxiety",
    x = NULL,
    y = "Regression coefficient with 95% confidence interval"
  ) +
  theme_minimal()

# Display the coefficient plot
print(p_coefs)
