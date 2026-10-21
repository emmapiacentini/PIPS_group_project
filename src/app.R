# Load required packages for the interactive Shiny application
library(shiny)
library(ggplot2)

# Reduced models for the app: social media hours + sleep only.
# The full model showed that platform, age and gender add nothing (R-squared is the same),
# so the app uses the simpler model.
app_model <- lm(anxiety_level ~ daily_social_media_hours + sleep_hours, data = data)

data$high_anxiety <- as.integer(data$anxiety_level >= 7)
app_high_model <- glm(high_anxiety ~ daily_social_media_hours + sleep_hours,
                      data = data, family = binomial())

# Risk bands on the predicted score: <3.5 Low, 3.5-6.5 Moderate, >=6.5 High
# (equivalent to 1-3, 4-6, 7-10 on the integer scale; a project convention, not a clinical cut-off)
classify_risk <- function(score) {
  ifelse(score >= 6.5, "High", ifelse(score >= 3.5, "Moderate", "Low"))
}
clamp_score <- function(x) unname(pmin(pmax(x, 1), 10))   # keep scores on the 1-10 scale

estimate_risk <- function(hours, sleep, level = 0.95) {
  stopifnot(is.numeric(hours), is.numeric(sleep), length(hours) == 1, length(sleep) == 1)
  
  newdata <- data.frame(daily_social_media_hours = hours, sleep_hours = sleep)
  pred <- predict(app_model, newdata, interval = "prediction", level = level)
  score <- clamp_score(pred[1, "fit"])
  
  list(
    score = score,
    lower = clamp_score(pred[1, "lwr"]),
    upper = clamp_score(pred[1, "upr"]),
    p_high = unname(predict(app_high_model, newdata, type = "response")),
    band = classify_risk(score),
    level = level
  )
}

# Define color palette for risk levels
risk_colours <- c(Low = "#2E7D32", Moderate = "#B26A00", High = "#C62828")

# Background map for the plot: predicted risk band for every hours x sleep combination
zone_grid <- expand.grid(
  daily_social_media_hours = seq(min(data$daily_social_media_hours),
                                 max(data$daily_social_media_hours), length.out = 120),
  sleep_hours = seq(min(data$sleep_hours), max(data$sleep_hours), length.out = 120)
)
zone_grid$band <- factor(classify_risk(clamp_score(predict(app_model, zone_grid))),
                         levels = c("Low", "Moderate", "High"))

