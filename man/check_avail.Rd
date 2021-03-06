% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helpers.R
\name{check_avail}
\alias{check_avail}
\title{Validate soils product/attribute combination}
\usage{
check_avail(product = NULL, attribute = NULL)
}
\arguments{
\item{product}{Character, one of the options from column 'Code' in
\code{\link[slga:slga_product_info]{slga_product_info}} where Type = 'Soil'.}

\item{attribute}{Character, one of the options from column 'Code' in
\code{\link[slga:slga_attribute_info]{slga_attribute_info}}.}
}
\value{
Logical; TRUE if available
}
\description{
Check whether the requested soils attribute is available for the requested
soils product.
}
\examples{
check_avail('NAT', 'CFG')
check_avail('SA',  'CFG')
}
