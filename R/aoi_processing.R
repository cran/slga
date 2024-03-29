#' Convert AOI
#'
#' Converts an AOI from a variety of possible input types to an `sf` style bbox.
#'
#' @param aoi Numeric vector of bounding coordinates in xmin, ymin, xmax, ymax
#'   order; or an `sf` or `raster` object from which they can be derived.
#' @return `sf` bbox object with same crs as input.
#' @keywords internal
#' @rdname aoi_convert
#' @importFrom raster extent
#' @importFrom sf st_as_sf st_as_sfc st_bbox st_crs st_transform
#' @importFrom utils data
#'
aoi_convert <- function(aoi = NULL) {
  UseMethod('aoi_convert')
}

#' @rdname aoi_convert
#' @inherit aoi_convert return
#' @method aoi_convert numeric
#'
aoi_convert.numeric <- function(aoi = NULL) {
  # check for common coord order fails (NB last is Aus-specific)
  if(any(aoi[3] <= aoi[1], aoi[2] >= aoi[4], aoi[2] >= aoi[1])) {
    stop('Please check that AOI coordinates are ordered correctly - xmin, ymin, xmax, ymax.')
  }
  message("Assuming AOI coordinates are in EPSG:4283 and ordered correctly.")
  structure(aoi, names = c("xmin", "ymin", "xmax", "ymax"),
            class = "bbox", crs = sf::st_crs(4283))
  }

#' @rdname aoi_convert
#' @inherit aoi_convert return
#' @method aoi_convert Raster
#'
aoi_convert.Raster <- function(aoi = NULL) {
  ## PROJ version thing augh ffs
  #if(grepl('EPSG', aoi@crs@projargs)) {
  #  aoi@crs@projargs <- gsub('EPSG', 'epsg', aoi@crs@projargs)
  #  }
  aoi_crs <- sf::st_crs(raster::crs(aoi))
  aoi <- raster::extent(aoi)
  sf::st_bbox(aoi, crs = aoi_crs)
}

#' @rdname aoi_convert
#' @inherit aoi_convert return
#' @method aoi_convert Extent
#'
aoi_convert.Extent <- function(aoi = NULL) {
  message("Assuming AOI coordinates are in EPSG:4283.")
  sf::st_bbox(aoi, crs = sf::st_crs(4283))
}

#' @rdname aoi_convert
#' @inherit aoi_convert return
#' @method aoi_convert sf
#'
aoi_convert.sf <- function(aoi = NULL) {
  sf::st_bbox(aoi)
}

#' @rdname aoi_convert
#' @inherit aoi_convert return
#' @method aoi_convert sfc
#'
aoi_convert.sfc <- function(aoi = NULL) {
  sf::st_bbox(aoi)
}

#' @rdname aoi_convert
#' @inherit aoi_convert return
#' @method aoi_convert sfg
#'
aoi_convert.sfg <- function(aoi = NULL) {
  message("Assuming AOI coordinates are in EPSG:4283.")
  new <- sf::st_as_sfc(sf::st_bbox(aoi))
  new <- sf::st_set_crs(new, 4283)
  sf::st_bbox(new)
}

#' @rdname aoi_convert
#' @inherit aoi_convert return
#' @method aoi_convert s2_geography
#'
aoi_convert.s2_geography <- function(aoi = NULL) {
  # s2 classes all come back into sf as 4326 so
  sf::st_bbox(sf::st_transform(sf::st_as_sf(aoi), 4283))
}

#' Transform an AOI's CRS
#'
#' Transforms an `sf` style bounding box object into the specified coordinate
#' reference system.
#'
#' @param aoi Object of class 'bbox' generated by internal function
#'   \code{\link[slga:aoi_convert]{aoi_convert()}}.
#' @param crs EPSG code of desired coordinate reference system. Default 4283.
#' @return 'bbox' object with the desired CRS, large enough to ensure returned
#' dataset covers entire input object.
#' @note This is a stopgap until and unless a dedicated sf method for bbox
#' transformations is written. Currently used to coerce to WGS84 under specific
#' circumstances. Since this helper was written for an Australia-specific package,
#' it is assumed that it will be used to transform coordinates from a fairly
#' limited list of known crs's, chiefly GDA94 (EPSG:4283) and its associated
#' UTM and Albers equal area projections.
#' @keywords internal
#' @importFrom sf st_bbox st_crs st_point st_sfc st_transform
#'
aoi_transform <- function(aoi = NULL, crs = 4283) {
  box <- sf::st_as_sfc(aoi, crs = sf::st_crs(aoi))
  new <- sf::st_transform(box, crs)
  sf::st_bbox(new)
}