app_css <- "
  body { background: #f4f6f8; color: #1f2933;
         font-family: -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
  .container-fluid { max-width: 1100px; padding-bottom: 40px; }

  .app-header { padding: 32px 0 20px; }
  .app-header h1 { margin: 0 0 6px; font-weight: 700; font-size: 30px; }
  .app-header p  { margin: 0; color: #52606d; font-size: 16px; }

  .card { background: #fff; border-radius: 14px; padding: 22px 24px; margin-bottom: 20px;
          box-shadow: 0 1px 3px rgba(16,24,40,.08), 0 4px 12px rgba(16,24,40,.04); }
  .card h3 { margin: 0 0 16px; font-size: 17px; font-weight: 700; }
  .label { text-transform: uppercase; letter-spacing: .06em; font-size: 11px;
           font-weight: 600; color: #7b8794; margin-bottom: 6px; }

  .result-top { display: flex; justify-content: space-between; align-items: flex-end;
                flex-wrap: wrap; gap: 16px; margin-bottom: 22px; }
  .band-pill { display: inline-block; color: #fff; font-weight: 700; letter-spacing: .08em;
               padding: 8px 18px; border-radius: 999px; font-size: 15px; }
  .score-block { text-align: right; }
  .score { font-size: 54px; font-weight: 800; line-height: 1; }
  .score-max { font-size: 20px; font-weight: 500; color: #9aa5b1; margin-left: 4px; }
  .interval { color: #52606d; font-size: 13px; margin-top: 6px; }

  .prob-track { background: #e4e7eb; border-radius: 999px; height: 14px; overflow: hidden; }
  .prob-fill  { height: 100%; border-radius: 999px; transition: width .3s ease; }
  .prob-value { font-size: 22px; font-weight: 700; margin-top: 8px; }

  .irs--shiny .irs-bar { background: #4C78A8; border-color: #4C78A8; }
  .irs--shiny .irs-from, .irs--shiny .irs-to, .irs--shiny .irs-single { background: #4C78A8; }
  .irs--shiny .irs-handle { border-color: #4C78A8; }
  .form-group { margin-bottom: 22px; }
  .hint { color: #7b8794; font-size: 12px; margin: 0; }

  details { font-size: 14px; color: #3e4c59; }
  details summary { cursor: pointer; font-weight: 600; margin-bottom: 8px; }
  .disclaimer { background: #fff8e6; border-left: 5px solid #f0b429; border-radius: 10px;
                padding: 14px 18px; font-size: 14px; color: #4a3b00; }
"

ui <- fluidPage(
  tags$head(tags$style(HTML(app_css))),
  
  div(class = "app-header",
      h1("Teen anxiety risk explorer"),
      p("See how daily social media use and sleep relate to predicted anxiety.")
  ),
  
  fluidRow(
    column(4,
           div(class = "card",
               h3("Your details"),
               sliderInput("social_hours", "Daily social media use",
                           min = floor(min(data$daily_social_media_hours)),
                           max = ceiling(max(data$daily_social_media_hours)),
                           value = round(median(data$daily_social_media_hours), 1),
                           step = 0.1, post = " h"),
               sliderInput("sleep_hours", "Sleep per night",
                           min = floor(min(data$sleep_hours)), max = ceiling(max(data$sleep_hours)),
                           value = round(median(data$sleep_hours), 1), step = 0.1, post = " h"),
               p(class = "hint", "Sliders are limited to the ranges in the dataset the model was fitted on.")
           )
    ),
    column(8,
           uiOutput("result_card"),
           div(class = "card", plotOutput("risk_plot", height = "400px"))
    )
  ),
  
  fluidRow(
    column(12,
           div(class = "card",
               tags$details(
                 tags$summary("How this works"),
                 p("The predicted score comes from a linear regression of anxiety (1-10) on daily social",
                   "media hours and sleep. The probability of high anxiety comes from a logistic regression",
                   "with the same two predictors. Age, gender and platform are left out because they did not",
                   "improve the predictions. Bands: 1-3 low, 4-6 moderate, 7-10 high.")
               )
           ),
           div(class = "disclaimer",
               strong("This is an educational tool, not a diagnosis. "),
               "It reflects associations in one cross-sectional dataset and says nothing about causes.",
               "If you are worried about your own or someone else's mental health, please talk to a",
               "doctor, school counsellor or another trusted professional."
           )
    )
  )
)

server <- function(input, output, session) {
  result <- reactive(estimate_risk(input$social_hours, input$sleep_hours))
  
  output$result_card <- renderUI({
    r <- result()
    colour <- risk_colours[[r$band]]
    
    div(class = "card",
        div(class = "result-top",
            div(
              div(class = "label", "Estimated risk"),
              span(class = "band-pill", style = sprintf("background: %s;", colour), toupper(r$band))
            ),
            div(class = "score-block",
                div(class = "label", "Predicted anxiety score"),
                div(class = "score", style = sprintf("color: %s;", colour),
                    sprintf("%.1f", r$score), span(class = "score-max", "/ 10")),
                div(class = "interval",
                    sprintf("%d%% prediction interval: %.1f to %.1f",
                            round(r$level * 100), r$lower, r$upper))
            )
        ),
        div(
          div(class = "label", "Probability of high anxiety (score of 7 or more)"),
          div(class = "prob-track",
              div(class = "prob-fill",
                  style = sprintf("width: %.0f%%; background: %s;", 100 * r$p_high, colour))),
          div(class = "prob-value", sprintf("%.0f%%", 100 * r$p_high))
        )
    )
  })
  
  output$risk_plot <- renderPlot({
    ggplot(zone_grid, aes(daily_social_media_hours, sleep_hours, fill = band)) +
      geom_raster(alpha = 0.35) +
      geom_point(data = data, aes(daily_social_media_hours, sleep_hours),
                 inherit.aes = FALSE, alpha = 0.12, size = 0.7, colour = "grey30") +
      annotate("point", x = input$social_hours, y = input$sleep_hours,
               shape = 21, size = 5, stroke = 1.3, fill = "#D55E00", colour = "white") +
      scale_fill_manual(values = risk_colours, name = "Predicted risk") +
      scale_x_continuous(breaks = 1:8) +
      coord_cartesian(expand = FALSE) +
      labs(title = "Where you sit on the risk map",
           subtitle = "Orange dot: you. Grey dots: teenagers in the dataset.",
           x = "Daily social media use (hours)", y = "Sleep (hours per night)") +
      theme_minimal(base_size = 13) +
      theme(legend.position = "bottom", panel.grid.minor = element_blank(),
            plot.title = element_text(face = "bold"), plot.title.position = "plot")
  }, res = 110)
}

shinyApp(ui = ui, server = server)   # run this line to launch the app
