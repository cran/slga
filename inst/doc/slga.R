## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE, warning = FALSE, message = FALSE,
  comment = "#>",
  fig.align = 'center', fig.width = 8, fig.height = 5, fig.caption = FALSE
)

## ----pkgs---------------------------------------------------------------------
library(raster)
library(slga)
options(stringsAsFactors = FALSE)

## ----bnec---------------------------------------------------------------------
data('bne_surface_clay')
bne_surface_clay

## ----'qry', eval = FALSE------------------------------------------------------
#  aoi <- c(152.95, -27.55, 153.07, -27.45)
#  bne_surface_clay <- get_soils_data(product = 'NAT', attribute = 'CLY',
#                                     component = 'ALL', depth = 1,
#                                     aoi = aoi, write_out = FALSE)

## ----'qry2', eval = FALSE-----------------------------------------------------
#  bne_mrvbf <- get_lscape_data(product = 'MRVBF', aoi = aoi, write_out = FALSE)

## ----direx, eval = FALSE------------------------------------------------------
#  filedir = 'C:/data'
#  filedir = getwd()
#  filedir = file.path('C:', 'data')

## ----'allclay', eval = FALSE--------------------------------------------------
#  # not run
#  bne_all_clay <- lapply(seq.int(6), function(d) {
#    get_soils_data(product = 'NAT', attribute = 'CLY', component = 'VAL',
#                   depth = d, aoi = aoi, write_out = FALSE)
#  })
#  bne_all_clay <- raster::brick(bne_all_clay)
#  

## ----'pt0', eval = FALSE------------------------------------------------------
#  #not run
#  clay_pt  <- get_soils_point('NAT', 'CLY', 'VAL', 5, c(153, -27.5))
#  slope_pt <- get_lscape_point('SLPPC', c(153, -27.5))

## ----'ptb', eval = FALSE------------------------------------------------------
#  # get the average predicted clay content for 60-100cm within ~300m of a point
#  avg_clay <- get_soils_point('NAT', 'CLY', 'VAL', 5, c(153, -27.5),
#                              buff = 3, buff_shp = 'circle', stat = 'mean')
#  

## ----mdeg, eval = FALSE-------------------------------------------------------
#  nat_clay_mdc <- metadata_soils('NAT', 'CLY', req_type = 'desc')

