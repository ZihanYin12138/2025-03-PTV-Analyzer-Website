# library(shiny)
# library(shinythemes)
# library(tidyverse)
# library(chorddiag)
# library(networkD3)
# library(igraph)
# library(shinyjs)
# library(sf)
# library(viridisLite)
# library(ggforce)
# library(leaflet)
# library(ggridges)
# library(scales)
# library(chorddiag)

# Load required data file for later use
filtered_edges <- read.csv("data/page_2.5_filtered_edges.csv", stringsAsFactors = FALSE)

# Define the Shiny UI
shinyUI(
  fluidPage(
    useShinyjs(), # Enables use of JavaScript extensions in Shiny
    
    # JS: Warn user if browser zoom is not at 100%
    tags$script(HTML("
      $(document).ready(function(){
        var zoomLevel = Math.round(window.devicePixelRatio * 100);
        if (zoomLevel !== 100){
          alert('Your browser zoom is currently set to ' + zoomLevel + '%.\\n\\nFor best visual experience, please reset it to 100% using Ctrl+0.');
        }
      });
    ")),
    
    # JS: Custom handler to scroll to top
    tags$script(HTML("
      Shiny.addCustomMessageHandler('scrollToTop', function(message) {
        window.scrollTo({ top: 0, behavior: 'smooth' });
      });
    ")),
    
    
    # JS: Automatically scroll to top when navbar tab is changed
    tags$script(HTML("
      $(document).on('shown.bs.tab', 'ul.nav li a[data-toggle=\"tab\"]', function(event) {
        var targetId = $(event.target).closest('ul').attr('id');
        if (targetId === 'main_nav') {
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }
      });
    ")),
    
    # Define consistent header styles for text
    tags$style(HTML("
      h1 { font-size: 42px; }
      h2 { font-size: 36px; }
      h3 { font-size: 30px; }
      h4 { font-size: 22px; }
      p  { font-size: 16px; line-height: 1.6; }
    ")),
  
  # Main navigation bar setup
  navbarPage(
    title = "PTV Analyzer",
    theme = shinytheme("united"),  # Apply visual theme
    position = "fixed-top",        # Fix the navbar to the top
    id = "main_nav",
    
    # ---- Page 0 - Home Page----
    tabPanel("Home",
      tags$style(type = "text/css", "body {padding-top: 70px;}"),  # Offset content to avoid overlap with navbar
      fluidPage(
      fluidRow(
       column(12, h1("Public Transport Victoria (PTV) Analyzer"),
              h3(tags$em("Analysing Commuting Trends and Challenges in Melbourne's Rail Network")))
      ),
      
      # Project Introduction and interactive panel grid
      fluidRow(
        column(9, 
          br(),
          p("Melbourne’s rail system is one of the city’s most important transport infrastructures, serving millions of commuters every year. However, issues such as directional crowding, supply-demand imbalance, and inconsistent service frequency remain persistent challenges—especially during peak hours at major stations.

This project investigates these challenges using a comprehensive dataset from the Victorian Government, covering all metropolitan train lines, stations, and hourly-level passenger counts from July 2023 to June 2024. The data is further enriched with weather and spatial context to uncover what shapes commuter behaviour.

By combining statistical analysis and interactive visualisation, this dashboard delivers both a narrative and exploratory interface tailored for transport planners and service optimisation analysts. It aims to support data-informed decision-making for improving rail efficiency and passenger experience across Melbourne’s network."),
          
          
          br(),
      # Subpage previews in 3-column layout
      fluidRow(
       column(4,
              div(
                style = "
                  background-color: white;
                  padding: 15px;
                  margin-bottom: 20px;
                  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
                  border-radius: 8px;
                  transition: transform 0.2s;
                  height: 420px
                ",
                tags$img(src = "img1.jpg", style = "height: 180px; width: 100%; object-fit: cover; border-radius: 5px;"),
                actionLink("to_page1", h4("Train Line Level Analysis")),
                p("Examine overall passenger volumes and directional imbalances across Melbourne’s train lines. Explore how service frequency aligns—or fails to align—with actual demand throughout the day.")
                
       )),
       column(4,
              div(
                style = "
                  background-color: white;
                  padding: 15px;
                  margin-bottom: 20px;
                  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
                  border-radius: 8px;
                  transition: transform 0.2s;
                  height: 420px
                ",
              tags$img(
                src = "img2.jpg", 
                style = "height: 180px; width: 100%; object-fit: cover; border-radius: 10px;"
              ),
              actionLink("to_page2", h4("Train Station Level Analysis")),
              p("Investigate how crowding intensity varies by station, time, and direction. Dive into detailed analyses including spatial congestion patterns, passenger flow within the City Loop, and network robustness.")
              
       )),
       column(4,
              div(
                style = "
                  background-color: white;
                  padding: 15px;
                  margin-bottom: 20px;
                  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
                  border-radius: 8px;
                  transition: transform 0.2s;
                  height: 420px
                ",
              tags$img(
                src = "img3.jpg", 
                style = "height: 180px; width: 100%; object-fit: cover; border-radius: 10px;"
              ),
              actionLink("to_page3", h4("About Project")),
              p("Understand the project’s background, key terminologies, and data sources. This section also outlines the motivation and methodology behind the visualisation.")
            )
          )
        )
      ),
      # Right sidebar for contact and next steps
        column(3,
               h3("Contact Us"),
               p(tags$b("Created by: "), "Zihan Yin"),
               p(tags$u("zyin0036@student.monash.edu")),
               p(tags$b("Supervised by: "), "Shivangi Gheewala"),
               p(tags$u("shivangi.gheewala@monash.edu")),
               p(tags$b("Faculty of IT, Monash University")),
               
               br(),
               
               h3("What's next?"),
               p("I plan to deploy this R Shiny App on shinyapps.io in the near future. Once it's live, I’ll include the public link in my personal resume."),
               p("That way, anyone viewing my resume can easily access and explore this project online : )")
               
        )
      )
      )
    ),
    
    # ---- Page 1 Line-Level Analysis----
    tabPanel("Line-Level Analysis",
      fluidPage(
       h1("Train Line Level Analysis"),
       
       br(), br(), 
       
       # Introductory paragraph describing overall goal of this page
       fluidRow(
         column(
           width = 8,   
           p("This section presents a line-level analysis of Melbourne’s rail network, 
      focusing on ridership patterns, directional imbalances, and the alignment 
      between demand and service across different times of day. It includes machine 
      learning insights into key ridership drivers and provides interactive modules 
      to support data-informed decisions for service optimisation and urban transport 
      planning.", style = "font-size:18px;")
         ),
         column(width = 4)),
       
       br(), br(), br(),
       
       ## ---- Page 1.1 ----
       ### ---- Story Mode ----
       # Section showing directional ridership volume on each line
       h3("How Busy Are Melbourne’s Train Lines?"),
       h4(em("An overview of total boardings on each train line, separated by direction.")),
       tabsetPanel(
         tabPanel("Story Mode",
            br(),
            fluidRow(
              column(
                width = 8,
                plotOutput("page11_story_plot", height = "450px")  # Visualization: directional ridership on each line
              ),
              column(
                width = 4,
                div(
                  style = "height:450px; overflow-y: auto; padding-right: 10px;",
                  br(),
                  # Explanation of the plot: key insights and line-specific patterns
                  p("This chart displays the total number of passengers boarding on each metropolitan train line from July 2023 to June 2024, with values shown separately for both travel directions—towards and from Flinders Street Station."),
                  p("Lines such as Pakenham, Lilydale, and Craigieburn consistently record the highest boarding volumes, reflecting their importance in Melbourne's rail network. In contrast, shorter or less frequented lines like Alamein and Williamstown show significantly lower totals."),
                  p("Directional differences are also evident. For example, Pakenham and Cranbourne lines carry more passengers towards Flinders, while Mernda, Hurstbridge, and Glen Waverley carry more in the opposite direction."),
                  p("These observations help highlight not only the busiest corridors in the network but also directional imbalances in passenger distribution, which may point to peak-hour demand, commuting trends, or service design considerations.")
                )
              )
            )
         ),
         
         ### ---- Exploration Mode ----
         # Interactive module for exploring ridership by time and direction
         tabPanel("Exploration Mode",
            br(),
            fluidRow(
              column(
                width = 8,
                plotOutput("page11_exploration_plot", height = "450px")  # Updated plot according to user inputs
              ),
              column(
                width = 4,
                div(style = "height:450px; overflow-y: auto; padding-right: 10px;",
                    h4("Explore Passengers Boarding by Time and Direction"),
                    br(),
                    # Dropdown to filter by day type
                    selectInput(
                      inputId = "page11_daytype",
                      label = "Select Day Type:",
                      choices = c("All", "Normal Weekday", "Normal Weekend", "Public Holiday", "School Holiday"),
                      selected = "All"
                    ),
                    # Dropdown to filter by time period
                    selectInput(
                      inputId = "page11_timebin",
                      label = "Select Time Period:",
                      choices = c("All", "00:00-04:00", "04:00-08:00", "08:00-12:00", "12:00-16:00", "16:00-20:00", "20:00-00:00"),
                      selected = "All"
                    ),
                    # Option to sort lines by directional difference
                    checkboxInput(
                      inputId = "page11_sortbydiff",
                      label = "Sort by Directional Difference",
                      value = FALSE
                    ),
                    # Reset button for filter controls
                    actionButton(
                      inputId = "page11_reset",
                      label = "Reset",
                      icon = icon("redo"),
                      class = "btn btn-outline-secondary"
                    ),
                    br(), br(),
                    # Description of how to use filters and what they reveal
                    p(em("This panel allows you to explore passenger loads by train line under different time-based and directional conditions.")),
                    p(em("You can filter by day types (e.g. weekday vs. weekend) and select specific time periods to examine travel intensity.")),
                    p(em("Check the sorting box to order lines by the difference between 'Towards Flinders' and 'From Flinders' passenger boardings. The numerical label in the figure will change from the total boardings to the difference in boardings in the two directions. The default is to sort by total boardings.")),
                    p("Note: Some lines may show very low volumes in off-peak periods such as late nights or holidays.")
                )
              )
            )
         )
       ),
       br(), br(), br(),
       
       ## ---- Page 1.2 ----
       ### ---- Story Mode ----
       # Section focused on demand and supply alignment analysis across day
       h3("How Well Does the Supply Match the Demand Across the Day?"),
       h4(em("An investigation of temporal alignment between service frequency and passenger demand on selected train lines.")),
       
       tabsetPanel(
         #### ---- Story 1 ----
         # Passenger boarding density on top 3 lines
         tabPanel("Story 1",
            br(),
            fluidRow(
              column(
                width = 4,
                div(
                  style = "height:400px; overflow-y: auto; padding-left: 10px;",
                  br(),
                  p("To begin, we focus on the three busiest train lines in Melbourne in terms of annual passenger volumes: Pakenham, Lilydale, and Craigieburn."),
                  p("The chart displays the passenger boarding density across time of day. Each curve is a normalized distribution that reflects the relative boarding intensity over time, not absolute counts."),
                  p("These lines exhibit a sharp morning peak between 07:00–09:00, and a broader evening peak from 16:00–19:00, aligning with typical commuter travel patterns. Boarding activity is almost nonexistent between 00:00–04:00.")
                )
              ),
              column(
                width = 8,
                plotOutput("Page12_story1", height = "400px")  # Plot: passenger density
              )
            )
         ),
         
         #### ---- Story 2 ----
         # Train frequency density
         tabPanel("Story 2",
            br(),
            fluidRow(
              column(
                width = 4,
                div(
                  style = "height:400px; overflow-y: auto; padding-left: 10px;",
                  br(),
                  p("Building on the previous view of passenger demand, we now turn to the train frequency density for the same top three lines."),
                  p("This metric captures how service frequency is distributed throughout the day, using the same density framework."),
                  p("While morning and evening peaks remain visible, the curves are less sharply defined than the passenger boarding density. This reflects a more gradual change in service frequency, with trains spread more evenly across the day.")
                )
              ),
              column(
                width = 8,
                plotOutput("Page12_story2", height = "400px")  # Plot: frequency density
              )
            )
         ),
         
         #### ---- Story 3 ----
         # Overlay chart: boarding vs frequency
         tabPanel("Story 3",
            br(),
            fluidRow(
              column(
                width = 4,
                div(
                  style = "height:500px; overflow-y: auto; padding-left: 10px;",
                  br(),
                  p("This chart overlays both train frequency and passenger boarding density curves for the top three lines to examine the alignment between supply and demand."),
                  p("The interpretation relies on curve height within each line: if the orange (boarding) curve exceeds the blue (frequency) curve, demand outweighs supply; if the reverse is true, it indicates potential oversupply."),
                  p("These three lines all demonstrate pronounced under-supply during peak hours, especially between 07:00–09:00 and 16:00–19:00. Outside these periods, the alignment is generally more balanced. This pattern reflects a broader system-wide tendency across most lines in Melbourne.")
                )
              ),
              column(
                width = 8,
                plotOutput("Page12_story3", height = "500px")  # Plot: overlay boarding vs supply
              )
            )
         ),
         
         #### ---- Story 4 ----
         # Special case study: Alamein and Richmond/Loop
         tabPanel("Story 4",
            br(),
            fluidRow(
              column(
                width = 4,
                div(style = "height:500px; overflow-y: auto; padding-left: 10px;",
                    br(),
                    p("Shifting focus from the top three lines, we highlight two lines with distinct supply-demand patterns: Alamein and Richmond and City Loop (shared section)."),
                    p("The Alamein line displays misalignment throughout the day. There is significant under-supply during the morning peak, over-supply around midday, and again under-supply during the evening peak, indicating potential inefficiencies in scheduling."),
                    p("In contrast, the Richmond and City Loop line is the only route to achieve near-perfect alignment during the morning peak, with almost complete overlap between demand and supply curves. However, a mismatch still emerges in the evening period.")
                )
              ),
              column(
                width = 8,
                plotOutput("Page12_story4", height = "500px")  # Plot: Alamein vs Richmond case
              )
            )
         ),
         
         ### ---- Exploration Mode ----
         # User-driven supply-demand matching chart by day type
         tabPanel("Exploration Mode",
            br(),
            fluidRow(
              column(
                width = 4,
                h4("Explore Supply-Demand Match by Day Type"),
                br(),
                # Dropdown for selecting day type
                selectInput("Page12_daytype", "Choose Day Type:",
                            choices = c("All", "Normal Weekday", "Normal Weekend", "Public Holiday", "School Holiday"),
                            selected = "All"),
                br(),
                p(em("This chart shows how well train service frequency (supply) matches passenger boarding volume (demand) throughout the day.")),
                p(em("You can switch between day types to identify over- or under-serviced periods."))
              ),
              column(
                width = 8,
                div(style = "height:500px; overflow-y: auto; padding-left: 0px;",
                    plotOutput("Page12_explorePlot", height = "1500px")  # Long plot of all lines by type
                )
              )
            )
         )
       ),
       
       br(), br(), br(),
       
       ## ---- Page 1.3 ----
       ### ---- Story Mode ----
       # Model-based explanation: which variables affect ridership
       h3("What Are the Key Predictors of Train Ridership Volume?"),
       h4(em("Insights from machine learning model on hourly-level train boarding data combined with weather conditions.")),
       
       tabsetPanel(
         tabPanel("Story Mode",
            br(),
            fluidRow(
              column(
                width = 8,
                plotOutput("Page13_rfBarPlot", height = "450px")  # Feature importance bar chart from random forest
              ),
              column(
                width = 4,
                div(style = "height:450px; overflow-y: auto; padding-right: 10px;",
                    # Detailed explanation of key features and their effects
                    p("Using a random forest regression model trained on hourly boarding records and weather data, we ranked the top ten most influential features in predicting ridership volumes."),
                    p("Train frequency consistently ranks as the most important feature under both importance metrics—MSE Increase and Node Purity Increase—highlighting its central role in determining passenger volumes. It is followed by solar radiation and the proportion of trains heading inbound (\"Up Direction %\"). Solar radiation likely captures time-of-day effects, which are strongly correlated with peak travel demand."),
                    p("Relative humidity also shows considerable importance, potentially reflecting weather-induced changes in ridership, such as rainfall. Calendar-related features like day of week and day type exhibit moderately high MSE Increase scores but lower node purity contributions, indicating some variability in how consistently they help split the data."),
                    p("Other weather variables—air temperature, wind speed, vapour pressure, and atmospheric pressure—round out the top 10, though they contribute less consistently than internal operational factors."),
                    p("Together, these findings suggest that service attributes such as frequency and direction have the strongest influence on ridership levels, while environmental and calendar effects offer secondary predictive power.")
                )
              )
            )
         ),
         ### ---- Exploration Mode ----
         # Compare model outputs for feature importance
         tabPanel("Exploration Mode",
            br(),
            fluidRow(
              column(
                width = 8,
                plotOutput("Page13_explore_plot", height = "450px")  # Comparison chart: feature rankings across models
              ),
              column(
                width = 4,
                div(style = "height:450px; overflow-y: auto; padding-right: 10px;",
                    h4("Compare Feature Importance Across Models"),
                    br(),
                    # User can choose among 4 model types
                    radioButtons(
                      inputId = "Page13_model_choice",
                      label = "Choose Model for Feature Importance:",
                      choices = list(
                        "Random Forest: MSE Increase & Node Purity" = "rf",
                        "Decision Tree: MSE Reduction" = "dt",
                        "Linear Regression: Abs Value of Coefficients (using standardized data)" = "lm",
                        "Lasso Regression: Abs Value of Non-Zero Coefficients (using standardized data)" = "lasso"
                      ),
                      selected = "rf"
                    ),
                    br(),
                    # Instructions for interpreting model output differences
                    p(em("This panel allows you to explore how different modeling approaches—such as Random Forests, Decision Trees, and both Linear and Lasso Regression—rank the importance of features in predicting train boarding volumes.")),
                    p(em("Random Forest shows importance using two metrics: MSE Increase and Node Purity Increase. The other models display importance as the absolute value of either raw or regularized coefficients.")),
                    p(em("You can switch between models to observe which variables consistently rank high and which ones vary in importance. This comparison helps evaluate model stability and the robustness of key predictors."))
                )
              )
            )
         )
       ),
       
       ## ---- End of Page 1 ----
       br(), br(), br(),
       fluidRow(
         column(6, actionButton("back_home1", "← Back to Home")),  # Navigation to homepage
         column(6, align = "right", actionButton("next_page2", "Next →"))  # Navigation to Page 2
       ),
       br()
      )
    ),
    
    
    # ---- Page 2 Station-Level Analysis----
    tabPanel("Station-Level Analysis",
      fluidPage(
      h1("Train Station Level Analysis"),
      
      br(), br(), 
      
      # Introductory paragraph explaining the purpose of this page
      fluidRow(
      column(
        width = 8,   
        p("This section presents a station-level exploration of Melbourne's metropolitan 
          rail network, focusing on how passenger activity varies by time, space, and 
          structural factors. The analysis is structured into five complementary perspectives, 
          each targeting a specific aspect of station-level dynamics such as crowding, 
          directional flow, and network robustness. From time-based boarding patterns to 
          spatial congestion hotspots and structural vulnerabilities, these modules help 
          identify where and why station pressure emerges across the network. Interactive
          elements are provided to support data-informed decisions for service optimisation 
          and urban transport planning.", style = "font-size:18px;")
      ),
      column(width = 4)),
      
      br(), br(), br(),
      
      ### ---- Page 2.1 ----
      # Sub-section: Temporal boarding and alighting analysis
      h3("How Do Boardings and Alightings Vary Across Time?"),
      h4(em("A comparative analysis of boarding and alighting patterns using station-level average volumes.")),
      
      # Interactive tab panels for Story Mode and Exploration Mode
      tabsetPanel(
        #### ---- Story Mode 1 ----
        tabPanel("Story 1",
                 br(),
                 fluidRow(
                   column(
                     width = 8,
                     # Plot showing average passenger volumes by day type
                     plotOutput("Page21_story1", height = "300px")
                   ),
                   column(
                     width = 4,
                     # Corresponding narrative text for Story 1
                     div(
                       style = "height:300px; overflow-y: auto; padding-left: 10px;",
                       br(), br(),
                       p("Average passenger volumes at stations drop progressively from normal weekdays to weekends and further to public holidays. Public holiday traffic is approximately 60% of weekday levels, while school holidays exhibit intermediate volumes, closer to weekend patterns."),
                       p("Across all day types, the proportional split between boardings and alightings remains remarkably stable. This indicates a general structural balance in trip patterns regardless of the specific day classification.")
                     )
                   )
                 )
        ),
        
        #### ---- Story Mode 2 ----
        tabPanel("Story 2",
                 br(),
                 fluidRow(
                   column(
                     width = 8,
                     # Plot showing volume variation by time of day
                     plotOutput("Page21_story2", height = "300px")
                   ),
                   column(
                     width = 4,
                       br(),
                        # Narrative commentary for Story 2
                       p("While day type shows minimal change in boarding-alighting ratios, time of day introduces pronounced asymmetries."),
                       p("Passenger activity peaks between 16:00–20:00, followed by 08:00–12:00, reflecting typical evening and morning commute windows."),
                       p("Clear directional trends emerge at the day’s extremes: boardings dominate in the early morning (04:00–08:00), likely representing departure points at residential areas, while alightings exceed boardings between 00:00–04:00, consistent with late-night arrivals.")
                   )
                 )
        ),
        
        #### ---- Story Mode 3 ----
        tabPanel("Story 3",
                 br(),
                 fluidRow(
                   column(
                     width = 8,
                     # Plot showing passenger volume by time and day type
                     plotOutput("Page21_story3", height = "550px")
                   ),
                   column(
                     width = 4,
                     div(
                       style = "height:550px; overflow-y: auto; padding-left: 10px;",
                       br(),
                       p("By intersecting day type with time of day, we can uncover more nuanced patterns in station usage."),
                       p("The weekday evening period (16:00–20:00) records the highest intensity, with over 40 average boardings or alightings per train per station, underlining its importance as a critical commuting window."),
                       p("In stark contrast, public holidays during 00:00–04:00 show negligible movement—averaging only 4 passengers per train per station—highlighting a substantial demand dip during off-peak and non-working periods.")
                     )
                   )
                 )
        ),
        
        #### ---- Story Mode 4 ----
        tabPanel("Story 4",
                 br(),
                 fluidRow(
                   column(
                     width = 8,
                     # Focus on early morning volume by day type
                     plotOutput("Page21_story4", height = "550px")
                   ),
                   column(
                     width = 4,
                     div(
                       style = "height:550px; overflow-y: auto; padding-left: 10px;",
                       br(),
                       p("The 04:00–08:00 time bin reveals striking contrasts between day types."),
                       p("On weekdays, early-morning volumes are already significant—comparable to the mid-morning peak (08:00–12:00)—reflecting early-start commuter behavior."),
                       p("However, on weekends and public holidays, this early time bin resembles the very low volume window of 00:00–04:00, suggesting that peak activity begins substantially later on non-working days, likely due to delayed or reduced travel demand.")
                     )
                   )
                 )
        ),
        #### ---- Exploration Mode ----
        tabPanel("Exploration Mode",
                 br(),
                 fluidRow(
                   column(
                     width = 8,
                     # Interactive plot for specific station exploration
                     plotOutput("Page21_explorePlot", height = "550px")
                   ),
                   column(
                     width = 4,
                     h4("Explore a Specific Station"),
                     # UI controls for selecting station
                     p("Select one station to examine its hourly boarding and alighting patterns across all day types."),
                     selectInput("Page21_stationSelect", "Choose a station:",
                                 choices = NULL, selected = NULL),
                     p(em("The chart on the left shows the average hourly passenger flow composition (Boardings vs Alightings) 
           for the selected station, across 4 day types and 6 time bins.")),
                     p(em("You can try selecting different stations — you may notice that commuter patterns vary drastically across locations."))
                   )
                 )
        )
        
      ),
      br(),
      br(),
      br(),
      
      ## ---- Page 2.2 ----
      # Sub-section: City Loop flow analysis using Chord Diagram
      
      ### ---- Story Mode ----
      h3("How Do Passengers Move Between the Six City Loop Stations?"),
      h4(em('An estimation of inter-station flows based on boarding and alighting data from "Richmond and City Loop" train line.')),
      tabsetPanel(
        tabPanel("Story Mode",
          br(),
          fluidRow(
            column(
              width = 6,
              div(
                style = "height:450px; overflow-y: auto; padding-right: 10px;",
                # Text analysis of directional flows between City Loop stations
              p("The passenger flow patterns among the six City Loop stations reveal a strong directional 
                asymmetry, particularly dominated by outbound movements from Flinders Street. This station 
                alone contributes over 5.6 million trips to Southern Cross and nearly 3.3 million to Melbourne 
                Central, making it the most significant origin point within this corridor. In contrast, incoming 
                flows to Flinders Street are minimal, suggesting that for many passengers, it serves as a major 
                starting point rather than a destination."),
              p("Southern Cross and Melbourne Central also act as important intermediate transfer nodes, with 
                substantial outgoing flows to Parliament and Richmond respectively. However, these flows are 
                notably smaller in comparison to the volumes originating from Flinders Street. Parliament and 
                Flagstaff receive moderate volumes, often as downstream stops along key commuting paths. 
                Richmond appears to absorb a large volume of passengers from City Loop stations without returning 
                the same volume, precisely because those passengers transfer to other lines beyond the shared segment. This 
                reinforces Richmond's true function as a transfer hub, even if our OD matrix—bounded to a shared corridor—makes 
                it look like a terminal."),
              p("This chord diagram aggregates estimated inter-station flows based on individual train records
                within the 'Richmond and City Loop' line segment. The simulation logic uses passenger boarding
                and alighting data to infer directional travel pairs across trains with variable stopping patterns.
                The visualization excludes intra-station loops and focuses only on directional flows between
                distinct stations, offering a synthesized view of localized travel dynamics within the core of
                Melbourne's rail network.")
            )),
            column(
              width = 6,
              # Chord diagram output showing inter-station flows
              chorddiagOutput("Page22_cityloopChord", height = "450px")
            )
          )
          ),
        ### ---- Exploration Mode ----
          tabPanel("Exploration Mode",
            br(),
            fluidRow(
             column(
               width = 12,
               div(
                 style = "height:450px; overflow-y: auto; padding-right: 10px;",
                 # Placeholder for future interactive features 
               p("Exploration Mode is currently not available for this sub-section."),
               p("Our engineers are working hard to make this feature available as soon as possible."), 
               p("Thank you for your patience : )")
                     ))
               )
          )
        ),
        br(),
        br(),
        br(),
      
      ## ---- Page 2.3 ----
      ### ---- Story Mode ----
      h3("What Makes Some Stations More Crowded Than Others?"),
      h4(em("A comparison of the top 3 most crowded stations based on four normalised 
            dimensions inside station crowding index (SCI).")),
      
      # Tabs for story and exploration mode
      tabsetPanel(
        tabPanel("Story Mode",
                 br(),
                 fluidRow(
                   column(
                     width = 6,
                     # Radar chart comparing the top 3 crowded stations
                     plotOutput("Page23_top3Radar", height = "450px")
                   ),
                   column(
                     width = 6,
                     # Narrative text explaining SCI and radar chart interpretation
                     div(
                       style = "height:450px; overflow-y: auto; padding-right: 10px;",
                       p("To evaluate the extent of passenger crowding at train stations, we introduce a composite measure known as the Station Crowding Index (SCI). Rather than relying on a single metric, the SCI captures multiple dimensions of congestion—ranging from peak-time usage to platform and train capacity—offering a more nuanced view of station-level pressure."),
                       
                       p("The SCI is constructed from four normalized dimensions:"),
                       tags$ul(
                         tags$li("Peak Hour Volume: The average number of passengers during the weekday peak (16:00–20:00)"),
                         tags$li("Passenger Volume per Platform: A measure of spatial load, based on daily volume divided by the number of platforms"),
                         tags$li("Train Count per Platform: A proxy for train service frequency and operational density"),
                         tags$li("Passenger Volume per Train: The average load per service, reflecting pressure on individual vehicles")
                       ),
                       
                       p("Each of these dimensions is normalized to a [0, 1] range across all stations, and their unweighted average forms the final SCI score. A higher SCI value implies higher overall crowding pressure, whether due to demand, infrastructure limits, or service patterns."),
                       
                       p("The radar chart on the left visualizes these four components for the three most crowded stations according to SCI—Flinders Street, Southern Cross, and Melbourne Central. The shapes of their profiles highlight how crowding can stem from different operational realities."),
                       
                       p("Flinders Street stands out as the most congested station, with scores near the maximum across all dimensions. Its particularly high values in peak-hour volume and passenger-per-train suggest both spatial and service-level crowding. Southern Cross, by contrast, has relatively lower demand metrics but ranks high in train count per platform, indicating its crowding may be driven more by service concentration than passenger load. Melbourne Central presents a more balanced profile with consistently moderate scores, making it the least pressured among the three despite its central location."),
                       
                       p("This decomposition illustrates that crowding is not a one-dimensional problem. While some stations are overwhelmed by raw demand, others face structural limitations or service bottlenecks. Understanding these differences is crucial for prioritizing infrastructure upgrades and operational interventions.")
                       
                     )
                   )
                 )
        ),
        ### ---- Exploration Mode ----
        tabPanel("Exploration Mode",
           br(),
           fluidRow(
             column(
               width = 6,
               # Interactive radar chart for user-selected stations
               plotOutput("Page23_radar_explore", height = "450px")
             ),
             column(
               width = 6,
               # User input panel for selecting stations and showing comparison
               h4("Compare Three Stations' SCI"),
               p("This interactive module allows you to compare any three stations across 
                   four normalised crowding dimensions inside SCI."),
               p("You can optionally overlay a reference line representing the median-SCI 
                     station to assist with benchmarking."),
               br(),
               fluidRow(
                 column(
                   width = 6,
                   selectizeInput(
                     inputId = "page23_station_select",
                     label = "Select up to 3 Stations:",
                     choices = NULL,  # To be dynamically populated
                     selected = NULL,
                     multiple = TRUE,
                     options = list(maxItems = 3, placeholder = "Type to search...")
                   ),
                   # Optional reference line toggle
                   checkboxInput(
                     inputId = "page23_show_reference",
                     label = "Show Reference Line (Median-SCI Station)",
                     value = FALSE
                   ),
                   # Button to reset selection
                   actionButton("page23_reset", "Reset Selection"),
                   ),
                 column(
                   width = 6,
                   strong("Selected Station Statistics:"),
                   # Output panel for detailed station stats
                   div(
                     style = "height:300px; overflow-y: auto; padding-right: 10px;",
                   verbatimTextOutput("Page23_station_info")
                   )
                 )
             ))
           )
      )
        
      ),
      br(), br(), br(),
      
      ## ---- Page 2.4 ----
      ### ---- Story Mode ----
      # Section title and explanation of spatial SCI distribution
      h3("Where is Train Station Crowding Most Severe Across the Network?"),
      h4(em("An interactive map visualizing station crowding index (SCI) spatially across all Melbourne metropolitan stations.")),
         
      # Tabs for story and exploration mode
      tabsetPanel(
           tabPanel("Story Mode",
                    br(),
                    fluidRow(
                      column(
                        width = 4,
                        # Descriptive text explaining map insights
                        div(style = "height:600px; overflow-y: auto; padding-right: 10px;",
                          p("This map visualizes the SCI across Melbourne’s 
                            metropolitan rail system. The most crowded stations are 
                            clustered within the City Loop area—Flinders Street, Southern Cross, 
                            Melbourne Central, and nearby nodes—represented by nearly black circles. 
                            As we move away from the city center along most lines, 
                            station crowding generally decreases. This is reflected by lighter-colored 
                            circles, suggesting lower SCI values at outer suburban stations."),
                          p("An exception emerges at terminal stations such as Frankston, Glen Waverley, 
                            and Craigieburn, where SCI values rise slightly again. This implies that even 
                            distant terminals can experience local crowding due to line convergence or 
                            feeder traffic."),
                          p("Particularly notable are the overlapping segments of certain lines. The 
                            Cranbourne–Pakenham shared segment, for instance, exhibits a high concentration 
                            of orange-red stations, consistent with the earlier observation that the 
                            Pakenham line has the highest passenger volume. Similarly, the Belgrave–Lilydale 
                            and Werribee–Williamstown shared segments show concentrated crowding. In 
                            the north, the Craigieburn line also demonstrates relatively high SCI values 
                            compared to its neighboring lines."),
                          p("In this map, Each station is represented by a circle, where the color 
                            indicates the Station Crowding Index (SCI)—darker colors correspond to 
                            higher SCI—and the size reflects how many train lines serve 
                            that station. You can click on any station to view more information, 
                            including its SCI, number of metro platforms, number of lines served, 
                            station type, and a radar chart that compares its SCI contribution against 
                            a standard reference.")
                        )
                      ),
                      column(
                        width = 8,
                        # Leaflet map output showing SCI and interaction
                        leafletOutput("Page24_leafletMap", height = "600px")
                      )
                    )
           ),
           ### ---- Exploration Mode ----
           tabPanel("Exploration Mode",
                    br(),
                    fluidRow(
                      column(
                        width = 4,
                        # Controls for filtering SCI by day type and time
                        div(style = "height:600px; overflow-y: auto; padding-right: 10px;",
                        h4("Explore SCI Patterns Over Time"),
                        br(),
                        selectInput(
                          "page24_daytype", "Select Day Type:",
                          choices = c("All", "Normal Weekday", "Normal Weekend", "Public Holiday", "School Holiday"),
                          selected = "All"
                        ),
                        checkboxInput("page24_hour_enable", "Enable Hour-Level View", value = FALSE),
                        # Conditional time slider
                        conditionalPanel(
                          condition = "input.page24_hour_enable == true",
                          sliderInput(
                            "page24_hour", 
                            label = HTML("Select Hour of Day: <br><small><i>(e.g. 0 = 00:00, 8 = 08:00, 23 = 23:00)</i></small>"),
                            min = 0, max = 23, step = 1, value = 0,
                            ticks = TRUE,
                            animate = animationOptions(interval = 1000),
                            sep = ""
                          )
                        ),
                        # Button to reset filters
                        actionButton("page24_reset", "Reset to All Day"),
                        br(), br(), 
                        # Explanatory text
                        p(em("This interactive module allows you to explore how SCI varies across 
                        stations under different conditions.")),
                        p(em("Use the dropdown menu to select a day type (e.g. weekdays, weekends, holidays). 
                          Optionally, check the 'Enable Hour-Level View' box to reveal a time point slider.")),
                        p(em("The time point slider lets you examine how SCI evolves over the course of a 
                      day for the selected day type. From 00:00 to 23:00, each hour represents the start 
                        of an hourly period.")),
                        p(em("You can manually move the slider or click the yellow play button to animate it. 
                        This helps you observe overall changes and peak crowding periods across the 
                        city throughout the day.")),
                        p("Note: Some stations may not have data at specific times."),
                      )),
                      column(
                        width = 8,
                        # Output map with dynamic filters
                        leafletOutput("page24_explore_map", height = "600px")
                      )
                    )
           )
      ),
      br(), br(), br(),
    
      
      
      ## ---- Page 2.5 ----
      ### ---- Story Mode ----
      # Section title and network science summary
      h3("How Robust is Melbourne's Train Network?"),
      h4(em("A structural view of connectivity and criticality across stations using a network science approach.")),
      
      # tab set for story and exploration mode
      tabsetPanel(
        tabPanel("Story Mode",
                 br(),
                 fluidRow(
                   column(
                     width = 8,
                     # Interactive force-directed network graph
                     forceNetworkOutput("Page25_networkPlot", height = "550px")
                   ),
                   column(
                     width = 4,
                     # Text describing network robustness and centrality analysis
                     div(style = "height:550px; overflow-y: auto; padding-right: 10px;",
                       p("The overall structure of Melbourne’s metropolitan rail network, as represented here, 
                       exhibits a moderately connected system. The average degree of approximately 5.94 
                       suggests that most stations are linked to about six others, forming a relatively dense 
                       network for urban transit. However, the average clustering coefficient of 0.277 
                       indicates that localized connectivity (i.e., how well a station's neighbors are 
                       connected to one another) is limited, reflecting a hierarchy rather than a highly 
                       meshed topology. The average shortest path length of 4.5 and diameter of 12 imply 
                       that even in the worst case, passengers are no more than 12 transitions away from 
                       any other station—highlighting efficient overall accessibility."),
                       p("Several stations emerge as structurally central. Flinders Street stands out with both 
                       the highest degree (30) and the highest betweenness centrality (11,872), indicating it 
                       serves as a major connector in numerous shortest paths across the network. Other key 
                       transfer hubs include North Melbourne and Richmond, both combining high betweenness 
                       values with above-average degree, underlining their importance in cross-line movement. 
                       Southern Cross and Camberwell also appear frequently in shortest paths, despite more 
                       moderate degrees, suggesting strategic positioning rather than sheer connectivity volume."),
                       p("The current network shows a balance between centralization and redundancy. However, reliance 
                       on a few high-betweenness nodes makes the system vulnerable to targeted disruptions. 
                       In particular, the removal of stations like Flinders Street or Richmond could fragment the 
                       network or lengthen travel paths significantly. These observations motivate further testing 
                       in Exploration Mode, where users can simulate such removals and assess changes to structural 
                       metrics in real time."),
                       p("In this diagram, adjacency between stations is defined based on the actual stopping sequence 
                     of trains: if two stations appear consecutively in the route of the same train, an edge is established 
                     between them. To filter out anomalies or infrequent routes, we retain only those edges whose appearance 
                     frequency exceeds three times the average frequency of all adjacent connections for a given station. 
                       This method accounts for both physical adjacency (e.g., stations connected by track) and operational 
                       adjacency (e.g., express services that skip stations), providing a more realistic representation of 
                       the functioning rail network.")
                     )
                   )
        )),
        
        ### ---- Exploration Mode ----
        tabPanel("Exploration Mode",
                 br(),
                 fluidRow(
                   column(
                     width = 8,
                     # Updated network graph after removing selected stations
                     forceNetworkOutput("Page25_networkPlot_removed", height = "550px")
                   ),
                   column(
                     width = 4,
                     # UI for selecting stations to simulate removal
                     h4("Network Robustness Test"),
                     selectizeInput("page25_remove_node",
                                    label = "Select Up to 5 Stations to Remove:",
                                    choices = sort(unique(c(filtered_edges$from, filtered_edges$to))),
                                    selected = NULL,
                                    multiple = TRUE,
                                    options = list(
                                      maxItems = 5,
                                      placeholder = 'Type to search...',
                                      allowEmptyOption = TRUE
                                    )
                     )
                     ,
                     fluidRow(
                       column(width = 12, verbatimTextOutput("Page25_metrics_removed"))
                     ),
                     fluidRow(
                       column(width = 6, actionButton("reset_node", "Reset Selection"))
                     ),
                     br(),
                     # Description of robustness simulation logic
                     p(em("The interactive module above allows you to simulate the removal of up to five stations from the train network. 
                      By selecting stations from the list, you can observe how the structure of the network responds to targeted 
                      disruptions in real time. This tool helps transport planners assess the robustness of the network and identify 
                       critical nodes.")),
                     p(em("For example, removing five structurally important stations—Flinders Street, Richmond, South Yarra, Southern 
                       Cross, and Caulfield—may lead to network fragmentation. In some cases, certain stations become unreachable, 
                       highlighting the system’s sensitivity to targeted disruptions."))
                   )
                 ),
                 br(),
        )
      ),
      
      ## ---- End of Page 2 ----
      br(), br(), br(),
      fluidRow(
        column(6, actionButton("back_page1", "← Back")),
        column(6, align = "right", actionButton("next_page3", "Next →"))
      ),
      br(),
      br(),
      br()
      )
    ),
    
    # ---- Page 3 About Project----
    tabPanel("About Project",
      fluidPage(
      h1("About Project"),
      br(), br(),
      fluidRow(
        column(
          width = 8,  
          ## ----Project Background----
          # Description of project context and questions
          h3("Project Background"),
          p("This visualisation project is part of the FIT5147 Data Exploration and Visualisation unit at Monash University. It builds upon a prior data exploration project focused on analysing commuting trends and challenges in Melbourne’s metropolitan rail network.", style = "font-size:18px;"),
          p("The project was originally proposed to address two central research questions:", style = "font-size:18px;"),
          tags$ul(
            tags$li("How do train service frequency and passenger numbers fluctuate across different time periods, and what are the internal and external factors (e.g., weather conditions) that influence these variations?"),
            tags$li("What methods can be used to quantify station crowding? How do factors (e.g., time of day, station design, service frequency) contribute to station crowding, and which stations are most affected?"), style = "font-size:18px;"
          ),
          p("These two questions form the foundation of this dashboard. The 'Train Line Level Analysis' section focuses on Question 1, while the 'Train Station Level Analysis' section addresses Question 2.", style = "font-size:18px;"),
          p("The motivation behind this project arises from growing concerns around overcrowding, service reliability, and directional passenger imbalance, especially during peak hours. By analysing detailed train service data from July 2023 to June 2024, this dashboard aims to support transport planners and service optimisation analysts with actionable insights.", style = "font-size:18px;"),
          
          br(), br(), 
          
          ## ----Data Sources----
          # Dataset descriptions with external links
          h3("Data Sources"),
          div(style = "font-size:18px;",
              p(HTML("This project uses four open datasets obtained from <a href='https://opendata.transport.vic.gov.au/' target='_blank'>Transport Victoria Open Data Portal</a> and <a href='https://www.data.vic.gov.au/' target='_blank'>VIC.GOC.AU DataVic</a>. Together, they provide detailed passenger activity, weather context, and spatial references for Melbourne’s metropolitan rail network."), style = "font-size:18px;"), 
              
              tags$ul(
                tags$li( 
                  strong(HTML("<a href='https://opendata.transport.vic.gov.au/dataset/train-service-passenger-counts' target='_blank'>Train Service Passenger Counts</a> (July 2023 – June 2024):")),
                  " A large-scale CSV dataset (15.6 million rows) containing hourly-level boardings and alightings at each station, annotated by line, direction, and date. This dataset forms the backbone of our analysis."
                ),
                tags$li(
                  strong(HTML("<a href='https://discover.data.vic.gov.au/dataset/argyle-square-weather-stations-historical-data' target='_blank'>Argyle Square Weather Station Data</a> (May 2021 – July 2024):")),
                  " Hourly meteorological observations including temperature, humidity, wind speed, and solar radiation. Weather conditions are used to assess their impact on ridership patterns."
                ),
                tags$li(
                  strong(HTML("<a href='https://opendata.transport.vic.gov.au/dataset/public-transport-lines-and-stops' target='_blank'>Public Transport Stops</a> (GeoJSON, November 2024):")),
                  " Geospatial metadata for over 28,000 public transport stops across Victoria. This dataset is used to map station coordinates and integrate spatial context into the visualisations."
                ),
                tags$li(
                  strong(HTML("<a href='https://opendata.transport.vic.gov.au/dataset/public-transport-lines-and-stops' target='_blank'>Public Transport Lines</a> (GeoJSON, November 2024):")),
                  " Route geometries and identifiers for nearly 10,000 public transport services. It supports visualisation of train line paths and enables network-level analysis of connectivity and robustness."
                )
              )
          )
        ),
        column(width = 4)),
      
      br(), br(), 
      fluidRow(
       # column(12, align = "center", actionButton("go_home", "Go to Home Page"))
       column(6, actionButton("back_page2", "← Back")),
       column(6, align = "right", actionButton("back_home2", "Go to Home Page →"))
      ),
      br(), br(), br()
      )
    )
  ),
  
  # ---- Footer ----
  # Data source acknowledgments and copyright
  tags$footer(
    style = "background-color: #f8f9fa; padding: 20px; margin-top: 50px; border-top: 1px solid #dee2e6; font-size: 14px;",
    div(
      style = "text-align: center;",
      p(HTML("Data sources used in this project are publicly available from <a href='https://opendata.transport.vic.gov.au/' target='_blank'>Transport Victoria Open Data Portal</a> and <a href='https://www.data.vic.gov.au/' target='_blank'>VIC.GOC.AU DataVic</a>.")),
      p("© 2025 Zihan Yin – Monash University. This dashboard is created as FIT5147 Data Visualisation Project."),
      p("This is an academic project for demonstration and educational purposes only. The views expressed and visual interpretations do not represent official statements from any government agency.")
    )
  )
))
