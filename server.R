# Define server logic 
server <- function(input, output, session) {
  
  ### Leaderboard Menu Item ###
  
  # Render slider input
  output$ip_slider_ui <- renderUI({
    req(df)
    
    min_ip <- 1
    max_ip <- ceiling(max(df$ip, na.rm = TRUE))
    
    sliderInput("ip_range",
                "Select Innings Pitched Range:",
                min = min_ip,
                max = max_ip,
                value = c(30, max_ip),
                step = 1)
  })
  
  
  # Top Strikeouts by Team-Year
  output$top_so_teams <- renderDT({
    df %>%
      mutate(year_team = paste(year, school)) %>%
      group_by(year_team) %>%
      summarize(so = round(sum(so, na.rm = TRUE), 0)) %>%
      arrange(desc(so)) %>%
      datatable(
        options = list(
          paging = FALSE,
          searching = FALSE,
          info = FALSE,
          ordering = TRUE,
          scrollY = "200px",  
          dom = 't'
        ),
        rownames = FALSE
      )
  })
  
  # Top Strikeouts by Player-Year
  output$top_so_players <- renderDT({
    
    req(input$ip_range)
    
    df %>%
      filter(ip >= input$ip_range[1], ip <= input$ip_range[2]) %>% 
      mutate(year_school_player = paste(year, school, name)) %>%
      select(year_school_player, ip, so) %>% 
      arrange(desc(so)) %>%
      datatable(
        options = list(
          paging = FALSE,
          searching = FALSE,
          info = FALSE,
          ordering = TRUE,
          scrollY = "200px", 
          dom = 't'
        ),
        rownames = FALSE
      )
  })
  
  # Top ERA by Team-Year
  output$top_era_teams <- renderDT({
    
    req(input$ip_range)
    
    df %>%
      mutate(year_team = paste(year, school)) %>%
      group_by(year_team) %>%
      summarize(era = round(mean(era, na.rm = TRUE), 3)) %>%
      arrange(era) %>%
      datatable(
        options = list(
          paging = FALSE,
          searching = FALSE,
          info = FALSE,
          ordering = TRUE,
          scrollY = "200px",  
          dom = 't'
        ),
        rownames = FALSE
      )
  })
  
  # Top ERA by Player-Year
  output$top_era_players <- renderDT({
    
    req(input$ip_range)
    
    df %>%
      filter(ip >= input$ip_range[1], ip <= input$ip_range[2]) %>% 
      mutate(year_school_player = paste(year, school, name)) %>%
      select(year_school_player, ip, era) %>% 
      arrange(era) %>%
      datatable(
        options = list(
          paging = FALSE,
          searching = FALSE,
          info = FALSE,
          ordering = TRUE,
          scrollY = "200px",  
          dom = 't'
        ),
        rownames = FALSE
      )
  })
  
  # Top WHIP by Team-Year
  output$top_whip_teams <- renderDT({
    
    req(input$ip_range)
    
    df %>%
      mutate(year_team = paste(year, school)) %>%
      group_by(year_team) %>%
      summarize(whip = round(mean(whip, na.rm = TRUE), 3)) %>%
      arrange(whip) %>%
      datatable(
        options = list(
          paging = FALSE,
          searching = FALSE,
          info = FALSE,
          ordering = TRUE,
          scrollY = "200px",  
          dom = 't'
        ),
        rownames = FALSE
      )
  })
  
  # Top WHIP by Player-Year
  output$top_whip_players <- renderDT({
    
    req(input$ip_range)
    
    df %>%
      filter(ip >= input$ip_range[1], ip <= input$ip_range[2]) %>% 
      mutate(year_school_player = paste(year, school, name)) %>%
      select(year_school_player, ip, whip) %>% 
      arrange(whip) %>%
      datatable(
        options = list(
          paging = FALSE,
          searching = FALSE,
          info = FALSE,
          ordering = TRUE,
          scrollY = "200px",  
          dom = 't'
        ),
        rownames = FALSE
      )
  })
  
  ### Data Menu Item ###
  
  # Reactive raw data
  filtered_raw_df <- reactive({
    req(input$data_schools, input$data_years, input$var)
    
    df %>%
      filter(
        school %in% input$data_schools,
        year %in% input$data_years,
        ip >= input$var[1],
        ip <= input$var[2]
      )
  })
  
  # Render table showing raw data loaded for analysis
  output$raw_data <- renderDT({
    datatable(
      filtered_raw_df(),
      class = 'cell-border stripe',
      options = list(
        scrollY = TRUE, 
        scrollX = "100px",
        scrollCollapse = TRUE,
        fixedHeader = TRUE,
        pageLength = 10)
    )
  })
  
  
  ### Analysis Menu Item ###
  
  ## Report Tab Panel ##
  
  # Reactive report data
  filtered_report_df <- reactive({
    req(input$report_schools)
    
    df %>%
      select(year, school, name, era, ip, bb, bb9, so, so9, h, h9, hr, hr9, whip) %>% 
      filter(school %in% input$report_schools)
  })
  
  # Render UI
  output$report_var_selector <- renderUI({
    req(filtered_report_df())
    
    numeric_vars <- filtered_report_df() %>%
      select(where(is.numeric)) %>%
      select(-year) %>%
      names()
    
    checkboxGroupInput(
      inputId = "selected_vars",
      label = "Choose variables to summarize:",
      choices = numeric_vars,
      selected = numeric_vars[1]  
    )
  })
  
  # Reactive summary triggered by action button
  summary_data <- eventReactive(input$summary_stats, {
    req(input$selected_vars)
    
    filtered_report_df() %>%
      filter(ip > 0) %>%
      group_by(year, school) %>%
      summarise(across(
        all_of(input$selected_vars),
        list(
          mean = ~round(mean(.x, na.rm = TRUE), 3),
          median = ~round(median(.x, na.rm = TRUE), 3),
          sd = ~round(sd(.x, na.rm = TRUE), 3)
        ),
        .names = "{.col}_{.fn}"
      ))
  })
  
  # Store original data as default
  report_mode <- reactiveVal("full")
  
  # Update mode when button is clicked
  observeEvent(input$summary_stats, {
    report_mode("summary")
  })
  
  # Reset table data
  observeEvent(input$reset_report_table, {
    report_mode("full")
  })
  
  # Create dynamic table output
  output$analysis_report <- renderDT({
    if (report_mode() == "full") {
      filtered_report_df() %>%
        filter(ip > 0) %>%
        datatable(
          class = 'cell-border stripe',
          options = list(
            scrollX = TRUE,
            scrollY = TRUE,
            pageLength = 10)
        )
    } else {
      # Show summary data
      req(summary_data())
      datatable(
        summary_data(),
        class = 'cell-border stripe',
        options = list(
          scrollX = TRUE, 
          scrollY = TRUE,
          pageLength = 10)
      )
    }
  })
  
  ### Advanced Statistics Panel Server Logic ###
  
  adv_stats_initialized <- reactiveVal(FALSE)
  
  observe({
    if (!adv_stats_initialized()) {
      updateActionButton(session, "calc_adv_stats", label = "Recalculate Advanced Stats")
    }
  })
  
  # Reactive data
  filtered_adv_df <- reactive({
    req(input$adv_schools, input$adv_years)
    
    # Mark first initialization so we don't re-trigger unintentionally
    if (!adv_stats_initialized()) {
      adv_stats_initialized(TRUE)
    }
    
    df %>%
      filter(
        school %in% input$adv_schools,
        year %in% input$adv_years
      ) %>%
      mutate(
        fip = case_when(
          is.na(hr) | is.na(bb) | is.na(so) | is.na(ip) ~ NA_real_,
          ip < input$fip_min_ip ~ NA_real_,
          TRUE ~ round(((input$hr_weight * hr) + (input$bb_weight * bb) - (input$so_weight * so)) / ip + input$fip_constant, 3)
        ),
        k_pct = case_when(
          is.na(so) | is.na(bf) | bf < input$k_pct_min_bf ~ NA_real_,
          TRUE ~ round(so / bf, 3)
        ),
        bb_pct = case_when(
          is.na(bb) | is.na(bf) | bf < input$bb_pct_min_bf ~ NA_real_,
          TRUE ~ round(bb / bf, 3)
        ),
        k_bb = case_when(
          is.na(so) | is.na(bb) | is.na(ip) ~ NA_real_,
          ip < input$k_bb_min_ip ~ NA_real_,
          bb < input$k_bb_min_bb ~ NA_real_,
          bb == 0 ~ NA_real_,
          TRUE ~ round(so / bb, 3)
        ),
        babip_denominator = bf - so - bb - hbp - hr,
        babip = case_when(
          is.na(h) | is.na(hr) | is.na(so) | is.na(bb) | is.na(hbp) | is.na(bf) | is.na(ip) ~ NA_real_,
          ip < input$babip_min_ip ~ NA_real_,
          babip_denominator <= 0 ~ NA_real_,
          TRUE ~ round((h - hr) / babip_denominator, 3)
        )
      ) %>%
      select(year, school, name, w, l, w_l_percent, ip, bf, fip, k_pct, bb_pct, k_bb, babip)
  })
  
  # Reset advanced stats input controls
  observeEvent(input$reset_adv_stats, {
    updateNumericInput(session, "hr_weight", value = 13)
    updateNumericInput(session, "bb_weight", value = 3)
    updateNumericInput(session, "so_weight", value = 2)
    updateNumericInput(session, "fip_constant", value = 3.1)
    updateNumericInput(session, "fip_min_ip", value = 10)
    updateNumericInput(session, "k_pct_min_bf", value = 10)
    updateNumericInput(session, "bb_pct_min_bf", value = 10)
    updateNumericInput(session, "k_bb_min_bb", value = 1)
    updateNumericInput(session, "k_bb_min_ip", value = 10)
    updateNumericInput(session, "babip_min_ip", value = 10)
  })
  
  # Render advanced stats output
  output$adv_stats_output <- renderDT({
    req(filtered_adv_df())
    
    datatable(
      filtered_adv_df(),
      class = 'cell-border stripe',
      options = list(
        scrollX = TRUE,
        scrollY = TRUE,
        pageLength = 10
      )
    )
  })
  
  ## Plot Tab Panel ##
  
  # Reactive plot data
  filtered_plot_df <- reactive({
    req(input$plot_schools)
    
    df %>%
      select(year, school, name, era, ip, bb, bb9, so, so9, h, h9, hr, hr9, whip) %>% 
      filter(school %in% input$plot_schools)
  })
  
  # Render UI
  output$plot_var_selector <- renderUI({
    req(filtered_plot_df())
    numeric_vars <- filtered_plot_df() %>%
      select(where(is.numeric)) %>%
      select(-year) %>%
      names()
    
    tagList(
      selectInput("plot_var", "Select variable to plot:", choices = numeric_vars),
      radioButtons("plot_mode", "Plot Mode:",
                   choices = c("Raw Only" = "raw", 
                               "Summary Only" = "summary", 
                               "Both" = "both"),
                   selected = "raw")
    )
  })
  
  # Render output
  output$analysis_plot <- renderPlotly({
    # Ensure inputs exist
    req(input$plot_var, input$plot_mode, input$plot_schools)
    
    # Capture the selected variable as a symbol
    var_sym <- sym(input$plot_var)
    
    # Raw data: mean per year
    raw_data <- filtered_plot_df() %>%
      filter(ip > 0) %>%
      group_by(year, school) %>%
      summarise(value = mean(!!var_sym, na.rm = TRUE), .groups = "drop") %>%
      mutate(type = "Raw")
    
    # Summary statistics (mean, median, sd)
    summary_data <- filtered_plot_df() %>%
      filter(ip > 0) %>%
      group_by(year, school) %>%
      summarise(
        mean   = mean(!!var_sym, na.rm = TRUE),
        median = median(!!var_sym, na.rm = TRUE),
        sd     = sd(!!var_sym, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Reshape summary stats to long format for easier plotting
    summary_long <- summary_data %>%
      pivot_longer(cols = c(mean, median, sd), names_to = "type", values_to = "value")
    
    # Decide what to plot
    plot_data <- switch(input$plot_mode,
                        raw = raw_data,
                        summary = summary_long,
                        both = bind_rows(raw_data, summary_long))
    
    # Plotly bar chart
    plot_ly(plot_data,
            x = ~year,
            y = ~value,
            color = ~type,
            type = "bar") %>%
      layout(barmode = "group",
             title = paste("Yearly", input$plot_var, "Analysis"),
             yaxis = list(title = input$plot_var),
             xaxis = list(title = "Year"))
  })
  
  
  ### Player Rating Tab ###
  
  # Render both ui elements
  output$shared_rating_inputs <- renderUI({
    
    tagList(
      pickerInput(
        inputId = "rating_schools",
        label = "Select School(s)",
        choices = schools,
        selected = schools,
        multiple = TRUE,
        options = list(
          `actions-box` = TRUE,
          `live-search` = TRUE,
          `selected-text-format` = "count > 3"
        )
      ),
      pickerInput(
        inputId = "rating_years",
        label = "Select Year(s)",
        choices = seasons,
        selected = seasons,
        multiple = TRUE,
        options = list(
          `actions-box` = TRUE,
          `live-search` = TRUE,
          `selected-text-format` = "count > 3"
        )
      )
    )
  })
  
  # Reactive values for ratings data
  ratings_data <- reactiveVal()
  detailed_data <- reactiveVal()
  
  ratings_data(all_ratings$summary)
  detailed_data(all_ratings$detailed)
  
  
  # Reactive ratings
  filtered_ratings <- reactive({
    req(ratings_data(), input$rating_schools, input$rating_years)
    
    ratings_data() %>%
      filter(year %in% input$rating_years, school %in% input$rating_schools)
  })
  
  filtered_detailed <- reactive({
    req(detailed_data(), input$rating_schools, input$rating_years)
    
    detailed_data() %>%
      filter(year %in% input$rating_years, school %in% input$rating_schools)
  })
  

  # Ratings Table
  output$ratings_table <- renderDT({
    filtered_ratings()
  },
  options = list(pageLength = -1, scrollY = "500px", scrollX = TRUE, paging = FALSE)
  )
  
  # Methodology Table
  output$methodology_table <- renderDT({
    filtered_detailed()
  },
  options = list(pageLength = -1, scrollY = "500px", scrollX = TRUE, paging = FALSE)
  )
  
  # Recalculate logic placeholder
  observeEvent(input$update_ratings, {
    withProgress(message = "Calculating player ratings. Please wait...", value = 0.5, {
      
      raw_weights <- sapply(rating_stats$stat, function(stat) input[[paste0("weight_", stat)]])
      names(raw_weights) <- paste0(rating_stats$stat, "_rating")
      
      weight_sum <- sum(raw_weights, na.rm = TRUE)
      if (weight_sum == 0) {
        normalized_weights <- rep(1 / length(raw_weights), length(raw_weights))  # fallback: equal weights
      } else {
        normalized_weights <- raw_weights / weight_sum
      }
      
      updated_priors <- sapply(rating_stats$stat, function(stat) input[[paste0("prior_", stat)]])
      
      updated_rating_stats <- rating_stats %>%
        mutate(prior_weight = updated_priors)
      
      rating_input_df <- player_ratings_df %>%
        filter(ip > 0)
      
      # Run ratings generation
      new_ratings <- generate_player_ratings(rating_input_df, updated_rating_stats, normalized_weights)
      
      ratings_data(new_ratings$summary)
      detailed_data(new_ratings$detailed)
    })
  })
  
  # Reset methodology stats
  observeEvent(input$reset_rating_inputs, {
    for (stat in rating_stats$stat) {
      updateNumericInput(session, paste0("weight_", stat),
                         value = stat_weights[[paste0(stat, "_rating")]])
      
      updateNumericInput(session, paste0("prior_", stat),
                         value = rating_stats$prior_weight[rating_stats$stat == stat])
    }
  })
  
  # Render warning output for weights
  output$weight_sum_warning <- renderText({
    raw_weights <- sapply(rating_stats$stat, function(stat) input[[paste0("weight_", stat)]])
    total <- round(sum(raw_weights, na.rm = TRUE), 3)
    
    if (abs(total - 1) > 0.01) {
      paste("⚠️ Weights sum to", total, "- they will be normalized to 1.0.")
    } else {
      paste("✓ Weights sum to", total)
    }
  })
  
}


