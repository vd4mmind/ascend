% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ascend_normalisation.R
\name{scranNormalise}
\alias{scranNormalise}
\title{scranNormalise}
\usage{
scranNormalise(object, quickCluster = FALSE, min.mean = 1e-05)
}
\arguments{
\item{object}{An \code{\linkS4class{EMSet}} that has not undergone 
normalisation.}

\item{quickCluster}{Use scran's quickCluster method (TRUE) or  use randomly-
assigned groups (FALSE, Default).}

\item{min.mean}{Threshold for average counts. This argument is for the 
\code{\link[scran]{computeSumFactors}} function from \pkg{scran}. The value 
of 1 is recommended for read count data, while the default value of 1e-5 is 
best for UMI data. This argument is only used for newer versions of 
\pkg{scran}.}
}
\value{
An \code{\linkS4class{EMSet}} with an expression matrix with counts 
normalised by \code{\link[scater]{normalize}} function.
}
\description{
Normalise an \code{\linkS4class{EMSet}} with \pkg{scran}'s deconvolution 
method by Lun et al. 2016.
}
\details{
Pooling method of cells is influenced by the size of the cell 
population.For datasets containing less than 20000 cells, this function will 
run\code{\link[scran]{computeSumFactors}} with preset sizes of 40, 60, 80 and 
100.

For datasets containing over 20000 cells, you have the option to use 
\code{\link[scran]{quickCluster}} to form pools of cells to feed into 
\code{\link[scran]{computeSumFactors}}. This method is slower and may fail
with very large datasets containing over 40000 cells. If 
\code{\link[scran]{quickCluster}} is not selected, cells will be randomly 
assigned to a group.
}
\examples{
\dontrun{
normalised_object <- scranNormalise(em.set, quickCluster = TRUE, 
min.mean = 1e-5)
}
}
