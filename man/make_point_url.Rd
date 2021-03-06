% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/url_generate.R
\name{make_point_url}
\alias{make_point_url}
\title{Make point URL}
\usage{
make_point_url(product = NULL, poi = NULL)
}
\arguments{
\item{product}{Character, one of the options from column 'Short_Name' in
\code{\link[slga:slga_product_info]{slga_product_info}}, where Type =
'Landscape'.}

\item{poi}{Vector of WGS84 coordinates defining a point area of
interest. The vector may be specified directly in the order x, y,
or the function can take in `sf` point objects.}
}
\value{
URL string containing supplied parameters. NB not using this one yet.
}
\description{
Generate the URL for a point data query on the Soil and Landscape Grid of
Australia.
}
\keyword{internal}
