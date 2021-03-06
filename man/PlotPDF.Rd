% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ascend_utilities.R
\name{PlotPDF}
\alias{PlotPDF}
\title{PlotPDF}
\usage{
PlotPDF(plot.list, filename = NULL, width = 11, height = 8.5, ...)
}
\arguments{
\item{plot.list}{A list of plots generated by \pkg{ascend}.}

\item{filename}{Name of the file you would like to output to.}

\item{width}{Width of the PDF.}

\item{height}{Height of the PDF.}

\item{...}{Additional arguments to pass on to \code{\link{pdf}} function}
}
\description{
Takes a list of plots generated by \pkg{ascend} and prints them to PDF. As 
this is a wrapper for the \link[grDevices]{pdf} function, you can pass additional
arguments to this function.
}
\examples{
\dontrun{
qc.plots <- PlotGeneralQC(em.set)
PlotPDF(qc.plots, filename = "MyQCplots.pdf", 
width = 11, height = 8.5, bg = "white")
}
}
