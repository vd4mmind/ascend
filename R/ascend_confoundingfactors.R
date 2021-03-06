#' RegressGene
#'
#' Called by RemoveConfoundingFactors. This step extracts residuals from the 
#' supplied gene.
#' 
#' @param x Gene to regress residuals from.
#' @param covariate.matrix Covariate matrix generated by RemoveConfoundingFactors.
#' @param expression.matrix A transposed expression matrix generated by 
#' RemoveConfoundingFactors.
#' @importFrom stats as.formula formula lm
#' @export
RegressGene <- function(x, covariate.matrix = NULL, expression.matrix = NULL) {
    regress.mtx <- cbind(covariate.matrix, expression.matrix[, x])

    # Edit string because '-' and other mathematical symbols may interfere with the formula step that is next
    colnames(regress.mtx) <- c(gsub("\\-", "_", colnames(covariate.matrix)), "GENE")
    regress.mtx <- as.data.frame(as.matrix(regress.mtx))

    # Generates a formula for calling the columns for input into the linear regression step
    fmla <- stats::as.formula(paste("GENE ", " ~ ", paste(gsub("\\-", "_", colnames(covariate.matrix)), collapse = "+"), sep = ""))

    # Linear model then extracts residuals from that result
    resid.gene <- stats::lm(fmla, data = regress.mtx)$residuals
    resid.gene <- as.data.frame(resid.gene)
    names(resid.gene) <- x

    # Populates the results into data.resid as a matrix
    return(resid.gene)
}

#' RegressConfoundingFactors
#'
#' This function generates a scaled regression matrix based on candidate genes
#' supplied by the user. This function is best used after normalisation.
#' @param object Expression matrix in data frame format. You may load
#' it from a EMSet object with the GetExpressionMatrix function.
#' @param candidate.genes A list of genes you wish to regress from the dataset.
#' Refer to the vignette on how to choose genes for regression.
#' @return An \code{\linkS4class{EMSet}} with confounding factors regressed from the
#' expression values.
#' @examples
#' \dontrun{
#' regressed_object <- RegressConfoundingFactors(em.set, 
#' candidate.genes = c("Gene1", "Gene2", "Gene3"))
#' }
#' @importFrom Matrix t
#' @importFrom BiocParallel bplapply
#' @importFrom data.table as.data.table
#' @export
#'
RegressConfoundingFactors <- function(object, candidate.genes = list()) {
  # INPUT VERIFICATION STEPS Check user has supplied a list of genes Check that the genes in the candidate list are in the rownames of the data frame
  if (!(length(candidate.genes) > 0)) {
    stop("Please supply a list of gene candidates.")
  }

  if (class(object) != "EMSet" ){
    stop("Please supply an EMSet.")
  }

  # Get expression matrix as a matrix, then transpose
  expression.matrix <- GetExpressionMatrix(object, format = "matrix")
  cell.barcodes <- colnames(expression.matrix)
  gene.ids <- rownames(expression.matrix)

  transposed.matrix <- Matrix::t(expression.matrix)
  expression.matrix <- as.data.frame(transposed.matrix)

  # Different cases - make matches case-agnostic
  gene.vector <- unlist(lapply(candidate.genes, function(x) grep(x, colnames(expression.matrix), ignore.case = TRUE, value = TRUE)))

  ## Check 2 - In case there are no matches
  if (length(gene.vector) == 0) {
    stop("The genes you have supplied in your candidate gene list are not present. Please revise your list.")
  }

  # Create a matrix of covariate (each cell in a row)
  covariate.mtx <- as.data.frame(expression.matrix[, gene.vector])

  # Parallel Process - Looping the regression through every gene
  # Regression can be done for all genes present in the matrix or a subset of genes
  print("Regressing gene...")
  data.resid <- BiocParallel::bplapply(colnames(expression.matrix), RegressGene, covariate.matrix = covariate.mtx, expression.matrix = expression.matrix)

  # Rename the columns in the resulting matrix to their corresponding genes
  print("Regression complete. Filtering out results...")
  data.resid <- as.data.frame(data.resid)

  # Scale the data and filter out columns with NA values
  scaled.resid.data <- scale(data.resid, center = TRUE, scale = TRUE)

  # Filter out columns with NA values
  scaled.resid.data.table <- data.table::as.data.table(scaled.resid.data)
  filtered.table <- scaled.resid.data.table[, which(unlist(lapply(scaled.resid.data.table, function(x) !all(is.na(x))))), with = FALSE]
  filtered.table <- as.data.frame(t(filtered.table))

  # Replace cell barcodes
  colnames(filtered.table) <- cell.barcodes

  # Replace negative values with 0
  filtered.table[filtered.table < 0 ] <- 0

  # Replace expression matrix
  regressed.obj <- ReplaceExpressionMatrix(object, filtered.table)
  regressed.obj <- SyncSlots(regressed.obj)

  return(regressed.obj)
}