#' Check AOI overlaps
#'
#' Confirms whether an AOI covers the requested product (wholly or partly).
#' @param aoi Converted and transformed area of interest
#' @param product Character, one of the options from column 'Short_Name' in
#'   \code{\link[slga:slga_product_info]{slga_product_info}}.
#' @return Logical, TRUE if overlap exists.
#' @note Will return TRUE if bbox is over product but not over land.
#' @importFrom sf sf_use_s2 st_as_sfc st_bbox st_crs st_intersects
#' @importFrom s2 s2_intersects_box
#' @importFrom utils data
#'
aoi_overlaps <- function(aoi = NULL, product = NULL) {
  slga_product_info <- NULL
  utils::data('slga_product_info', envir = environment())
  prd <- slga_product_info[which(slga_product_info$Short_Name == product), ]
  prd <- c(prd[['xmin']], prd[['ymin']], prd[['xmax']], prd[['ymax']])
  # s2 plays up if boxes are projected for this check
  prd_aoi <- structure(prd, names = c("xmin", "ymin", "xmax", "ymax"),
                       class = "bbox", crs =  sf::st_crs(NA))
  aoi <- sf::st_as_sfc(aoi)
  sf::st_crs(aoi) <- NA
  aoi <- sf::st_bbox(aoi)

  int <- sf::st_intersects(sf::st_as_sfc(aoi), sf::st_as_sfc(prd_aoi))
  if(length(int[[1]]) == 0L) { FALSE } else { TRUE }
  }

#' Align AOI to product
#'
#' Cheerfully stolen from \code{\link[raster:alignExtent]{raster::alignExtent}}
#' and adapted to sf bbox objects. This is designed to prevent WCS server-side
#' interpolation when requesting SLGA data.
#'
#' @param aoi `sf` bbox object
#' @param product Character, one of the options from column 'Short_Name' in
#'   \code{\link[slga:slga_product_info]{slga_product_info}}.
#' @param snap Character; 'near', 'in', or 'out'. Defaults to 'out'.
#' @keywords internal
#' @importFrom utils data
#'
aoi_align <- function(aoi = NULL, product = NULL, snap = "out") {
  snap <- match.arg(snap, c("near", "in", "out"))
  slga_product_info <- NULL
  utils::data('slga_product_info', envir = environment())

  res <- abs(
    c(slga_product_info$offset_x[which(slga_product_info$Short_Name == product)],
      slga_product_info$offset_y[which(slga_product_info$Short_Name == product)]))

  orig <-
    c(slga_product_info$origin_x[which(slga_product_info$Short_Name == product)],
      slga_product_info$origin_y[which(slga_product_info$Short_Name == product)])

  if (snap == "near") {
    xmn <- round((aoi['xmin'] - orig[1])/res[1]) * res[1] + orig[1]
    xmx <- round((aoi['xmax'] - orig[1])/res[1]) * res[1] + orig[1]
    ymn <- round((aoi['ymin'] - orig[2])/res[2]) * res[2] + orig[2]
    ymx <- round((aoi['ymax'] - orig[2])/res[2]) * res[2] + orig[2]
  }
  if (snap == "out") {
    xmn <- floor((aoi['xmin']   - orig[1])/res[1]) * res[1] + orig[1]
    xmx <- ceiling((aoi['xmax'] - orig[1])/res[1]) * res[1] + orig[1]
    ymn <- floor((aoi['ymin']   - orig[2])/res[2]) * res[2] + orig[2]
    ymx <- ceiling((aoi['ymax'] - orig[2])/res[2]) * res[2] + orig[2]
  }
  if (snap == "in") {
    xmn <- ceiling((aoi['xmin'] - orig[1])/res[1]) * res[1] + orig[1]
    xmx <- floor((aoi['xmax']   - orig[1])/res[1]) * res[1] + orig[1]
    ymn <- ceiling((aoi['ymin'] - orig[2])/res[2]) * res[2] + orig[2]
    ymx <- floor((aoi['ymax']   - orig[2])/res[2]) * res[2] + orig[2]
  }

  if (xmn == xmx) {
    if (xmn <= aoi['xmin']) {
      xmx <- xmx + res[1]
    }
    else {
      xmn <- xmn - res[1]
    }
  }
  if (ymn == ymx) {
    if (ymn <= aoi['ymin']) {
      ymx <- ymx + res[2]
    }
    else {
      ymn <- ymn - res[2]
    }
  }

  # edge case - at this stage, if aoi is from a point and snap = 'in',
  # max/mins can get flipped so
  if(xmn < xmx) {
    aoi[1] <- xmn
    aoi[3] <- xmx
  } else {
    aoi[1] <- xmx
    aoi[3] <- xmn
  }

  if(ymn < ymx) {
    aoi[2] <- ymn
    aoi[4] <- ymx
  } else {
    aoi[2] <- ymx
    aoi[4] <- ymn
  }
  aoi
}

