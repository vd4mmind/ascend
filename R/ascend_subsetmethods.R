# Functions for subsetting EMSets
#' SubsetCondition
#' 
#' Generic for \code{\link{SubsetCondition}}.
#' 
#' @param object An \code{\linkS4class{EMSet}}
#' @param condition Name of the condition/column you would like to subset the
#' \code{\linkS4class{EMSet}} by
#' @param subconditions List of subconditions that are stored in the condition
#' column, that you would like to select
#' 
#' @importFrom methods setMethod
#' @export
setGeneric(name = "SubsetCondition", def = function(object, condition, subconditions) {
    standardGeneric("SubsetCondition")
})

#' SubsetCondition
#'
#' Subset cells of a specific condition(s) from an \code{\linkS4class{EMSet}}.
#'
#' @param object An \code{\linkS4class{EMSet}}
#' @param condition Name of the condition/column you would like to subset the
#' \code{\linkS4class{EMSet}} by
#' @param subconditions List of subconditions that are stored in the condition
#' column, that you would like to select
#' 
#' @return An \code{\linkS4class{EMSet}} containing cells that only have this 
#' condition.
#' 
#' @examples
#' \dontrun{
#' happy_emset <- SubsetCondition(em.set, condition = "emotion", 
#' subconditions = "happy") 
#' }
#' @include ascend_objects.R
#' @importFrom methods setGeneric setMethod
#' @export
setMethod("SubsetCondition", signature("EMSet"), function(object, condition = NULL, subconditions = c()) {
  # Check if selected condition are present
  if (!(condition %in% colnames(object@CellInformation))) {
    stop("Please check if your condition has been defined in the object's Cell Information.")
  }

  # Check if your selected subconditions are present in your condition column
  if (!all(unlist(lapply(subconditions, function(subcondition) subcondition %in% object@CellInformation[, condition])))){
    stop("Please check if your selected subconditions are in your defined in your selected condition column.")
  }
  
  # Create a new object to output, ensures original object does not get overwritten.
  subset.obj <- object

  # Retrieve data from relevant slots
  expression.matrix <- GetExpressionMatrix(subset.obj, format = "data.frame")
  cell.info <- subset.obj@CellInformation

  # Select out the specified columns
  subset.cell.info <- cell.info[which(cell.info[, condition] %in% subconditions), ]

  # Select out rows that are true in at least one column
  keep.barcodes <- as.vector(subset.cell.info[ ,1])

  # Subset the expression matrix.
  subset.matrix <- expression.matrix[, keep.barcodes]
  subset.obj <- ReplaceExpressionMatrix(subset.obj, subset.matrix)
  subset.obj <- ReplaceCellInfo(subset.obj, subset.cell.info)
  subset.obj <- SyncSlots(subset.obj)

  # Clean up the object
  subset.obj@PCA <- list()
  subset.obj@Clusters <- list()
  subset.obj@Log <- c(subset.obj@Log, list(SubsetByCondition = TRUE, SubsettedConditions = condition))
  return(subset.obj)
})

#' SubsetBatch
#' 
#' Generic for \code{\link{SubsetBatch}}.
#' @param object An \code{\linkS4class{EMSet}}.
#' @param batches Name or number of the batch(es) you would like to subset.
#' @importFrom methods setMethod
#' @export
setGeneric(name = "SubsetBatch", def = function(object, batches) {
    standardGeneric("SubsetBatch")
})

#' SubsetBatch
#'
#' Subset a specific batch from an \code{\linkS4class{EMSet}}.
#'
#' @param object An \code{\linkS4class{EMSet}}.
#' @param batches Name or number of the batch(es) you would like to subset.
#' @return An \code{\linkS4class{EMSet}} containing only this batch.
#'
#' @examples
#' \dontrun{
#' sample1_emset <- SubsetBatch(em.set, batches = c("1", "2", "3"))
#' }
#' @importFrom methods setGeneric setMethod
#' @include ascend_objects.R
#' @export
setMethod("SubsetBatch", signature("EMSet"), function(object, batches = c()) {
    # Check if selected batches are present in the batches column
    if (!any(batches %in% object@CellInformation[, 2])) {
        stop("None of your selected batches are present in the dataset.")
    }

    # Create a new object to output, ensures original object does not get overwritten.
    subset.obj <- object

    # Retrieve data from relevant slots
    expression.matrix <- GetExpressionMatrix(subset.obj, format = "data.frame")
    cell.info <- subset.obj@CellInformation

    # Get barcodes for selected clusters
    subset.cell.info <- cell.info[which(cell.info[, 2] %in% batches), ]

    # Subset the expression matrix.
    subset.matrix <- expression.matrix[, unlist(subset.cell.info[, 1])]
    subset.obj <- ReplaceExpressionMatrix(subset.obj, subset.matrix)
    subset.obj <- SyncSlots(subset.obj)

    # Clean up the object
    subset.obj@PCA <- list()
    subset.obj@Clusters <- list()
    subset.obj@Log <- c(subset.obj@Log, list(SubsetByBatches = TRUE, SubsettedBatches = batches))
    return(subset.obj)
})

