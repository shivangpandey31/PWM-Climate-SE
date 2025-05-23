# ------------------------------------------------------------------------------
# Intersection and Area Calculation for Population and Administrative Polygons
#
# This script intersects population grid polygons with administrative boundaries
# (districts and parishes), calculates the area and area fraction for each
# intersected polygon, and saves the results as RDS files for later use.
#
# Dependencies: terra
# ------------------------------------------------------------------------------

library(terra)  # For spatial vector operations

# ------------------------------------------------------------------------------
# Function to intersect two polygon layers, calculate area and fraction, and save
# ------------------------------------------------------------------------------
intersection_polygons <- function(prov, popu, filename) {
    # Intersect population polygons with administrative polygons
    v <- terra::intersect(popu, prov)
    # Calculate area in square meters for each intersected polygon
    v$area <- terra::expanse(v)
    # Calculate area fraction (area in square kilometers)
    v$frac <- v$area / 1e+06
    # Save the resulting spatial object as an RDS file
    saveRDS(v, filename)
    return(v)
}

# ------------------------------------------------------------------------------
# Load population grid and administrative district polygons
# ------------------------------------------------------------------------------
popu <- terra::vect('vectors/totalbefolkning_1km_231231.gpkg')  # Population grid
prov <- terra::vect('vectors/distrikt.gpkg')                    # District polygons

# Intersect and save district-level population polygons
v <- intersection_polygons(prov, popu, "input_files/district_population.rds")

# ------------------------------------------------------------------------------
# Load parish polygons and repeat intersection
# ------------------------------------------------------------------------------
prov <- terra::vect('vectors/sockenstad.gpkg')                  # Parish polygons

# Intersect and save parish-level population polygons
v <- intersection_polygons(prov, popu, "input_files/parish_population.rds")