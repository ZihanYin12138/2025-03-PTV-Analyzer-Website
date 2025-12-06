# library(shiny)

# Add Google font and enable text rendering
font_add_google("Roboto", "roboto")
showtext_auto()

# For Page 1.2 
# Load required data for Page 1.2 (ridgeline plots of boarding and frequency density)
df_combined_sampled <- readRDS("data/page_1.2_story_mode.rds")

# Recode line name for consistent formatting in plots
df_combined_sampled <- df_combined_sampled %>%
  mutate(Line_Name = recode(Line_Name,
                            "Richmond and City Loop" = "Richmond and\nCity Loop"))

# For Page 1.3 Exploration Mode
# Define feature labels used in Page 1.3 for model explanation
label_map <- c(
  "Train_Freq" = "Train Frequency",
  "Direction_Up_Proportion" = "Up Direction %",
  "solar" = "Solar Radiation",
  "windspeed" = "Wind Speed",
  "relativehumidity" = "Relative Humidity",
  "airtemp" = "Air Temperature",
  "Day_Type" = "Day Type",
  "Day_of_Week" = "Day of Week",
  "atmosphericpressure" = "Atmospheric Pressure",
  "vapourpressure" = "Vapour Pressure",
  "strikes" = "Strike Events",
  "winddirection" = "Wind Direction"
)

# Function to apply feature name mapping to improve plot readability
add_feature_labels <- function(df) {
  df %>%
    mutate(Label = ifelse(Feature %in% names(label_map),
                          label_map[Feature],
                          Feature))  # fallback to original name
}

# For Page 2.4 Exploration Mode
# Load precomputed data for Page 2.4 (station-level crowding index)
df_combined <- readRDS("data/page_2.4_explore_mode_precomputed.rds")

# Ensure character format for day type column
df_combined <- df_combined %>%
  mutate(Day_Type = as.character(Day_Type))

# Load station metadata and extract coordinates for leaflet mapping
station_meta <- st_read("data/page_2.4_station_stats_with_station_type.geojson") %>%
  mutate(
    Longitude = st_coordinates(geometry)[,1],
    Latitude = st_coordinates(geometry)[,2]
  ) %>%
  st_drop_geometry() %>%
  select(Station_Name, N_Metro_Platform, N_Lines, Station_Type, Latitude, Longitude)

# Color palette for crowding index visualization
pal <- colorNumeric(palette = "inferno", domain = df_combined$Crowding_Index, reverse = TRUE)



# The Real Part
# Define server-side logic