#' SubsetCluster
#' 
#' Generic for \code{\link{SubsetCluster}}.
#' @param object A \code{\linkS4class{EMSet}}.
#' @param clusters Clusters to subset from the dataset.
#' @importFrom methods setMethod
#' @export
setGeneric(name = "SubsetCluster", def = function(object, clusters) {
    standardGeneric("SubsetCluster")
})

#' SubsetCluster
#'
#' Subset an\code{\linkS4class{EMSet}} by cluster. Please make sure you have clustered 
#' with \code{\link{RunCORE}} before using this function.
#' 
#' This data is already normalised, but if you wish to recluster the data, you 
#' will need to use the RunPCA function again.
#'
#' @param object A \code{\linkS4class{EMSet}}.
#' @param clusters Clusters to subset from the dataset.
#' @return Returns an \code{\linkS4class{EMSet}} containing only the selected 
#' clusters.
#' @examples
#' \dontrun{
#' cluster1_object <- SubsetCluster(em.set, clusters = c("1", "2", "3"))
#' }
#' @include ascend_objects.R
#' @importFrom methods setGeneric setMethod
#' @export
#'
setMethod("SubsetCluster", signature("EMSet"), function(object, clusters = c()) {
    # Check if data has been clustered
    if (is.null(object@CellInformation[, "cluster"])) {
        stop("Please cluster your data before using this function.")
    }

    # Check if selected clusters are present in the clustered column
    if (!any(clusters %in% object@CellInformation[, "cluster"])) {
        stop("None of your selected clusters are present in the dataset.")
    }

    if (missing(clusters)) {
        stop("Please specify which cluster(s) you would like to extract from this object.")
    }

    # Create a new object to output, ensures original object does not get overwritten.
    subset.obj <- object

    # Retrieve data from relevant slots
    expression.matrix <- GetExpressionMatrix(subset.obj, format = "data.frame")
    cell.info <- subset.obj@CellInformation

    # Get barcodes for selected clusters
    subset.cell.info <- cell.info[which(cell.info$cluster %in% clusters), ]

    # Subset the expression matrix.
    subset.matrix <- expression.matrix[, as.character(subset.cell.info[, 1])]
    subset.obj <- ReplaceExpressionMatrix(subset.obj, subset.matrix)
    subset.obj <- SyncSlots(subset.obj)

    # Clean up the object
    subset.obj@PCA <- list()
    subset.obj@Clusters <- list()
    subset.obj@Log <- c(subset.obj@Log, list(SubsetByCluster = TRUE, SubsettedClusters = clusters))
    return(subset.obj)
})

#' SubsetCells
#' 
#' Generic for \code{\link{SubsetCells}}.
#' @param object An \code{\linkS4class{EMSet}}.
#' @param cell.barcodes A list of cell identifiers to subset from the 
#' @importFrom methods setMethod
#' @export
setGeneric(name = "SubsetCells", def = function(object, cell.barcodes) {
    standardGeneric("SubsetCells")
})

#' SubsetCells
#'
#' Subset cells in the supplied list from an \code{\linkS4class{EMSet}}.
#'
#' @param object An \code{\linkS4class{EMSet}}.
#' @param cell.barcodes A list of cell identifiers to subset from the 
#' \linkS4class{EMSet}.
#' @return An \code{\linkS4class{EMSet}}.
#' @examples
#' \dontrun{
#' barcode_list <- c("Barcode1", "Barcode2", "Barcode3")
#' subset_emset <- SubsetCells(em.set, cell.barcodes = barcode_list)
#' }
#' @include ascend_objects.R
#' @importFrom methods setGeneric setMethod
#' @export
#'
setMethod("SubsetCells", signature("EMSet"), function(object, cell.barcodes = c()) {
    # Check cells are in the expression matrix.
    expression.matrix <- GetExpressionMatrix(object, "data.frame")
    cell.info <- GetCellInfo(object)
    gene.info <- GetGeneInfo(object)
    control.list <- GetControls(object)
    present.cells <- cell.barcodes[cell.barcodes %in% colnames(expression.matrix)]
    
    # Missing cell catch
    if (length(present.cells) == 0) {
        stop("All listed cells were not present in the EMSet.")
    } else {
        # Subset out information
        subset.matrix <- expression.matrix[, present.cells]
        colnames(subset.matrix) <- present.cells
        subset.obj <- ReplaceExpressionMatrix(object, subset.matrix)
        subset.obj <- SyncSlots(subset.obj)

        # Clear Clustering and PCA
        subset.obj@Clusters <- list()
        subset.obj@PCA <- list()

        return(subset.obj)
    }
})
