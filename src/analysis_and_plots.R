install.packages("ggplot2")
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

#Plot 1: Show the observed relationship within each platform.
platform_colours <- c(Other = "#999999", Both = "#009E73", Instagram = "#CC79A7", TikTok = "#0072B2")

p_scatter <- ggplot(data, aes(daily_social_media_hours, anxiety_level,
                              colour = platform_usage, fill = platform_usage)) +
  geom_jitter(height = 0.3, width = 0.05, alpha = 0.18, size = 0.8) +
  geom_smooth(method = "lm", formula = y ~ x, linewidth = 1.1, alpha = 0.25) +
  facet_wrap(~ platform_usage, ncol = 2) +
  scale_colour_manual(values = platform_colours) +
  scale_fill_manual(values = platform_colours) +
  scale_x_continuous(breaks = 1:8) +
  scale_y_continuous(breaks = 1:10) +
  labs(
    title = "Anxiety rises with social media use, whichever platform teens use most",
    subtitle = paste0("Each dot is one teenager (n = ", nrow(data), "); line = linear trend with 95% CI"),
    x = "Daily social media use (hours)",
    y = "Anxiety level (1-10)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 12),
    plot.title = element_text(face = "bold"),
    plot.title.position = "plot"
  )

# Display the scatterplot
print(p_scatter)

#Plot 2
pretty_labels <- c(
  daily_social_media_hours = "Social media (hours/day)",
  sleep_hours              = "Sleep (hours/night)",
  age                      = "Age (years)",
  gendermale               = "Gender: male (vs. female)",
  platform_usageBoth       = "Platform: both (vs. other)",
  platform_usageInstagram  = "Platform: Instagram (vs. other)",
  platform_usageTikTok     = "Platform: TikTok (vs. other)"
)
coefs$label <- factor(pretty_labels[coefs$term], levels = rev(unname(pretty_labels)))
coefs$significant <- coefs$low > 0 | coefs$high < 0   # CI excludes zero

p_coefs <- ggplot(coefs, aes(estimate, label, xmin = low, xmax = high, colour = significant)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_pointrange(size = 0.7) +
  scale_colour_manual(
    values = c("TRUE" = "#D55E00", "FALSE" = "grey55"),
    labels = c("TRUE" = "Significant (p < .05)", "FALSE" = "Not significant"),
    name = NULL
  ) +
  labs(title = "Only social media use and sleep predict anxiety",
       x = "Change in anxiety score (points), with 95% CI", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")
