## R Environment and Display Recommendations

This R Shiny app was developed and tested under the following environments:

-   **Development environment:** RStudio 2025.05.0+496 with R 4.4.3
-   **Tested environment:** MoVE platform with RStudio 2024.12.1+563 and R 4.4.2

After installing all required packages, the app runs correctly on both environments. However, note that some visual elements (especially fonts and layout rendering) may appear slightly different on the MoVE platform.

To ensure the best viewing and performance experience, please follow these recommendations:

1.  **Run the app locally** if possible.
2.  Use **RStudio 2025.05.0+496** and **R 4.4.3**.
3.  Before running the app, install all required packages. RStudio will automatically prompt to install CRAN packages.\
    Packages `chorddiag` and `ggradar` are **not from CRAN** and must be installed manually (see below).
4.  Once the app is running, view it in **Edge or Chrome** and set your browser zoom level to **100%** for proper layout rendering.
5.  *Hope you enjoy.*

------------------------------------------------------------------------

## Special Package Installation Notes: `chorddiag` and `ggradar`

This project uses two R packages that are **not available on CRAN**:

-   [`chorddiag`](https://github.com/mattflor/chorddiag): Used for interactive chord diagrams.
-   [`ggradar`](https://github.com/ricardo-bion/ggradar): Used for radar charts built on `ggplot2`.

These packages must be installed from GitHub before running the app.

#### step-by-step installation

You need the `remotes` package to install packages from GitHub:

``` r
install.packages("remotes")
```

Then install the two packages:

``` r
# Install chorddiag from GitHub
remotes::install_github("mattflor/chorddiag")

# Install ggradar from GitHub
remotes::install_github("ricardo-bion/ggradar")
```