#' Tile AOI
#'
#' If an AOI is Large, chop it up so that a series of GETs can be sent.
#'
#' @param aoi sf bbox already converted from user input and aligned to requested
#' product.
#' @param size Number, max side length of tiles in decimal degrees. Default 1.
#' @return a list of bounding boxes subdividing the area of interest. Return
#' list is aligned to product and tiles that don't overlap are discarded.
#'
#' @keywords internal
#' @importFrom sf st_crs
#'
aoi_tile <- function(aoi = NULL, product = NULL, size = 1) {

  # NB can do this with sf funs in fewer lines but its slower
  xrng <- sort(unique(c(aoi[1], seq(aoi[1], aoi[3], by = size), aoi[3])))
  yrng <- sort(unique(c(aoi[2], seq(aoi[2], aoi[4], by = size), aoi[4])))

  # list of bboxes (unvalidated!!!)
  tiles <- mapply(function(llxi, llyi, urxi, uryi) {
    structure(c(xrng[llxi], yrng[llyi], xrng[urxi], yrng[uryi]),
              names = c("xmin", "ymin", "xmax", "ymax"),
              class = "bbox", crs = sf::st_crs(4283))
  },
  llxi = rep(seq(length(xrng) - 1), times = length(yrng) - 1),
  llyi = rep(seq(length(yrng) - 1), each = length(xrng) - 1),
  urxi = rep(2:length(xrng), times = length(yrng) - 1),
  uryi = rep(2:length(yrng), each = length(xrng) - 1),
  SIMPLIFY = FALSE)

  # tidy tiles - align and discard non-overlapping
  # NB earlier checks preclude the possibility of no tiles overlapping
  # NB NB all tiles will overlap by one cell, on purpose
  tiles <- lapply(tiles, function(x) {    aoi_align(x, product) })
  keep  <- sapply(tiles, function(x) { aoi_overlaps(x, product) })
  tiles <- tiles[keep]

  if(length(tiles) == 1) { tiles[[1]] } else { tiles }
}

