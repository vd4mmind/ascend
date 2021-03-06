% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ascend_normalisation.R
\name{NormaliseLibSize}
\alias{NormaliseLibSize}
\title{NormaliseLibSize}
\usage{
NormaliseLibSize(object)
}
\arguments{
\item{object}{An \code{\linkS4class{EMSet}} object. Please remove spike-ins 
from the expression matrix before normalising.}
}
\value{
An \code{\linkS4class{EMSet}} normalised by library size.
}
\description{
Normalise library sizes by scaling.
}