# ---- Page 0 Home Page ----
shinyServer(function(input, output, session) {
  
  # Handle navbar tab link clicks from homepage
  observeEvent(input$to_page1, {
    updateTabsetPanel(session, "main_nav", selected = "Line-Level Analysis")
  })

  observeEvent(input$to_page2, {
    updateTabsetPanel(session, "main_nav", selected = "Station-Level Analysis")
  })

  observeEvent(input$to_page3, {
    updateTabsetPanel(session, "main_nav", selected = "About Project")
  })
  
  # ---- Page 1 Line-Level Analysis----
  ## -------- Page 1.1 --------
  ### ---- Story Mode ----
  
  # Render static plot for Story Mode showing passenger boardings in both directions
  output$page11_story_plot <- renderPlot({
    
    # Load pre-processed dataset for line-level directional boarding
    df_boarding_by_line_direction <- readRDS("data/page_1.1_story_mode.rds")
    
    # Reshape data to long format with direction labels and custom colors
    df_boarding_long <- df_boarding_by_line_direction %>%
      pivot_longer(cols = c("Up", "Down"), names_to = "Direction", values_to = "Boardings") %>%
      mutate(
        Direction_Label = if_else(Direction == "Up", "Towards Flinders", "From Flinders"),
        Color = if_else(Direction == "Up", rgb(0.2, 0.7, 0.1, 0.6), rgb(0.7, 0.2, 0.1, 0.6))
      )
    
    # Create label data for annotation on plot
    df_boarding_labels <- df_boarding_by_line_direction %>%
      mutate(
        max_val = pmax(Up, Down),  # Take the higher of Up or Down as label reference
        label_x = max_val + 250000,  # Offset for label positioning
        label_y = Line_Name,
        label_text = label_number(accuracy = 0.1, scale_cut = cut_short_scale())(sum_load)
      )
    
    # Plot: each line shows a directional segment and two colored dots representing boardings
    ggplot() +
      geom_segment(data = df_boarding_by_line_direction,
                   aes(x = Line_Name, xend = Line_Name, y = Down, yend = Up),
                   color = "grey40") +
      geom_point(data = df_boarding_long,
                 aes(x = Line_Name, y = Boardings, color = Direction_Label),
                 size = 7, shape = 16) +
      geom_text(data = df_boarding_labels,
                aes(x = label_y, y = label_x, label = label_text),
                color = "grey40", size = 5, hjust = 0) +
      scale_color_manual(
        values = c("Towards Flinders" = rgb(0.2, 0.7, 0.1, 0.6),
                   "From Flinders" = rgb(0.7, 0.2, 0.1, 0.6)),
        name = "Train Line Direction",
        guide = guide_legend(override.aes = list(shape = 16, size = 8))
      ) +
      coord_flip() +  # Horizontal layout for better readability
      scale_y_continuous(
        labels = label_number(accuracy = 0.1, scale_cut = cut_short_scale()),
        limits = c(NA, max(df_boarding_labels$label_x) * 1.05)
      ) +
      labs(
        title = "Train Line Annual Passengers Boarding: Towards vs From Flinders",
        x = "Train Line",
        y = "Total Number of Passengers Boarding"
      ) +
      theme_minimal(base_family = "roboto") +
      theme(
        plot.title = element_text(size = 17, face = "bold", color = "#2a475e"),
        axis.title = element_text(size = 13, face = "bold"),
        legend.title = element_text(size = 13, face = "bold"),
        legend.text = element_text(size = 12),
        legend.position = "top",
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)
      )
  })
  
  
  ### ---- Exploration Mode ----
  # Render plot for interactive exploration with day type/time bin filters and sorting option
  output$page11_exploration_plot <- renderPlot({
    
    # Load dataset for interactive filtering
    df_exploration_input <- readRDS("data/page_1.1_exploration_mode.rds")
    
    # Get user input values
    selected_daytype <- input$page11_daytype
    selected_timebin <- input$page11_timebin
    sort_by_diff <- input$page11_sortbydiff
    
    # Filter data based on selected day type and time bin
    df_exploration_filtered <- df_exploration_input %>%
      filter(
        (selected_daytype == "All" | Day_Type == selected_daytype),
        (selected_timebin == "All" | Time_Bin == selected_timebin)
      ) 
    
    # Aggregate across time/day if user selects "All"
    if (selected_daytype == "All" | selected_timebin == "All") {
      df_exploration_filtered <- df_exploration_filtered %>%
        group_by(Line_Name) %>%
        summarise(
          Up = sum(Up),
          Down = sum(Down),
          sum_load = sum(sum_load),
          diff_load = sum(diff_load),
          .groups = "drop"
        )
    }
    
    # Sort by difference or total, and prepare label text
    if (sort_by_diff) {
      df_exploration_filtered <- df_exploration_filtered %>%
        arrange(desc(-diff_load)) %>%
        mutate(
          Line_Name = factor(Line_Name, levels = Line_Name),
          label_value = diff_load,
          label_text = label_number(accuracy = 0.1, scale_cut = cut_si(""))(diff_load)
        )
    } else {
      df_exploration_filtered <- df_exploration_filtered %>%
        arrange(desc(-sum_load)) %>%
        mutate(
          Line_Name = factor(Line_Name, levels = Line_Name),
          label_value = sum_load,
          label_text = label_number(accuracy = 0.1, scale_cut = cut_si(""))(sum_load)
        )
    }
    
    # Reshape for plotting each direction (Up/Down)
    df_exploration_long <- df_exploration_filtered %>%
      select(Line_Name, Up, Down) %>%
      pivot_longer(cols = c(Up, Down), names_to = "Direction", values_to = "Boardings") %>%
      mutate(
        Direction_Label = if_else(Direction == "Up", "Towards Flinders", "From Flinders"),
        Color = if_else(Direction == "Up", rgb(0.2, 0.7, 0.1, 0.6), rgb(0.7, 0.2, 0.1, 0.6))
      )
    
    # Generate final interactive plot
    ggplot() +
      geom_segment(data = df_exploration_filtered,
                   aes(x = Line_Name, xend = Line_Name, y = Down, yend = Up),
                   color = "grey40") +
      geom_point(data = df_exploration_long,
                 aes(x = Line_Name, y = Boardings, color = Direction_Label),
                 size = 7, shape = 16) +
      geom_text(data = df_exploration_filtered,
                aes(x = Line_Name, y = pmax(Up, Down) * 1.1 + 200, label = label_text),
                color = "grey40", size = 5, hjust = 0) +
      scale_color_manual(
        values = c("Towards Flinders" = rgb(0.2, 0.7, 0.1, 0.6),
                   "From Flinders" = rgb(0.7, 0.2, 0.1, 0.6)),
        name = "Train Line Direction",
        guide = guide_legend(override.aes = list(shape = 16, size = 8))
      ) +
      coord_flip() +  # Flip coordinates for horizontal layout
      scale_y_continuous(
        labels = label_number(accuracy = 0.1, scale_cut = cut_si("")),
        limits = c(NA, max(pmax(df_exploration_filtered$Up, df_exploration_filtered$Down) * 1.15) * 1.05)
      ) +
      labs(
        title = "Train Line Annual Passengers Boarding: Towards vs From Flinders",
        x = "Train Line",
        y = "Number of Passengers"
      ) +
      theme_minimal(base_family = "roboto") +
      theme(
        plot.title = element_text(size = 17, face = "bold", color = "#2a475e"),
        axis.title = element_text(size = 13, face = "bold"),
        legend.title = element_text(size = 13, face = "bold"),
        legend.text = element_text(size = 12),
        legend.position = "top",
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)
      )
    
  })
  
  # Reset UI inputs when "Reset" button is clicked
  observeEvent(input$page11_reset, {
    updateSelectInput(session, "page11_daytype", selected = "All")
    updateSelectInput(session, "page11_timebin", selected = "All")
    updateCheckboxInput(session, "page11_sortbydiff", value = FALSE)
  })
  
  
  ## ---- Page 1.2 ----
  ### ---- Story Mode ----
  
  #### ---- Story 1 ----
  # Render a density ridge plot showing passenger boarding density over time
  # for the top 3 train lines: Pakenham, Lilydale, and Craigieburn.
  # Density is weighted by number of boardings.
  output$Page12_story1 <- renderPlot({
    df_story1 <- df_combined_sampled %>%
      filter(Line_Name %in% c("Pakenham", "Lilydale", "Craigieburn"),
             Metric == "Passenger Boarding Density")
    
    ggplot(df_story1, aes(x = Arrival_Time_Scheduled, y = Line_Name, fill = Metric, colour = Metric)) +
      geom_density_ridges(
        aes(
          height = ..density..,
          weight = Passenger_Boardings,
          group = interaction(Line_Name, Metric)
        ),
        alpha = 0.4,
        scale = 1.2,
        stat = "density"
      ) +
      scale_fill_manual(values = c("Passenger Boarding Density" = "darkorange")) +
      scale_colour_manual(values = c("Passenger Boarding Density" = "darkorange")) +
      scale_x_time(
        labels = scales::label_time(format = "%H:%M"),
        breaks = hms::hms(hours = seq(0, 24, by = 4))
      ) +
      labs(
        title = "Passenger Boarding Density by Time (Top 3 Lines)",
        x = "Time of Day",
        y = "Train Line"
      ) +
      theme_minimal(base_family = "roboto") +
      theme(
        plot.title = element_text(size = 17, face = "bold", color = "#2a475e"),
        axis.title = element_text(size = 13, face = "bold"),
        legend.position = "none",
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)
      )
  })
  
  #### ---- Story 2 ----
  # Render a density ridge plot of train frequency over time
  # for the same top 3 lines, using uniform weighting.
  output$Page12_story2 <- renderPlot({
    df_story2 <- df_combined_sampled %>%
      filter(Line_Name %in% c("Pakenham", "Lilydale", "Craigieburn"),
             Metric == "Train Frequency Density")
    
    ggplot(df_story2, aes(x = Arrival_Time_Scheduled, y = Line_Name, fill = Metric, colour = Metric)) +
      geom_density_ridges(
        aes(
          height = ..density..,
          weight = 1,
          group = interaction(Line_Name, Metric)
        ),
        alpha = 0.4,
        scale = 1.2,
        stat = "density"
      ) +
      scale_fill_manual(values = c("Train Frequency Density" = "steelblue")) +
      scale_colour_manual(values = c("Train Frequency Density" = "steelblue")) +
      scale_x_time(
        labels = scales::label_time(format = "%H:%M"),
        breaks = hms::hms(hours = seq(0, 24, by = 4))
      ) +
      labs(
        title = "Train Frequency Density by Time (Top 3 Lines)",
        x = "Time of Day",
        y = "Train Line"
      ) +
      theme_minimal(base_family = "roboto") +
      theme(
        plot.title = element_text(size = 17, face = "bold", color = "#2a475e"),
        axis.title = element_text(size = 13, face = "bold"),
        legend.position = "none",
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)
      )
  })
  
  #### ---- Story 3 ----
  # Overlay plot showing both boarding density and train frequency for top 3 lines.
  # Highlights the supply-demand relationship.
  output$Page12_story3 <- renderPlot({
    df_story3 <- df_combined_sampled %>%
      filter(Line_Name %in% c("Pakenham", "Lilydale", "Craigieburn"))
    
    ggplot(df_story3, aes(x = Arrival_Time_Scheduled, y = Line_Name, fill = Metric, colour = Metric)) +
      geom_density_ridges(
        aes(
          height = ..density..,
          weight = ifelse(Metric == "Passenger Boarding Density", Passenger_Boardings, 1),
          group = interaction(Line_Name, Metric)
        ),
        alpha = 0.3,
        scale = 1,
        stat = "density"
      ) +
      scale_fill_manual(
        values = c("Train Frequency Density" = "steelblue", "Passenger Boarding Density" = "darkorange")
      ) +
      scale_colour_manual(
        values = c("Train Frequency Density" = "steelblue", "Passenger Boarding Density" = "darkorange")
      ) +
      scale_x_time(
        labels = scales::label_time(format = "%H:%M"),
        breaks = hms::hms(hours = seq(0, 24, by = 4))
      ) +
      labs(
        title = "Supply vs Demand - Top 3 Lines",
        x = "Time of Day",
        y = "Train Line"
      ) +
      theme_minimal(base_family = "roboto") +
      theme(
        plot.title = element_text(size = 17, face = "bold", color = "#2a475e"),
        axis.title = element_text(size = 13, face = "bold"),
        legend.title = element_text(size = 13, face = "bold"),
        legend.text = element_text(size = 12),
        legend.position = "top",
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)
      )
  })
  
  #### ---- Story 4 ----
  # Similar overlay plot for two outlier lines: Alamein and Richmond/City Loop.
  # Useful for anomaly investigation.
  output$Page12_story4 <- renderPlot({
    df_story4 <- df_combined_sampled %>%
      filter(Line_Name %in% c("Alamein", "Richmond and\nCity Loop"))
    
    ggplot(df_story4, aes(x = Arrival_Time_Scheduled, y = Line_Name, fill = Metric, colour = Metric)) +
      geom_density_ridges(
        aes(
          height = ..density..,
          weight = ifelse(Metric == "Passenger Boarding Density", Passenger_Boardings, 1),
          group = interaction(Line_Name, Metric)
        ),
        alpha = 0.3,
        scale = 1,
        stat = "density"
      ) +
      scale_fill_manual(
        values = c("Train Frequency Density" = "steelblue", "Passenger Boarding Density" = "darkorange")
      ) +
      scale_colour_manual(
        values = c("Train Frequency Density" = "steelblue", "Passenger Boarding Density" = "darkorange")
      ) +
      scale_x_time(
        labels = scales::label_time(format = "%H:%M"),
        breaks = hms::hms(hours = seq(0, 24, by = 4))
      ) +
      labs(
        title = "Supply vs Demand - Anomalous Lines",
        x = "Time of Day",
        y = "Train Line"
      ) +
      theme_minimal(base_family = "roboto") +
      theme(
        plot.title = element_text(size = 17, face = "bold", color = "#2a475e"),
        axis.title = element_text(size = 13, face = "bold"),
        legend.title = element_text(size = 13, face = "bold"),
        legend.text = element_text(size = 12),
        legend.position = "top",
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)
      )
  })
  
  ### ---- Exploration Mode ----
  # Generalized plot function for dynamic day-type overlay plotting.
  # This is reused in the interactive exploration section.
  plot_daytype_overlay <- function(df, title_text) {
    ggplot(df, aes(x = Arrival_Time_Scheduled, y = Line_Name, fill = Metric, colour = Metric)) +
      geom_density_ridges(
        aes(
          height = ..density..,
          weight = ifelse(Metric == "Passenger Boarding Density", Passenger_Boardings, 1),
          group = interaction(Line_Name, Metric)
        ),
        alpha = 0.3,
        scale = 1,
        stat = "density"
      ) +
      scale_fill_manual(
        values = c("Train Frequency Density" = "steelblue", "Passenger Boarding Density" = "darkorange")
      ) +
      scale_colour_manual(
        values = c("Train Frequency Density" = "steelblue", "Passenger Boarding Density" = "darkorange")
      ) +
      scale_x_time(
        labels = scales::label_time(format = "%H:%M"),
        breaks = hms::hms(hours = seq(0, 24, by = 4))
      ) +
      labs(
        title = title_text,
        x = "Time of Day",
        y = "Train Line"
      ) +
      theme_minimal(base_family = "roboto") +
      theme(
        plot.title = element_text(size = 17, face = "bold", color = "#2a475e"),
        axis.title = element_text(size = 13, face = "bold"),
        legend.title = element_text(size = 13, face = "bold"),
        legend.text = element_text(size = 12),
        legend.position = "top",
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)
      )
  }
  
  # Render the interactive plot based on selected day type.
  output$Page12_explorePlot <- renderPlot({
    
    # Retrieve user-selected day type from UI input
    selected_type <- input$Page12_daytype
    
    # Load the corresponding dataset based on day type
    df <- switch(selected_type,
                 "All" = readRDS("data/page_1.2_story_mode.rds"),
                 "Normal Weekday" = readRDS("data/page_1.2_explore_weekday.rds"),
                 "Normal Weekend" = readRDS("data/page_1.2_explore_weekend.rds"),
                 "Public Holiday" = readRDS("data/page_1.2_explore_public.rds"),
                 "School Holiday" = readRDS("data/page_1.2_explore_school.rds"))
    
    # Set dynamic title for plot
    title_text <- paste0(selected_type, " - Supply vs Demand")
    
    # Render plot using generalized overlay function
    plot_daytype_overlay(df, title_text)
  })
  
  
  ## ---- Page 1.3 ----
  
  ### ---- Story Mode ----
  # Render the bar plot showing the top 10 most important features from the Random Forest model (Story Mode)
  output$Page13_rfBarPlot <- renderPlot({
    # Load pre-calculated feature importance data from Random Forest
    df_rf_importance <- readRDS("data/page_1.3_story_mode.rds")
    
    # Create a bar chart to show feature importance based on two metrics
    ggplot(df_rf_importance, aes(x = reorder(Feature, -Mean_Scaled_Importance), y = Scaled_Importance, fill = Metric)) +
      geom_bar(stat = "identity", position = position_dodge(width = 0.7)) +
      scale_fill_manual(values = c("MSE Increase" = "#1f77b4", "Node Purity Increase" = "#ff7f0e")) +
      labs(
        title = "Top 10 Features for Predicting Total Passenger Boardings",
        x = "Features Used to Predict Total Boardings",
        y = "Scaled Importance (0–1)",
        fill = "Importance Metric"
      ) +
      theme_minimal(base_family = "roboto") +
      theme(
        axis.text.x = element_text(size = 12, angle = 45, hjust = 1),
        axis.text.y = element_text(size = 12),
        axis.title = element_text(size = 13, face = "bold"),
        plot.title = element_text(size = 17, face = "bold", color = "#2a475e"),
        legend.title = element_text(size = 13, face = "bold"),
        legend.text = element_text(size = 12)
      ) 
  })
  
  
  ### ---- Exploration Mode ----
  # Dynamically render feature importance plot based on selected model type
  output$Page13_explore_plot <- renderPlot({
    # Ensure model choice input is available
    req(input$Page13_model_choice)
    
    # Load the corresponding feature importance data based on selected model
    df <- switch(input$Page13_model_choice,
                 "rf" = readRDS("data/page_1.3_story_mode.rds"),
                 "dt" = readRDS("data/page_1.3_dt_importance.rds"),
                 "lm" = readRDS("data/page_1.3_lm_importance.rds"),
                 "lasso" = readRDS("data/page_1.3_lasso_importance.rds")
    )
    
    # If the data includes a 'Metric' column, plot with multiple importance metrics (e.g. for RF)
    if ("Metric" %in% colnames(df)) {
      ggplot(df, aes(x = reorder(Feature, -Scaled_Importance), y = Scaled_Importance, fill = Metric)) +
        geom_bar(stat = "identity", position = position_dodge(width = 0.7)) +
        scale_fill_manual(values = c("MSE Increase" = "#1f77b4", "Node Purity Increase" = "#ff7f0e")) +
        labs(
          title = "Random Forest Feature Importance",
          x = "Feature",
          y = "Scaled Importance",
          fill = "Importance Metric"
        ) +
        theme_minimal(base_family = "roboto") +
        theme(
          axis.text.x = element_text(size = 12, angle = 45, hjust = 1),
          axis.text.y = element_text(size = 12),
          axis.title = element_text(size = 12),
          plot.title = element_text(size = 16, face = "bold", color = "#2a475e"),
          legend.title = element_text(size = 12),
          legend.text = element_text(size = 12)
        )
    } else {
      # For models without multiple metrics (e.g. DT, LM, LASSO), use simplified single-metric bar plot
      df <- add_feature_labels(df)  # Add human-readable feature labels
      ggplot(df, aes(x = reorder(Label, -Importance), y = Importance)) +
        geom_bar(stat = "identity", fill = "grey60") +
        labs(
          title = "Model-Based Feature Importance",
          x = "Feature",
          y = "Importance"
        ) +
        theme_minimal(base_family = "roboto") +
        theme(
          axis.text.x = element_text(size = 12, angle = 45, hjust = 1),
          axis.text.y = element_text(size = 12),
          axis.title = element_text(size = 12),
          plot.title = element_text(size = 16, face = "bold", color = "#2a475e")
        )
    }
  })
  
  ## ---- End of Page 1 ----
  
  # Navigate to next tab when "next_page2" button is clicked
  observeEvent(input$next_page2, {
    updateTabsetPanel(session, "main_nav", selected = "Station-Level Analysis")
    session$sendCustomMessage("scrollToTop", "go")
  })
  
  # Navigate back to home tab when "back_home1" button is clicked
  observeEvent(input$back_home1, {
    updateTabsetPanel(session, "main_nav", selected = "Home")
    session$sendCustomMessage("scrollToTop", "go")
  })
  
  
  
  # ---- Page 2 Station-Level Analysis----
  ## ---- Page 2.1 ----
  ### ---- Story Mode 1 ----
  output$Page21_story1 <- renderPlot({
    # Load and prepare data
    df <- read_csv("data/page_2.1_story1.csv") %>%
      mutate(Day_Type = factor(Day_Type,
                               levels = c("Normal Weekday", "Normal Weekend", "Public Holiday", "School Holiday"),
                               ordered = TRUE
      ))
    
    # Create label positions and formatting
    df_labels <- df %>%
      mutate(
        label_pct = paste0(round(prop * 100), "%"),
        label_pax = paste0(round(Total), " pax"),
        x_label = ifelse(Type == "Boardings", x - r * 0.5, x + r * 0.5),
        y_label = y,
        y_pax = y - r - 0.10
      )
    
    # Plot arc bars for each day type and flow type
    ggplot(df) +
      geom_arc_bar(aes(x0 = x, y0 = y, r0 = 0, r = r, start = start, end = end, fill = Type),
                   color = "white", size = 0.4, alpha = 0.95
      ) +  # Draw proportional arc segments
      scale_fill_manual(values = c("Boardings" = "steelblue", "Alightings" = "darkorange")) +  # Custom fill colors for types
      scale_x_continuous(
        breaks = 1:4,
        labels = levels(df$Day_Type),
        expand = expansion(mult = 0.1)
      ) +
      coord_fixed() +
      labs(x = NULL, y = NULL, title = "Passenger Flow Composition by Day Type", fill = "Flow Type") +
      theme_minimal(base_family = "roboto") +
      theme(
        axis.text.y = element_blank(),
        axis.text.x = element_text(size = 12),
        legend.title = element_text(size = 13, face = "bold"),
        legend.text = element_text(size = 12),
        plot.title = ggtext::element_textbox_simple(size = 17, face = "bold", color = "#2a475e", margin = margin(b = 20, unit = "pt"))
      ) +
      geom_text(data = df_labels, aes(x = x_label, y = y_label, label = label_pct), size = 4, color = "white") + # Add % labels inside arcs
      geom_text(data = df_labels %>% distinct(Day_Type, x, y_pax, label_pax),
                aes(x = x, y = y_pax, label = label_pax), size = 4, color = "gray40"
      )    # Add total passenger labels below arcs
  })
  
  ### ---- Story Mode 2 ----
  output$Page21_story2 <- renderPlot({
    # Load and prepare time-binned passenger flow data
    df <- read_csv("data/page_2.1_story2.csv") %>%
      mutate(
        Time_Bin = factor(Time_Bin, levels = c("00:00–04:00", "04:00–08:00", "08:00–12:00", "12:00–16:00", "16:00–20:00", "20:00–00:00")),
        r_raw = sqrt(Total) / sqrt(max(Total)) * 0.45,
        r = pmax(r_raw, 0.25)
      )
    
    # Generate label positions for arcs
    df_labels <- df %>%
      mutate(
        label_pct = paste0(round(prop * 100), "%"), # Percentage labels
        label_pax = paste0(round(Total), " pax"), # Total labels
        x_label = ifelse(Type == "Boardings", x + r * 0.5, x - r * 0.5),
        y_label = y,
        y_pax = y - r - 0.2
      )
    
    # Plot arc bars by time bins
    ggplot(df) +
      geom_arc_bar(aes(x0 = x, y0 = y, r0 = 0, r = r, start = start, end = end, fill = Type),
                   color = "white", size = 0.4, alpha = 0.95
      ) +
      scale_fill_manual(values = c("Boardings" = "steelblue", "Alightings" = "darkorange")) +
      scale_x_continuous(
        breaks = 1:6,
        labels = levels(df$Time_Bin),
        expand = expansion(mult = 0.1)
      ) +
      coord_fixed() +
      labs(x = NULL, y = NULL, title = "Passenger Flow Composition by Time of Day", fill = "Flow Type") +
      theme_minimal(base_family = "roboto") +
      theme(
        axis.text.y = element_blank(),
        axis.text.x = element_text(size = 12),
        legend.title = element_text(size = 13, face = "bold"),
        legend.text = element_text(size = 12),
        plot.title = ggtext::element_textbox_simple(size = 17, face = "bold", color = "#2a475e", margin = margin(b = 20, unit = "pt"))
      ) +
      geom_text(data = df_labels, aes(x = x_label, y = y_label, label = label_pct), size = 4, color = "white") +  # Add % labels
      geom_text(data = df_labels %>% distinct(Time_Bin, x, y_pax, label_pax),  # Add total pax labels
                aes(x = x, y = y_pax, label = label_pax), size = 4, color = "gray40"
      ) +
      scale_x_continuous(
        breaks = 1:6,
        labels = levels(df$Time_Bin),
        expand = c(0, 0)
      )  # Override x-axis expansion
    
  })
  
  ### ---- Story Mode 3 ----
  output$Page21_story3 <- renderPlot({
    # Read and prepare grid data with categorical order
    df <- read_csv("data/page_2.1_story3_story4.csv") %>%
      mutate(
        Day_Type = factor(Day_Type, levels = c("Normal Weekday", "Normal Weekend", "Public Holiday", "School Holiday"), ordered = TRUE),
        Time_Bin = factor(Time_Bin, levels = c("00:00–04:00", "04:00–08:00", "08:00–12:00", "12:00–16:00", "16:00–20:00", "20:00–00:00"))
      ) %>%
      mutate(x = as.numeric(Time_Bin), y = as.numeric(fct_rev(Day_Type)))
    
    # Reshape to long format and compute arc angles
    df_long <- df %>%
      pivot_longer(cols = c(Boardings, Alightings), names_to = "Type", values_to = "Value") %>%
      group_by(Day_Type, Time_Bin) %>%
      mutate(prop = Value / sum(Value), start = cumsum(lag(prop, default = 0)) * 2 * pi, end = cumsum(prop) * 2 * pi) %>%
      ungroup() %>%
      mutate(x = as.numeric(Time_Bin), y = as.numeric(fct_rev(Day_Type)))
    
    # Plot grid of circular flows
    ggplot(df_long) +
      geom_arc_bar(aes(x0 = x, y0 = y, r0 = 0, r = r, start = start, end = end, fill = Type),
                   color = "white", size = 0.3, alpha = 0.9
      ) +
      scale_fill_manual(values = c("Boardings" = "steelblue", "Alightings" = "darkorange")) +
      scale_x_continuous(breaks = 1:6, labels = levels(df$Time_Bin), expand = expansion(mult = 0.1)) +
      scale_y_continuous(breaks = 1:4, labels = rev(levels(df$Day_Type)), expand = expansion(mult = 0.1)) +
      labs(x = "Time of Day", y = "Day Type", fill = "Flow Type", title = "Hourly Station Passenger Volume Composition by Day Type and Time of Day") +
      theme_minimal(base_family = "roboto") +
      theme(
        plot.title = element_text(size = 17, face = "bold", color = "#2a475e"),
        axis.title = element_text(size = 13, face = "bold"),
        legend.title = element_text(size = 13, face = "bold"),
        legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)
      ) +
      geom_text(
        data = df, aes(x = as.numeric(Time_Bin), y = as.numeric(fct_rev(Day_Type)) - r - 0.075, label = paste0(round(100 * Boardings / Total), "%")),
        color = "steelblue", size = 3.2
      ) + # Boarding % inside arcs
      geom_text(
        data = df, aes(x = as.numeric(Time_Bin), y = as.numeric(fct_rev(Day_Type)) - r - 0.18, label = paste0(round(Total), " pax")),
        color = "gray40", size = 3.2
      ) +  # Total below arcs
      annotate("rect", xmin = 4.5, xmax = 5.5, ymin = 3.4, ymax = 4.4, alpha = 0.1, color = "#2a475e", fill = "#2a475e") + # Highlight specific regions
      annotate("rect", xmin = 0.6, xmax = 1.4, ymin = 1.6, ymax = 2.2, alpha = 0.1, color = "#2a475e", fill = "#2a475e")
  })
  
  ### ---- Story Mode 4 ----
  output$Page21_story4 <- renderPlot({
    # Similar setup as Story 3
    df <- read_csv("data/page_2.1_story3_story4.csv") %>%
      mutate(
        Day_Type = factor(Day_Type, levels = c("Normal Weekday", "Normal Weekend", "Public Holiday", "School Holiday"), ordered = TRUE),
        Time_Bin = factor(Time_Bin, levels = c("00:00–04:00", "04:00–08:00", "08:00–12:00", "12:00–16:00", "16:00–20:00", "20:00–00:00"))
      ) %>%
      mutate(x = as.numeric(Time_Bin), y = as.numeric(fct_rev(Day_Type)))
    
    df_long <- df %>%
      pivot_longer(cols = c(Boardings, Alightings), names_to = "Type", values_to = "Value") %>%
      group_by(Day_Type, Time_Bin) %>%
      mutate(prop = Value / sum(Value), start = cumsum(lag(prop, default = 0)) * 2 * pi, end = cumsum(prop) * 2 * pi) %>%
      ungroup() %>%
      mutate(x = as.numeric(Time_Bin), y = as.numeric(fct_rev(Day_Type)))
    
    ggplot(df_long) +
      geom_arc_bar(aes(x0 = x, y0 = y, r0 = 0, r = r, start = start, end = end, fill = Type),
                   color = "white", size = 0.3, alpha = 0.9
      ) +
      scale_fill_manual(values = c("Boardings" = "steelblue", "Alightings" = "darkorange")) +
      scale_x_continuous(breaks = 1:6, labels = levels(df$Time_Bin), expand = expansion(mult = 0.1)) +
      scale_y_continuous(breaks = 1:4, labels = rev(levels(df$Day_Type)), expand = expansion(mult = 0.1)) +
      labs(x = "Time of Day", y = "Day Type", fill = "Flow Type", title = "Hourly Station Passenger Volume Composition by Day Type and Time of Day") +
      theme_minimal(base_family = "roboto") +
      theme(
        plot.title = element_text(size = 17, face = "bold", color = "#2a475e"),
        axis.title = element_text(size = 13, face = "bold"),
        legend.title = element_text(size = 13, face = "bold"),
        legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)
      ) +
      geom_text(
        data = df, aes(x = as.numeric(Time_Bin), y = as.numeric(fct_rev(Day_Type)) - r - 0.075, label = paste0(round(100 * Boardings / Total), "%")),
        color = "steelblue", size = 3.2
      ) +
      geom_text(
        data = df, aes(x = as.numeric(Time_Bin), y = as.numeric(fct_rev(Day_Type)) - r - 0.18, label = paste0(round(Total), " pax")),
        color = "gray40", size = 3.2
      ) +
      annotate("rect", xmin = 0.6, xmax = 3.4, ymin = 1.5, ymax = 4.4, alpha = 0.1, color = "#2a475e", fill = "#2a475e")
  })
  
  ### ---- Exploration Mode ----
  # Load exploration data with station-wise breakdown
  df_explore_21 <- read_csv("data/page_2.1_exploration_mode.csv") %>%
    mutate(
      Day_Type = factor(
        Day_Type,
        levels = c("Normal Weekday", "Normal Weekend", "Public Holiday", "School Holiday"),
        ordered = TRUE
      ),
      Time_Bin = factor(
        Time_Bin,
        levels = c('00:00–04:00', '04:00–08:00', '08:00–12:00',
                   '12:00–16:00', '16:00–20:00', '20:00–00:00')
      )
    )
  
  # Update station selection dynamically
  observe({
    updateSelectInput(
      inputId = "Page21_stationSelect",
      choices = unique(df_explore_21$Station_Name),
      selected = unique(df_explore_21$Station_Name)[1]
    )
  })
  
  # Reactive filtered data 
  df_selected_station <- reactive({
    req(input$Page21_stationSelect)
    
    # Filter data for chosen station and calculate radii
    df_filtered <- df_explore_21 %>%
      filter(Station_Name == input$Page21_stationSelect) %>%
      mutate(
        Total = Boardings + Alightings,
        r = sqrt(Total) / sqrt(max(Total)) * 0.35
      )
    
    # Reshape and compute arc geometry
    df_long <- df_filtered %>%
      pivot_longer(cols = c(Boardings, Alightings), names_to = "Type", values_to = "Value") %>%
      group_by(Day_Type, Time_Bin) %>%
      mutate(
        prop = Value / sum(Value),
        start = cumsum(lag(prop, default = 0)) * 2 * pi,
        end = cumsum(prop) * 2 * pi,
        mid = (start + end) / 2
      ) %>%
      ungroup() %>%
      mutate(
        x = as.numeric(Time_Bin),
        y = as.numeric(fct_rev(Day_Type))
      )
    
    list(df = df_filtered, df_long = df_long)
  })
  
  
  # Plot selected station's data
  output$Page21_explorePlot <- renderPlot({
    df_data <- df_selected_station()
    df <- df_data$df
    df_long <- df_data$df_long
    
    ggplot(df_long) +
      geom_arc_bar(aes(x0 = x, y0 = y, r0 = 0, r = r,
                       start = start, end = end, fill = Type),
                   color = "white", size = 0.3, alpha = 0.9) +
      scale_fill_manual(values = c("Boardings" = "steelblue", "Alightings" = "darkorange")) +
      scale_x_continuous(breaks = 1:6, labels = levels(df$Time_Bin), expand = expansion(mult = 0.1)) +
      scale_y_continuous(breaks = 1:4, labels = rev(levels(df$Day_Type)), expand = expansion(mult = 0.1)) +
      labs(
        x = "Time of Day", y = "Day Type", fill = "Flow Type",
        title = paste("Hourly Passenger Volume Composition at", input$Page21_stationSelect, "Station")
      ) +
      theme_minimal(base_family = "roboto") +
      theme(
        plot.title = element_text(size = 17, face = "bold", color = "#2a475e"),
        axis.title = element_text(size = 13, face = "bold"),
        legend.title = element_text(size = 13, face = "bold"),
        legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)
      ) +
      geom_text(
        data = df,
        aes(x = as.numeric(Time_Bin),
            y = as.numeric(fct_rev(Day_Type)) - r - 0.075,
            label = paste0(round(100 * Boardings / (Boardings + Alightings)), "%")),
        color = "steelblue", size = 3.2
      ) +
      geom_text(
        data = df,
        aes(x = as.numeric(Time_Bin),
            y = as.numeric(fct_rev(Day_Type)) - r - 0.18,
            label = paste0(round(Boardings + Alightings), " pax")),
        color = "gray40", size = 3.2
      )
  })
  
  
  ## ---- Page 2.2 ----
  
  # Render a chord diagram showing OD (Origin-Destination) passenger flows
  output$Page22_cityloopChord <- renderChorddiag({
    # Load OD matrix CSV file
    od_df <- read.csv("data/page_2.2_cityloop_od_matrix.csv", row.names = 1, check.names = FALSE)
    
    # Trim whitespace in column and row names
    colnames(od_df) <- trimws(colnames(od_df))
    rownames(od_df) <- trimws(rownames(od_df))
    
    # Convert to matrix format
    od_matrix <- as.matrix(od_df)
    
    # Fix station order to ensure consistent visual layout
    custom_order <- c("Flagstaff", "Southern Cross", "Melbourne Central", "Parliament", "Richmond", "Flinders Street")
    od_matrix <- od_matrix[custom_order, custom_order]
    
    # Generate chord diagram with styling options
    chorddiag(od_matrix,
              palette = "Set3",
              tooltipUnit = " people",
              tickInterval = 200000,
              ticklabelFontsize = 8,
              groupnameFontsize = 15,
              groupnamePadding = 10,
              margin = 80)
  })
  
  
  ## ---- Page 2.3 ----
  ### ---- Story Mode ----
  
  # Render radar chart for the top 3 crowded stations
  output$Page23_top3Radar <- renderPlot({
    # Add Google font and enable text rendering
    # font_add_google("Roboto", "roboto")
    # showtext_auto()
    
    # Load station stats from geojson
    Station_Stats <- st_read("data/page_2.3_2.4_station_stats.geojson", quiet = TRUE)
    
    # Select top 3 stations with highest crowding index
    top3 <- Station_Stats %>%
      arrange(desc(Crowding_Index)) %>%
      slice(1:3) %>%
      st_drop_geometry() %>%
      select(
        Station_Name,
        `Peak Hour Volume` = norm_peak_volume,
        `Passenger Volume\nper Platform` = norm_per_platform_volume,
        `Train Count per Platform` = norm_per_platform_trains,
        `Passenger Volume\nper Train` = norm_per_train_volume
      )
    
    # Normalize values for radar chart and rename group
    radar_data <- top3 %>%
      mutate(across(-Station_Name, rescale)) %>%
      rename(group = Station_Name)
    
    # Generate radar chart using ggradar
    plt <- radar_data %>%
      ggradar(
        font.radar = "roboto",
        grid.label.size = 5,
        axis.label.size = 5,
        group.point.size = 3,
        group.line.width = 1.8,
        group.colours = c("#F8766D", "#FDCB6E", "#00B894"),
        fill.alpha = 0.25
      ) +
      labs(title = "Top 3 Stations' SCI Dimensions") +
      coord_equal(clip = "off") +
      theme(
        text = element_text(family = "roboto"),
        plot.title.position = "plot",
        plot.title = element_textbox_simple(
          size = 20,
          face = "bold",
          color = "#2a475e",
          hjust = 0,
          margin = margin(l = -42, unit = "pt"),
          width = unit(1, "npc")
        ),
        legend.position = c(1.1, 0),
        legend.justification = c(1, 0),
        legend.text = element_text(size = 15, family = "roboto"),
        legend.key = element_rect(fill = NA, color = NA),
        legend.background = element_blank()
      )
    
    # Print radar plot
    print(plt)
  })
  
  
  ### ---- Exploration Mode ----
  
  # Load and preprocess station stats (no geometry)
  station_stats_data <- st_read("data/page_2.3_2.4_station_stats.geojson", quiet = TRUE) %>%
    st_drop_geometry()
  
  # Extract list of all station names
  all_stations <- station_stats_data$Station_Name
  
  # Determine the median station by crowding index
  median_station_name <- station_stats_data %>%
    arrange(Crowding_Index) %>%
    slice(ceiling(n() / 2)) %>%
    pull(Station_Name)
  
  # Initialize select input with station names
  updateSelectizeInput(
    session, 
    "page23_station_select",
    choices = all_stations,
    server = TRUE
  )
  
  # Reactive expression for selected station(s) data
  selected_station_data <- reactive({
    selected <- input$page23_station_select
    if (is.null(selected) || length(selected) == 0) {
      return(NULL)
    }
    
    station_stats_data %>%
      filter(Station_Name %in% selected) %>%
      mutate(group = Station_Name) %>%
      select(
        group,
        `Peak Hour Volume` = norm_peak_volume,
        `Passenger Volume\nper Platform` = norm_per_platform_volume,
        `Train Count per Platform` = norm_per_platform_trains,
        `Passenger Volume\nper Train` = norm_per_train_volume
      )
  })
  
  # Reactive expression for median (reference) station
  reference_station_data <- reactive({
    station_stats_data %>%
      filter(Station_Name == median_station_name) %>%
      mutate(group = "Reference (Median)") %>%
      select(
        group,
        `Peak Hour Volume` = norm_peak_volume,
        `Passenger Volume\nper Platform` = norm_per_platform_volume,
        `Train Count per Platform` = norm_per_platform_trains,
        `Passenger Volume\nper Train` = norm_per_train_volume
      )
  })
  
  # Render radar chart for selected stations and optional reference
  output$Page23_radar_explore <- renderPlot({
    selected <- input$page23_station_select
    show_ref <- input$page23_show_reference
    
    # If nothing is selected, show placeholder message
    if (is.null(selected) || length(selected) == 0) {
      return(
        ggplot(data.frame(x = 0, y = 0)) +
          geom_text(aes(x, y, label = "No stations selected"), size = 6, color = "gray50") +
          theme_void()
      )
    }
    
    # Get radar data from reactive
    radar_data <- selected_station_data()
    
    # Optionally append reference station data
    if (input$page23_show_reference) {
      radar_data <- bind_rows(radar_data, reference_station_data())
    }
    
    # Define color scheme depending on reference inclusion
    color_vec <- c("#F8766D", "#FDCB6E", "#00B894")
    if (input$page23_show_reference) {
      color_vec <- c(color_vec[1:nrow(selected_station_data())], "grey60")
    } else {
      color_vec <- color_vec[1:nrow(selected_station_data())]
    }
    
    # Plot radar chart
    ggradar(
      radar_data,
      font.radar = "roboto",
      grid.label.size = 5,
      axis.label.size = 5,
      group.point.size = 3,
      group.line.width = 1.8,
      group.colours = color_vec,
      fill.alpha = 0.25
    ) +
      labs(title = "Exploration of SCI Dimensions") +
      coord_equal(clip = "off") +
      theme(
        text = element_text(family = "roboto"),
        plot.title.position = "plot",
        plot.title = ggtext::element_textbox_simple(
          size = 20,
          face = "bold",
          color = "#2a475e",
          hjust = 0,
          margin = margin(l = -42, unit = "pt"),
          width = unit(1, "npc")
        ),
        legend.position = c(1.1, 0),
        legend.justification = c(1, 0),
        legend.text = element_text(size = 15),
        legend.background = element_blank()
      )
  })
  
  
  # Display detailed info about selected stations (and reference)
  output$Page23_station_info <- renderText({
    selected <- input$page23_station_select
    if (is.null(selected) || length(selected) == 0) return("No station selected.")
    
    # Selected station stats
    result <- station_stats_data %>%
      filter(Station_Name %in% selected) %>%
      mutate(across(starts_with("norm_"), ~ round(.x, 3))) %>%
      mutate(
        display = paste0(
          Station_Name, " — SCI: ", round(Crowding_Index, 2), "\n",
          "  Peak Hour Volume: ", norm_peak_volume, "\n",
          "  Passenger Volume per Platform: ", norm_per_platform_volume, "\n",
          "  Train Count per Platform: ", norm_per_platform_trains, "\n",
          "  Passenger Volume per Train: ", norm_per_train_volume, "\n"
        )
      ) %>%
      pull(display)
    
    # Reference (median) station stats
    ref <- station_stats_data %>%
      filter(Station_Name == median_station_name) %>%
      mutate(across(starts_with("norm_"), ~ round(.x, 3))) %>%
      mutate(
        display = paste0(
          "Reference — ", Station_Name, " (Median SCI: ", round(Crowding_Index, 2), ")\n",
          "  Peak Hour Volume: ", norm_peak_volume, "\n",
          "  Passenger Volume per Platform: ", norm_per_platform_volume, "\n",
          "  Train Count per Platform: ", norm_per_platform_trains, "\n",
          "  Passenger Volume per Train: ", norm_per_train_volume, "\n"
        )
      ) %>%
      pull(display)
    
    # Combine and return display text
    paste(c(result, ref), collapse = "\n")
  })
  
  
  # Reset button behavior: clear selected stations and reference toggle
  observeEvent(input$page23_reset, {
    updateSelectizeInput(
      session,
      "page23_station_select",
      selected = character(0)  # Clear selection
    )
    
    updateCheckboxInput(session, "page23_show_reference", value = FALSE)
  })
  
  ## ---- Page 2.4 ----
  
  # Load train line geometries from a GeoJSON file
  Line_Dataset <- st_read("data/page_2.4_train_lines_reference.geojson", quiet = TRUE)
  
  # Load precomputed train line label points with geometry
  Line_Labels <- readRDS("data/page_2.4_train_line_labels.rds")
  
  # Extract longitude and latitude of label end points for plotting
  Line_Labels_coords <- Line_Labels %>%
    mutate(
      lon = st_coordinates(end_point)[,1],
      lat = st_coordinates(end_point)[,2]
    ) %>%
    st_drop_geometry()
  
  ### ---- Story Mode ----
  output$Page24_leafletMap <- renderLeaflet({
    # Load station statistics including crowding index and type
    Station_Stats <- st_read("data/page_2.4_station_stats_with_station_type.geojson", quiet = TRUE)
    
    # Create a color palette for crowding index (SCI)
    pal <- colorNumeric(palette = "inferno", domain = Station_Stats$Crowding_Index, reverse = TRUE)
    
    # Construct base leaflet map
    leaflet() %>%
      addProviderTiles("CartoDB.Positron") %>%
      setView(lng = 144.9631, lat = -37.8136, zoom = 12) %>%
      
      # Add train lines as polylines
      addPolylines(data = Line_Dataset,
                   color = "grey",
                   weight = 2,
                   opacity = 1,
                   group = "Train Lines") %>%
      
      # Add stations as circle markers, colored by crowding index and scaled by number of lines
      addCircleMarkers(
        data = Station_Stats,
        color = ~pal(Crowding_Index),
        radius = ~scales::rescale(N_Lines, to = c(6, 12)),
        fillOpacity = 1,
        stroke = FALSE,
        popup = ~paste0(
          "<div style='font-size:16px; font-weight:bold;'>", Station_Name, " Station", "</div>",
          "<div style='font-size:13px;'>",
          "<table style='border-collapse: collapse;'>",
          "<tr><td style='font-weight:bold; padding-right:8px;'>Crowding Index:</td><td>", round(Crowding_Index, 3), "</td></tr>",
          "<tr><td style='font-weight:bold; padding-right:8px;'>Metro Platforms:</td><td>", N_Metro_Platform, "</td></tr>",
          "<tr><td style='font-weight:bold; padding-right:8px;'>Lines Served:</td><td>", N_Lines, "</td></tr>",
          "<tr><td style='font-weight:bold; padding-right:8px;'>Station Type:</td><td>", Station_Type, "</td></tr>",
          "</table>",
          "</div>",
          "<img src='radar_png/", gsub(" ", "_", Station_Name), ".png' width='300px'>"
        )
      ) %>%
      
      # Add static labels for each train line using coordinates
      addLabelOnlyMarkers(data = Line_Labels_coords,
                          lng = ~lon,
                          lat = ~lat,
                          label = ~SHORT_NAME,
                          labelOptions = labelOptions(
                            noHide = TRUE,
                            direction = "auto",
                            textOnly = TRUE,
                            style = list(
                              "color" = "gray20",
                              "font-family" = "sans-serif",
                              "font-size" = "10px"
                            )
                          )) %>%
      
      # Add legend for crowding index
      addLegend("bottomright",
                pal = pal,
                values = Station_Stats$Crowding_Index,
                title = "SCI",
                opacity = 0.8) %>%
      
      # Add reset button to re-center map
      addEasyButton(easyButton(
        icon = "fa-rotate-right",
        title = "Reset Map",
        onClick = JS(glue::glue("
      function(btn, map) {{
        map.setView([-37.8136, 144.9631], 12);
      }}
    "))
      ))
  })
  
  ### ---- Exploration Mode ----
  
  # Handle reset button click to reset UI inputs
  observeEvent(input$page24_reset, {
    updateSelectInput(session, "page24_daytype", selected = "All")
    updateCheckboxInput(session, "page24_hour_enable", value = FALSE)
    updateSliderInput(session, "page24_hour", value = 0)
  })
  
  # Reactive expression to filter and aggregate data based on UI inputs
  df_filtered <- reactive({
    req(input$page24_daytype)
    
    if (input$page24_hour_enable) {
      if (input$page24_daytype == "All") {
        # When viewing by hour and all day types, average by station
        df_combined %>%
          filter(Arrival_Hour_Scheduled == input$page24_hour) %>%
          group_by(Station_Name) %>%
          summarise(Crowding_Index = mean(Crowding_Index, na.rm = TRUE), .groups = "drop")
      } else {
        # Filter by specific day type and hour
        df_combined %>%
          filter(Day_Type == input$page24_daytype,
                 Arrival_Hour_Scheduled == input$page24_hour)
      }
    } else {
      if (input$page24_daytype == "All") {
        # Average across all day types (hour disabled)
        df_combined %>%
          group_by(Station_Name) %>%
          summarise(Crowding_Index = mean(Crowding_Index, na.rm = TRUE), .groups = "drop")
      } else {
        # Filter by specific day type only
        df_combined %>%
          filter(Day_Type == input$page24_daytype) %>%
          group_by(Station_Name) %>%
          summarise(Crowding_Index = mean(Crowding_Index, na.rm = TRUE), .groups = "drop")
      }
    }
  })
  
  # Initial map rendering for Exploration Mode
  output$page24_explore_map <- renderLeaflet({
    # Aggregate data for initial view
    initial_data <- df_combined %>%
      group_by(Station_Name) %>%
      summarise(Crowding_Index = mean(Crowding_Index, na.rm = TRUE), .groups = "drop")
    
    # Join spatial metadata
    map_data <- station_meta %>%
      left_join(initial_data, by = "Station_Name")
    
    # Render leaflet map with markers and lines
    leaflet(data = map_data) %>%
      addProviderTiles("CartoDB.Positron") %>%
      setView(lng = 144.9631, lat = -37.8136, zoom = 12) %>% 
      addPolylines(data = Line_Dataset,
                   color = "grey",
                   weight = 2,
                   opacity = 1,
                   group = "Train Lines") %>% 
      addLabelOnlyMarkers(data = Line_Labels_coords,
                          lng = ~lon,
                          lat = ~lat,
                          label = ~SHORT_NAME,
                          labelOptions = labelOptions(
                            noHide = TRUE,
                            direction = "auto",
                            textOnly = TRUE,
                            style = list(
                              "color" = "gray20",
                              "font-family" = "sans-serif",
                              "font-size" = "10px"
                            )
                          )) %>%
      addCircleMarkers(
        lng = ~Longitude, lat = ~Latitude,
        radius = ~scales::rescale(N_Lines, to = c(6, 12)),
        fillColor = ~ifelse(is.na(Crowding_Index), "lightgray", pal(Crowding_Index)),
        color = NA,
        fillOpacity = 1,
        stroke = FALSE,
        popup = ~paste0(
          "<div style='font-size:16px; font-weight:bold;'>", Station_Name, " Station", "</div>",
          "<div style='font-size:13px;'>",
          "<b>Crowding Index:</b> ", round(Crowding_Index, 3), "<br/>",
          "<b>Metro Platforms:</b> ", N_Metro_Platform, "<br/>",
          "<b>Lines Served:</b> ", N_Lines, "<br/>",
          "<b>Station Type:</b> ", Station_Type, "</div>",
          "<img src='radar_png/", gsub(" ", "_", Station_Name), ".png' width='300px'>"
        )
      ) %>%
      addLegend("bottomright",
                pal = pal,
                values = df_combined$Crowding_Index,
                title = "SCI",
                opacity = 0.8) %>%
      addEasyButton(easyButton(
        icon = "fa-rotate-right",
        title = "Reset Map",
        onClick = JS("
      function(btn, map) {
        map.setView([-37.8136, 144.9631], 12);
      }
    ")
      ))
  })
  
  # Update map dynamically when filtered data changes
  observe({
    df_display <- df_filtered() %>%
      select(Station_Name, Crowding_Index)
    
    map_data <- station_meta %>%
      left_join(df_display, by = "Station_Name")
    
    leafletProxy("page24_explore_map") %>%
      clearMarkers() %>%
      clearControls() %>%
      addCircleMarkers(
        data = map_data,
        lng = ~Longitude, lat = ~Latitude,
        radius = ~scales::rescale(N_Lines, to = c(6, 12)),
        fillColor = ~ifelse(is.na(Crowding_Index), "lightgray", pal(Crowding_Index)),
        color = NA,
        fillOpacity = 1,
        stroke = FALSE,
        popup = ~paste0(
          "<div style='font-size:16px; font-weight:bold;'>", Station_Name, " Station", "</div>",
          "<div style='font-size:13px;'>",
          "<b>Crowding Index:</b> ", round(Crowding_Index, 3), "<br/>",
          "<b>Metro Platforms:</b> ", N_Metro_Platform, "<br/>",
          "<b>Lines Served:</b> ", N_Lines, "<br/>",
          "<b>Station Type:</b> ", Station_Type, "</div>",
          "<img src='radar_png/", gsub(" ", "_", Station_Name), ".png' width='300px'>"
        )
      ) %>%
      addLegend("bottomright",
                pal = pal,
                values = df_combined$Crowding_Index,
                title = "SCI",
                opacity = 0.8)
  })
  
  ## ---- Page 2.5 ----
  ### ---- Story Mode ----
  
  # Load edge data from CSV
  filtered_edges <- read.csv("data/page_2.5_filtered_edges.csv", stringsAsFactors = FALSE)
  
  # Build nodes from unique "from" and "to" entries
  nodes <- data.frame(name = unique(c(filtered_edges$from, filtered_edges$to))) %>%
    mutate(id = 0:(n() - 1))  # Assign numeric IDs to nodes
  
  # Build links with source and target node IDs
  links <- filtered_edges %>%
    left_join(nodes, by = c("from" = "name")) %>%
    rename(source = id) %>%
    left_join(nodes, by = c("to" = "name")) %>%
    rename(target = id) %>%
    select(source, target, freq) %>%
    mutate(scaled_value = sqrt(freq))  # Scale frequency for visualization
  
  # Create an igraph object for network analysis
  g <- igraph::graph_from_data_frame(filtered_edges, directed = FALSE)
  
  # Define function to render the interactive force-directed network
  renderPage25Network <- function() {
    # Calculate node degree
    degree_df <- data.frame(name = V(g)$name, degree = degree(g))
    
    # Merge degree into node data and categorize into groups
    nodes_full <- nodes %>%
      left_join(degree_df, by = "name") %>%
      mutate(
        group = cut(degree, breaks = 5,
                    labels = c("Very Low", "Low", "Medium", "High", "Very High")),
        name = paste0(name, " (deg=", degree, ")")  # Add degree info to node label
      )
    
    # Generate color scale for node groups
    color_vector <- rev(viridisLite::inferno(10))[c(2, 4, 6, 8, 10)]
    color_map <- paste0("d3.scaleOrdinal().domain([", 
                        paste0('"', levels(nodes_full$group), '"', collapse = ","), "])",
                        ".range([\"", paste(color_vector, collapse = "\", \""), "\"])")
    
    # Render the network using forceNetwork
    forceNetwork(
      Links = links,
      Nodes = nodes_full,
      Source = "source",
      Target = "target",
      Value = "scaled_value",
      NodeID = "name",
      Nodesize = "degree",
      Group = "group",
      fontSize = 33,
      fontFamily = "sans-serif",
      zoom = TRUE,
      opacity = 1,
      opacityNoHover = 0.2,
      linkDistance = JS("function(d) { return 60 / Math.sqrt(d.value); }"),
      linkWidth = JS("function(d) { return Math.sqrt(d.value); }"),
      radiusCalculation = JS("Math.sqrt(d.nodesize) + 8"),
      colourScale = JS(color_map),
      charge = -200,
      legend = TRUE
    )
  }
  
  # Render the default full network plot
  output$Page25_networkPlot <- renderForceNetwork({
    renderPage25Network()
  })
  
  ### ---- Exploration Mode ----
  
  # Render default network when no nodes are removed
  output$Page25_networkPlot_removed <- renderForceNetwork({
    renderPage25Network()
  })
  
  # Default message when network is intact
  output$Page25_metrics_removed <- renderText({
    paste("No station removed. Network intact.")
  })
  
  # Reactively track user-selected nodes to remove
  selected_nodes_reactive <- reactive({
    input$page25_remove_node
  })
  
  # Monitor changes to selected nodes
  observe({
    selected_nodes <- selected_nodes_reactive()
    
    # If no nodes are selected, render the full default network
    if (is.null(selected_nodes) || length(selected_nodes) == 0) {
      output$Page25_networkPlot_removed <- renderForceNetwork({
        renderPage25Network()
      })
      output$Page25_metrics_removed <- renderText({
        "No station removed. Network intact."
      })
      return()
    }
    
    # If nodes are selected, remove them and rebuild subgraph
    updated_edges <- filtered_edges %>%
      filter(!(from %in% selected_nodes | to %in% selected_nodes))
    
    g_removed <- graph_from_data_frame(updated_edges, directed = FALSE)
    
    # Rebuild nodes and links from updated edge list
    nodes_removed <- data.frame(name = unique(c(updated_edges$from, updated_edges$to))) %>%
      mutate(id = 0:(n() - 1))
    
    links_removed <- updated_edges %>%
      left_join(nodes_removed, by = c("from" = "name")) %>%
      rename(source = id) %>%
      left_join(nodes_removed, by = c("to" = "name")) %>%
      rename(target = id) %>%
      select(source, target, freq) %>%
      mutate(scaled_value = sqrt(freq))
    
    # Recalculate degree and groupings
    degree_df <- data.frame(name = V(g_removed)$name, degree = degree(g_removed))
    nodes_full <- nodes_removed %>%
      left_join(degree_df, by = "name") %>%
      mutate(
        group = cut(degree, breaks = 5,
                    labels = c("Very Low", "Low", "Medium", "High", "Very High")),
        name = paste0(name, " (deg=", degree, ")")
      )
    
    # Rebuild color scale for the updated graph
    color_vector <- rev(inferno(10))[c(2, 4, 6, 8, 10)]
    color_map <- paste0("d3.scaleOrdinal().domain([", 
                        paste0('"', levels(nodes_full$group), '"', collapse = ","), "])",
                        ".range([\"", paste(color_vector, collapse = "\", \""), "\"])")
    
    # Render updated subgraph after node removal
    output$Page25_networkPlot_removed <- renderForceNetwork({
      forceNetwork(
        Links = links_removed,
        Nodes = nodes_full,
        Source = "source",
        Target = "target",
        Value = "scaled_value",
        NodeID = "name",
        Nodesize = "degree",
        Group = "group",
        fontSize = 30,
        fontFamily = "sans-serif",
        zoom = TRUE,
        opacity = 1,
        opacityNoHover = 0.2,
        linkDistance = JS("function(d) { return 60 / Math.sqrt(d.value); }"),
        linkWidth = JS("function(d) { return Math.sqrt(d.value); }"),
        radiusCalculation = JS("Math.sqrt(d.nodesize) + 8"),
        colourScale = JS(color_map),
        charge = -200,
        legend = TRUE
      )
    })
    
    # Recalculate and display new metrics for the subgraph
    output$Page25_metrics_removed <- renderText({
      avg_deg <- round(mean(degree(g_removed)), 2)
      avg_path <- if (is.connected(g_removed)) round(average.path.length(g_removed), 2) else "N/A (Disconnected)"
      diam <- if (is.connected(g_removed)) diameter(g_removed) else "N/A"
      cluster <- round(transitivity(g_removed, type = "average"), 3)
      
      paste(
        "Removed:", paste(selected_nodes, collapse = ", "), "\n",
        "Average Degree:", avg_deg, "\n",
        "Clustering Coefficient:", cluster, "\n",
        "Average Shortest Path Length:", avg_path, "\n",
        "Diameter:", diam
      )
    })
  })
  
  # Reset button: clears selections and restores default view
  observeEvent(input$reset_node, {
    updateSelectizeInput(session, "page25_remove_node", selected = character(0))
    
    output$Page25_networkPlot_removed <- renderForceNetwork({
      renderPage25Network()
    })
    
    output$Page25_metrics_removed <- renderText({
      paste("No station removed. Network intact.")
    })
  })
  
  
  
  ## ---- End of Page 2 ----
  observeEvent(input$back_page1, {
    updateTabsetPanel(session, "main_nav", selected = "Line-Level Analysis")
    session$sendCustomMessage("scrollToTop", "go")
  })
  
  observeEvent(input$next_page3, {
    updateTabsetPanel(session, "main_nav", selected = "About Project")
    session$sendCustomMessage("scrollToTop", "go")
  })
  
  ## ---- End of Page 3 ----
  
  observeEvent(input$back_page2, {
    updateTabsetPanel(session, "main_nav", selected = "Station-Level Analysis")
    session$sendCustomMessage("scrollToTop", "go")
  })
  
  observeEvent(input$back_home2, {
    updateTabsetPanel(session, "main_nav", selected = "Home")
    session$sendCustomMessage("scrollToTop", "go")
  })
  
})