#' Validate AOI
#'
#' Checks that an area of interest is of appropriate projection, size, and
#' extent, aligns AOI to requested product, tiles if large.
#'
#' @param aoi Numeric; bounding coordinates or an `sf` or `raster` object from
#'   which they can be derived.
#' @param product Character, one of the options from column 'Short_Name' in
#'   \code{\link[slga:slga_product_info]{slga_product_info}}.
#' @return sf style bbox or list of same, aligned to requested product.
#' @keywords internal
#'
validate_aoi <- function(aoi = NULL, product = NULL) {

  if(is.null(product)) {
    stop('Please specify a target product.')
  }

  ext <- if(!inherits(aoi, 'bbox')) {
    aoi_convert(aoi)
  } else {
    aoi
  }

  # check crs, transform if not in 4283
  if(sf::st_crs(ext)$input != 'EPSG:4283') {
    message('Transforming aoi coordinates to EPSG:4283')
    ext <- aoi_transform(ext, 4283)
  }

  if(aoi_overlaps(ext, product) == FALSE) {
    stop('AOI does not overlap requested product extent.')
  }

  # Align extent to source to avoid server-side interpolation and grid shift
  ext <- aoi_align(aoi = ext, product = product)

  # check extent isn't too big. If it is, tile
  x_range <- abs(ext[1] - ext[3])
  y_range <- abs(ext[2] - ext[4])
  # 0.001 below prevents unnecessary tiling due to aoi snap
  if(any(x_range > 1.001, y_range > 1.001)) {
    # returns a list of max 1x1' bboxes
    aoi_tile(ext, product)
  } else {
    # returns a bbox
    ext
  }
}

#' bbox from center point
#'
#' Get a bounding box from an x,y point and desired buffer distance
#'
#' @param product Character, one of the options from column 'Short_Name' in
#'  \code{\link[slga:slga_product_info]{slga_product_info}}.
#' @param poi Numeric; length-2 vector of x, y coordinates or `sf` style point.
#' @param buff Integer, cell buffer around point. Defaults to 0 (single cell).
#' @return sf style bbox or list of same, aligned to requested product, centered
#'   on `point` and extending `buff` cells away from centre.
#' @keywords internal
#' @note This is for buffered data requests around a point.
#' @importFrom sf st_crs st_coordinates
#' @importFrom utils data
#' @examples {
#' library(slga)
#' poi <- c(152, -27)
#'
#' # size 0 = extent of single cell
#' slga:::validate_poi(poi = poi, product = 'SLPPC', buff = 0)
#'
#' # size 3 = 7x7 cells (centre cell and 3 in each direction)
#' slga:::validate_poi(poi = poi, product = 'SLPPC', buff = 3)
#' }
#'
validate_poi <- function(poi = NULL, product = NULL, buff = 0) {

  slga_product_info <- NULL
  utils::data('slga_product_info', envir = environment())

  # too lazy for full methods just now
  if(inherits(poi, c('XY', 'XYZ', 'XYM', 'XYZM', 'sfc_POINT', 'sf'))) {
    poi <- as.vector(sf::st_coordinates(poi))
  }

  res <- abs(
    c(slga_product_info$offset_x[which(slga_product_info$Short_Name == product)],
      slga_product_info$offset_y[which(slga_product_info$Short_Name == product)]))
  orig <-
    c(slga_product_info$origin_x[which(slga_product_info$Short_Name == product)],
      slga_product_info$origin_y[which(slga_product_info$Short_Name == product)])

  # nb to snap point to nearest cell center,
  #p_x <- floor((poi[1] - orig[1])/res[1]) * res[1] + orig[1] + (res[1] / 2)
  #p_y <- floor((poi[2] - orig[2])/res[2]) * res[2] + orig[2] + (res[2] / 2)

  # 1-cell bbox from snap = 'out'
  xmn <- floor((poi[1]   - orig[1])/res[1]) * res[1] + orig[1]
  ymn <- floor((poi[2]   - orig[2])/res[2]) * res[2] + orig[2]
  xmx <- ceiling((poi[1] - orig[1])/res[1]) * res[1] + orig[1]
  ymx <- ceiling((poi[2] - orig[2])/res[2]) * res[2] + orig[2]

  # for size > 1, buffer res * size
  if(buff > 0) {
    xmn <- xmn - (res[1] * buff)
    ymn <- ymn - (res[2] * buff)
    xmx <- xmx + (res[1] * buff)
    ymx <- ymx + (res[2] * buff)
  }

  ext <- structure(c(xmn, ymn, xmx, ymx),
                   names = c("xmin", "ymin", "xmax", "ymax"),
                   class = "bbox", crs = sf::st_crs(4283))

  if(aoi_overlaps(ext, product) == FALSE) {
    stop('POI does not intersect requested product extent.')
  }

  ext
}
