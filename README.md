# Public Transport Victoria (PTV) Analyzer

[![R Shiny](https://img.shields.io/badge/Dashboard-R%20Shiny-blue.svg)](https://zyyin1.shinyapps.io/ptv_analyzer/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An interactive data visualization project analysing commuting trends, station crowding, and network robustness within Melbourne's metropolitan rail network.

---

### 🔗 Quick Links

* 🌐 **Live Website:** [PTV Analyzer Dashboard](https://zyyin1.shinyapps.io/ptv_analyzer/)
* 📄 **中文版 README:** [README.zh.md](README.zh.md)
* 📜 **DEP Proposal:** [DEP_Proposal_Version2.pdf](report/DEP_Proposal_Version2.pdf)
* 📊 **DEP Report:** [DEP_Report.pdf](report/DEP_Report.pdf)

---

## 📖 Project Overview

This repository contains the complete source code and documentation for the **PTV Analyzer**, a project developed as part of the FIT5147 unit at Monash University. The project is divided into two phases:

1.  **Data Exploration Project (DEP):** A comprehensive statistical analysis answering core research questions regarding train frequency, passenger volume fluctuations, and station crowding quantification. The findings are documented in the [DEP Report](report/DEP_Report.pdf).
2.  **Data Visualisation Project (DVP):** An interactive R Shiny web application built upon the findings of the DEP. It transforms static insights into an exploratory dashboard, allowing transport planners and general users to interact with the data through "Story Modes" and "Exploration Modes."

### Key Research Questions
The project addresses two primary questions:
1.  **Supply vs. Demand:** How do train service frequency and passenger numbers fluctuate across different time periods (and weather conditions)?
2.  **Station Crowding:** How can we quantify station crowding (via the custom *Station Crowding Index*), and which stations are most affected by factors like time of day and infrastructure?

---

## 📈 Key Findings (DEP)

Based on the statistical analysis conducted in the *Data Exploration Project*, several critical insights into Melbourne's rail network were uncovered:

* **Supply-Demand Mismatch:** While trunk lines (e.g., Pakenham, Lilydale) experience severe capacity shortages during morning (07:00–09:00) and evening peaks, branch lines like **Alamein** show significant oversupply during mid-day off-peak hours, highlighting scheduling inefficiencies.
* **Ridership Drivers:** Machine learning modeling (Random Forest) reveals that **Train Frequency** is the dominant predictor of passenger volume. Contrary to common belief, weather factors (rain, temperature) have a negligible impact on ridership, whereas **Solar Radiation** (acting as a proxy for time-of-day) ranks second.
* **The "City Loop" Bottleneck:** Using the custom *Station Crowding Index (SCI)*, City Loop stations (Flinders St, Southern Cross) show near-maximum crowding scores. However, the causes differ: Flinders Street is driven by **passenger volume**, while Southern Cross is driven by **service frequency intensity**.
* **Temporal Shifts:** Peak crowding occurs between 16:00–20:00 on weekdays. Notably, peak travel times shift significantly later on weekends and public holidays, with public holiday traffic volume averaging only **60%** of a normal weekday.

---

## 🖥️ Dashboard Features (DVP)

The R Shiny dashboard translates the above findings into an interactive experience, featuring two distinct interaction modes: **"Story Mode"** for guided narrative and **"Exploration Mode"** for free-form analysis.

### 🔍 Core Functionalities:
* **Interactive Supply-Demand Analysis:** Users can overlay train frequency density against passenger boarding density to visually identify service gaps across different lines and day types (Page 1.2).
* **Station Crowding Heatmap:** A geospatial visualization of the *Station Crowding Index (SCI)* across the network. Includes an **animated hourly slider** to observe how congestion hotspots migrate from suburbs to the city center throughout the day (Page 2.4).
* **Network Robustness Simulator:** An interactive network graph allowing users to simulate "station failures" (node removal). It calculates real-time metrics (e.g., Average Path Length, Diameter) to test the system's resilience against infrastructure disruptions (Page 2.5).
* **City Loop Flow Visualization:** An interactive **Chord Diagram** mapping the directional passenger flows between the six core City Loop stations, highlighting the dominance of outbound traffic from Flinders Street (Page 2.2).
* **Predictive Model Playground:** Allows users to toggle between Random Forest, Decision Tree, and Linear Regression models to see how different algorithms rank feature importance for ridership prediction (Page 1.3).

---

## 📂 Project Structure

Below is the file structure of the repository.

```text
2025-03-PTV-Analyzer-Website
├─ data                      # Data used for the Shiny website (Optimized/RDS format)
│  ├─ page_1.1_exploration_mode.rds
│  ├─ page_1.1_story_mode.rds
│  ├─ page_1.2_explore_public.rds
│  ├─ page_1.2_explore_school.rds
│  ├─ page_1.2_explore_weekday.rds
│  ├─ page_1.2_explore_weekend.rds
│  ├─ page_1.2_story_mode.rds
│  ├─ page_1.3_dt_importance.rds
│  ├─ page_1.3_lasso_importance.rds
│  ├─ page_1.3_lm_importance.rds
│  ├─ page_1.3_story_mode.rds
│  ├─ page_2.1_exploration_mode.csv
│  ├─ page_2.1_story1.csv
│  ├─ page_2.1_story2.csv
│  ├─ page_2.1_story3_story4.csv
│  ├─ page_2.2_cityloop_od_matrix.csv
│  ├─ page_2.3_2.4_station_stats.geojson
│  ├─ page_2.4_explore_mode_precomputed.rds
│  ├─ page_2.4_station_stats_with_station_type.geojson
│  ├─ page_2.4_train_lines_reference.geojson
│  ├─ page_2.4_train_line_labels.rds
│  └─ page_2.5_filtered_edges.csv
├─ draft
│  ├─ DEP_Draft_Code.Rmd     # Draft code for generating charts in the DEP Report
│  └─ DVP_Draft_Code.Rmd     # Draft code for generating charts in the DVP Website
├─ plot                      # Static figures used in the DEP Report
│  ├─ figure_1_1.png
│  ├─ figure_1_2.png
│  ├─ figure_1_3.png
│  ├─ figure_2_1.png
│  ├─ figure_2_2.png
│  └─ figure_2_3.png
├─ LICENSE                   # MIT License
├─ README.md                 # Project documentation (English)
├─ README.zh.md              # Project documentation (Chinese)
├─ report
│  ├─ DEP_Proposal_Version1.pdf    # Initial DEP Proposal
│  ├─ DEP_Proposal_Version2.pdf    # Final DEP Proposal (Current)
│  ├─ DEP_Report.pdf               # Full Data Exploration Project Report
│  ├─ DVP_Presentation.pdf         # "Five Design Sheet" used for DVP design process
│  └─ DVP_Report.pdf               # Data Visualisation Project Report 
├─ rsconnect                       # Deployment configuration for shinyapps.io
│  └─ shinyapps.io
│     └─ zyyin1
│       └─ ptv_analyzer.dcf
├─ global.R                  # Global configuration and library imports
├─ server.R                  # Shiny Server logic (Back-end)
├─ ui.R                      # Shiny UI layout (Front-end)  
└─ www                       # Static assets (images, pre-generated plots)
   ├─ img1.jpg                
   ├─ img2.jpg
   ├─ img3.jpg
   └─ radar_png              # Pre-generated radar charts for leaflet tooltips
      ├─ Aircraft.png
      ├─ Alamein.png
      ├─ ... (contains images for all stations)
      └─ Yarraville.png
```

## 🛠️ R Environment and Display Recommendations

This R Shiny app was developed and tested under the following environments:

* **Development environment:** RStudio 2025.05.0+496 with R 4.4.3
* **Tested environment:** MoVE platform with RStudio 2024.12.1+563 and R 4.4.2

After installing all required packages, the app runs correctly on both environments. However, note that some visual elements (especially fonts and layout rendering) may appear slightly different on the MoVE platform.

To ensure the best viewing and performance experience, please follow these recommendations:

1.  **Run the app locally** if possible.
2.  Use **RStudio 2025.05.0+496** and **R 4.4.3**.
3.  Before running the app, install all required packages. RStudio will automatically prompt to install CRAN packages.
    Packages `chorddiag` and `ggradar` are **not from CRAN** and must be installed manually (see below).
4.  Once the app is running, view it in **Edge or Chrome** and set your browser zoom level to **100%** for proper layout rendering.
5.  *Hope you enjoy.*

---

## 📦 Special Package Installation Notes

This project uses two R packages that are **not available on CRAN**:

* [`chorddiag`](https://github.com/mattflor/chorddiag): Used for interactive chord diagrams (Page 2.2).
* [`ggradar`](https://github.com/ricardo-bion/ggradar): Used for radar charts built on `ggplot2` (Page 2.3 & 2.4).

These packages must be installed from GitHub before running the app.

### Step-by-step installation

You need the `remotes` package to install packages from GitHub:

```r
install.packages("remotes")
```

Then install the two packages:

```r
# Install chorddiag from GitHub
remotes::install_github("mattflor/chorddiag")

# Install ggradar from GitHub
remotes::install_github("ricardo-bion/ggradar")
```

## 📊 Data Sources

The project utilizes four primary datasets sourced from the **Victorian Government Open Data Portal** and **Data Vic**.

### 1. [Train Service Passenger Counts (FY July 2023–June 2024)](https://opendata.transport.vic.gov.au/dataset/train-service-passenger-counts)
* **Description:** This tabular dataset (CSV format) contains estimated passenger boarding and alighting counts for Melbourne’s rail services. With 15.6 million rows and 21 columns, it includes attributes such as Business Date, Day Type (e.g., weekday, public holiday), Line Name, Direction (toward/away from Flinders Street), and aggregated passenger counts (e.g., boardings, alightings).
* **Usage:** Spatial attributes like station coordinates and temporal granularity (hourly intervals) enable analysis of ridership trends and station-specific patterns. This dataset is used to address **Questions 1 and 2**.

### 2. [Argyle Square Weather Stations Historical Data (May 2021–July 2024)](https://discover.data.vic.gov.au/dataset/argyle-square-weather-stations-historical-data)
* **Description:** This tabular dataset (CSV format) includes 138,538 rows of hourly weather observations. Key variables include precipitation, windspeed, air temperature, and relative humidity.
* **Usage:** These variables are merged with ridership data to assess weather impacts. Combined with Data Source A, this dataset helps answer **Question 1** (regarding external factors).

### 3. [Public Transport Stops (November 2024)](https://opendata.transport.vic.gov.au/dataset/public-transport-lines-and-stops)
* **Description:** This spatial dataset (GeoJSON format) provides geographic coordinates and metadata for 28,323 public transport stops across Victoria, including Melbourne’s rail network. Attributes include Stop ID, Stop Name, and Mode (e.g., Metro Train, Regional Train).
* **Usage:** It supports mapping station locations and integrating spatial context with the passenger dataset for visualisation.

### 4. [Public Transport Lines (November 2024)](https://opendata.transport.vic.gov.au/dataset/public-transport-lines-and-stops)
* **Description:** Another spatial dataset (GeoJSON format) detailing 9,776 public transport routes, including rail lines. Attributes like Line Name, Headsign (destination), and Mode facilitate analysis of service coverage and connectivity.
* **Usage:** It complements the Stops dataset to contextualize passenger flows across the network spatially.

---

## 👤 Author

**Zihan Yin**
* Monash University
* **Project Supervised by:** Shivangi Gheewala & Michael Niemann

_This project is for educational purposes as part of the Monash University FIT5147 unit._