# ------------------------------------------------------------------------------
# Weighted Mean Calculation for Climate Data
#
# This script downloads gridded climate data, extracts values for spatial units,
# calculates population-weighted means, and saves the results as CSV files.
#
# Dependencies: terra, sf, data.table, exactextractr, curl, dplyr
# ------------------------------------------------------------------------------

library(terra)         # For raster and vector spatial data
library(sf)            # For simple features (vector data)
library(data.table)    # For fast data manipulation
library(exactextractr) # For fast raster extraction over polygons
library(curl)          # For robust file downloading
library(dplyr)         # For data manipulation (used elsewhere)

# ------------------------------------------------------------------------------
# Calculate population-weighted mean for extracted climate data
# ------------------------------------------------------------------------------
weighted_population <- function(exposure, shap, days, value_name) {
    # Convert spatial and exposure data to data.table
    shap <- as.data.table(as.data.frame(shap))
    exposure <- as.data.table(exposure)

    # Attach extracted values to shapefile table for NA filtering
    shap[, var := exposure[[1]]]

    # Remove polygons with NA extracted values
    print('Remove NA values')
    shap <- shap[complete.cases(shap$var)]
    exposure <- exposure[complete.cases(exposure[[1]])]

    # Calculate population weights for each polygon
    print('Calculate the weights')
    shap[, pop_inc := POP * frac][, weights := pop_inc / sum(pop_inc), by = distriktskod]

    # Assign formatted date-time column names to exposure
    names(exposure) <- format(days, "%Y-%m-%dT%H:%M:%SZ")

    # Multiply exposure by weights to get weighted values
    print('Calculate population weighted variable')
    exposure <- exposure * shap$weights

    # Add location identifier for grouping
    exposure[, location := shap$distriktskod]

    # Aggregate weighted values by location
    exposure <- exposure[, lapply(.SD, sum), by = location]

    # Reshape to long format: one row per location-date
    print('Pivot longer')
    exposure <- melt(exposure, id.vars = "location", variable.name = "date", value.name = value_name)
    exposure <- exposure[order(location)]

    print('Done')
    return(exposure)
}

# ------------------------------------------------------------------------------
# Generate a list of monthly NetCDF URLs for a given year
# ------------------------------------------------------------------------------
list_of_urls <- function(base_url, prefix, year) {
    months <- 1:12

    # Helper function: get last day of a month
    last_day <- function(year, month) {
        first_next_month <- as.Date(sprintf("%4d-%02d-01", ifelse(month == 12, year + 1, year), ifelse(month == 12, 1, month + 1)))
        as.integer(format(first_next_month - 1, "%d"))
    }

    urls <- c()
    for (m in months) {
        start <- sprintf("%4d%02d01", year, m)
        end <- sprintf("%4d%02d%02d", year, m, last_day(year, m))
        url <- sprintf("%s%s%s-%s.nc", base_url, prefix, start, end)
        urls <- c(urls, url)
    }
    return(urls)
}

# ------------------------------------------------------------------------------
# Download a file from a URL if it does not already exist locally
# ------------------------------------------------------------------------------
download_file <- function(url) {
    destfile <- basename(url)
    if (!file.exists(destfile)) {
        download.file(
            url, destfile,
            mode = "wb",
            method = "curl"
        )
    }
    return(destfile)
}

# ------------------------------------------------------------------------------
# Extract, weight, and format climate data for a given URL and spatial object
# ------------------------------------------------------------------------------
create_dte <- function(url, v, value_name) {
    destfile <- download_file(url)
    nc <- terra::rast(destfile)

    # Get start and end dates from raster time dimension
    sday <- format(min(terra::time(nc)), "%Y-%m-%d")
    eday <- format(max(terra::time(nc)), "%Y-%m-%d")

    # Generate sequence of days for the month
    days <- seq(from = as.POSIXct(sday, tz = 'UTC'),
                to = as.POSIXct(eday, tz = 'UTC') + 1*60*60*23,
                by = '1 day')

    # Assign date names to raster layers and reproject to match vector CRS
    names(nc) <- days
    nc <- terra::project(nc, terra::crs(v))

    # Extract mean raster values for each polygon
    e <- exact_extract(nc, st_as_sf(v), fun = 'mean', max_cells_in_memory = 1e+09)

    # Calculate population-weighted means
    dte <- weighted_population(e, v, days, value_name)

    # Remove temporary file
    file.remove(destfile)

    return(dte)
}

# ------------------------------------------------------------------------------
# Helper to construct the correct prefix for each variable
# ------------------------------------------------------------------------------
url_names <- function(value_name) {
    prefix <- paste0(value_name, "/", value_name, prefix_end)
    return(prefix)
}

# ------------------------------------------------------------------------------
# Main function: process all years for a given area and variable
# ------------------------------------------------------------------------------
run_for_area <- function(area_name, years, value_name) {
    prefix <- url_names(value_name)
    output_dir <- paste0("Regridded/", value_name, "/no_mask/", area_name)

    # Create output directory if it doesn't exist
    if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
    }

    for (year in years) {
        urls <- list_of_urls(base_url, prefix, year)
        urls <- urls[1:3] # FOR TESTING: process only first 3 months

        dtes <- list()
        for (url in urls) {
            print(url)
            # Get the spatial object by name (e.g., 'district' or 'parish')
            v <- get(area_name)
            dte <- create_dte(url, v, value_name)
            dtes[[url]] <- dte
        }

        # Combine all monthly data.tables into one for the year
        dte <- rbindlist(dtes, use.names = TRUE, fill = TRUE)
        dte <- dte[order(location, date)]

        # Save the yearly data as a CSV file
        filename <- paste0(output_dir, "/temp_", area_name, "_", year, ".csv")
        write.csv(dte, file = filename, row.names = FALSE, quote = FALSE)
        print(paste0("Saved file: ", filename))
    }
}

# ------------------------------------------------------------------------------
# Load spatial population data for districts and parishes
# ------------------------------------------------------------------------------
district <- terra::vect("input_files/district_population.rds") # District polygons
parish <- terra::vect("input_files/parish_population.rds")     # Parish polygons

# Rename column for consistency
names(parish)[names(parish) == "sockenstadkod"] <- "distriktskod"

# ------------------------------------------------------------------------------
# Set up parameters for processing
# ------------------------------------------------------------------------------
years <- 2017:2018
base_url <- "https://opendata-download-metanalys.smhi.se/gridclim/"
prefix_end <- "_NORDIC-3_SMHI-UERRA-Harmonie_RegRean_v1_Gridpp_v1.0.1_day_"
value_names <- c("tas", "pr", "hurs", "tasmax", "tasmin")

# ------------------------------------------------------------------------------
# Run processing for each variable and area (district and parish)
# ------------------------------------------------------------------------------
for (value_name in value_names) {
    run_for_area("district", years, value_name)
    run_for_area("parish", years, value_name)
}