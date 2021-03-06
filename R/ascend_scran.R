#' SCESetnormalise
#' 
#' Called by \code{\link{scranNormalise}} - runs normalisation on a 
#' \pkg{SingleCellExperiment} object and converts it back to an 
#' \linkS4class{EMSet}.
#' 
#' @param sce.set A \pkg{SingleCellExperiment} object.
#' @param em.set The \code{\linkS4class{EMSet}} to load the SCESet into.
#' @param quickCluster Whether or not to use quickCluster (Default: FALSE).
#' @return A normalised \code{\linkS4class{EMSet}} object.
#' @importFrom scran quickCluster computeSumFactors
#' @importFrom scater normalize
#' 
SCESetnormalise <- function(sce.set, em.set, quickCluster = FALSE){
  # Remove controls from SCESet object
  present.mt <- which(rownames(sce.set) %in% em.set@Controls$Mt)
  present.rb <- which(rownames(sce.set) %in% em.set@Controls$Rb)
  
  remove.idx <- c(present.mt, present.rb)
  
  # Remove ERCC sequences if in dataset
  ercc.idx <- grep("^ercc-", ignore.case = TRUE, rownames(em.set@ExpressionMatrix))
  if (length(ercc.idx) > 0) {
    remove.idx <- c(remove.idx, ercc.idx)
  }
  
  # Remove these items
  sce.set_rmMtRb <- sce.set[-remove.idx, ]
  
  # Run computeSumFactors based on number of samples If we have more than 10,000 samples, we will run quickCluster Otherwise we supply a set list of sizes
  if (ncol(sce.set_rmMtRb) > 10000) {
    if (quickCluster) {
      print(sprintf("%i cells detected. Running quickCluster to feed into computeSumFactors...", ncol(sce.set)))
      quick.cluster <- scran::quickCluster(sce.set_rmMtRb, method = "hclust")
    } else {
      print(sprintf("%i cells detected. Randomly grouping cells to feed into computeSumFactors...", ncol(sce.set)))
      cell.identifiers <- colnames(sce.set_rmMtRb)
      
      # Assign pseudocluster
      chunked.idx <- split(sample(1:length(cell.identifiers)), 1:10)
      quick.cluster <- cell.identifiers
      
      for (cluster.id in names(chunked.idx)) {
        cell.idx <- chunked.idx[[cluster.id]]
        quick.cluster[cell.idx] <- cluster.id
      }
    }
    
    # Feed rough clusters into computeSumFactors
    factored.sce.set <- scran::computeSumFactors(sce.set_rmMtRb, clusters = quick.cluster, positive = TRUE)
  } else {
    print(sprintf("%i cells detected. Running computeSumFactors with preset sizes of 40, 60, 80, 100...", ncol(sce.set)))
    preset.sizes <- c(40, 60, 80, 100)
    factored.sce.set <- scran::computeSumFactors(sce.set_rmMtRb, sizes = preset.sizes, positive = TRUE)
  }
  
  print("scran's computeSumFactors complete. Removing zero sum factors from dataset...")
  zero.size.factors <- which(factored.sce.set@phenoData@data$size_factor == 0)
  if (any(zero.size.factors)) {
    min.size.factor <- min(factored.sce.set@phenoData@data$size_factor[-zero.size.factors])
    factored.sce.set@phenoData@data$size_factor[zero.size.factors] <- min.size.factor
  }
  
  print("Running scater's normalize method...")
  dcvl.sce.set <- scater::normalize(factored.sce.set)
  
  # Convert log-transformed results back into counts
  print("Normalisation complete. Converting SCESet back to EMSet...")
  dcvl.matrix <- as.matrix(scater::norm_exprs(dcvl.sce.set))
  unlog.dcvl.matrix <- UnLog2Matrix(dcvl.matrix)
  
  # Replace the em.set
  normalised.obj <- ReplaceExpressionMatrix(em.set, unlog.dcvl.matrix)
  normalised.obj <- SyncSlots(normalised.obj)
  normalised.obj@Log$NormalisationMethod <- "scranNormalise"
  normalised.obj@Log$Controls <- FALSE
  normalised.obj@Log$ExcludeControls <- list(Mt = TRUE, Rb = TRUE)
  
  remove(sce.set)
  return(normalised.obj)
}


#' SCEnormalise
#' 
#' Called by \code{\link{scranNormalise}} - runs normalisation on a 
#' \pkg{SingleCellExperiment} object and converts it back to an 
#' \linkS4class{EMSet}.
#' 
#' @param sce.obj A \pkg{SingleCellExperiment} object.
#' @param em.set An \code{\linkS4class{EMSet}} that the sce.set originated from.
#' @param quickCluster Normalise with quickCluster Default: FALSE.
#' @param min.mean Argument to pass on to
#' \code{\link[scran]{computeSumFactors}} from \pkg{scran} Default: 1e-5.
#' @return A normalised \code{\linkS4class{EMSet}}.
#' 
#' @importFrom scran quickCluster computeSumFactors
#' @importFrom scater normalize
#' 
SCEnormalise <- function(sce.obj, em.set, quickCluster = FALSE, min.mean = 1e-5){
  # Remove controls from SCE object
  present.mt <- which(rownames(sce.obj) %in% em.set@Controls$Mt)
  present.rb <- which(rownames(sce.obj) %in% em.set@Controls$Rb)
  
  remove.idx <- c(present.mt, present.rb)
  ercc.idx <- grep("^ercc-", ignore.case = TRUE, rownames(em.set@ExpressionMatrix))
  if (length(ercc.idx) > 0) {
    remove.idx <- c(remove.idx, ercc.idx)
  } 
  
  sce.obj_rmMtRb <- sce.obj[-remove.idx, ]
  
  if (ncol(sce.obj_rmMtRb) > 10000) {
    if (quickCluster) {
      print(sprintf("%i cells detected. Running quickCluster to feed into computeSumFactors...", ncol(sce.obj)))
      quick.cluster <- scran::quickCluster(sce.obj_rmMtRb, method = "hclust")
    } else {
      print(sprintf("%i cells detected. Randomly grouping cells to feed into computeSumFactors...", ncol(sce.obj)))
      cell.identifiers <- colnames(sce.obj_rmMtRb)
      
      # Assign pseudocluster
      chunked.idx <- split(sample(1:length(cell.identifiers)), 1:10)
      quick.cluster <- cell.identifiers
      
      for (cluster.id in names(chunked.idx)) {
        cell.idx <- chunked.idx[[cluster.id]]
        quick.cluster[cell.idx] <- cluster.id
      }
    }
    
    # Feed rough clusters into computeSumFactors
    factored.sce.obj <- scran::computeSumFactors(sce.obj_rmMtRb, clusters = quick.cluster, min.mean = min.mean, positive = TRUE)
  } else {
    print(sprintf("%i cells detected. Running computeSumFactors with preset sizes of 40, 60, 80, 100...", ncol(sce.obj)))
    preset.sizes <- c(40, 60, 80, 100)
    factored.sce.obj <- scran::computeSumFactors(sce.obj_rmMtRb, sizes = preset.sizes, positive = TRUE, min.mean = min.mean)
  }
  
  print("scran's computeSumFactors complete. Removing zero sum factors from dataset...")
  
  # Get Size Factors
  size.factors <- BiocGenerics::sizeFactors(factored.sce.obj)
  zero.size.factors <- which(size.factors == 0)
  
  # Adjust zero size factors to smallest size factor and replace current size factor
  if (length(zero.size.factors) > 0) {
    min.size.factor <- min(size.factors[-zero.size.factors])
    
    # Replace zero size factors
    size.factors[zero.size.factors] <- min.size.factor
    BiocGenerics::sizeFactors(factored.sce.obj) <- size.factors
  }
  
  print("Running scater's normalize method...")
  dcvl.sce.obj <- scater::normalize(factored.sce.obj)
  
  # Convert log-transformed results back into counts
  print("Normalisation complete. Converting SingleCellExperiment back to EMSet...")
  dcvl.matrix <- as.matrix(SingleCellExperiment::logcounts(dcvl.sce.obj))
  unlog.dcvl.matrix <- UnLog2Matrix(dcvl.matrix)
  
  # Replace the em.set
  normalised.obj <- ReplaceExpressionMatrix(em.set, unlog.dcvl.matrix)
  normalised.obj <- SyncSlots(normalised.obj)
  normalised.obj@Log$NormalisationMethod <- "scranNormalise"
  normalised.obj@Log$Controls <- FALSE
  normalised.obj@Log$ExcludeControls <- list(Mt = TRUE, Rb = TRUE)
  
  remove(sce.obj)
  return(normalised.obj)
}

#' scranCellCycle
#'
#' Wrapper for \pkg{scran}'s cell cycle functions. Please ensure you are using
#' *ensembl_id* as your rownames in this dataset. Also ensure you are using
#' mitochondrial and ribosomal genes as controls.
#'
#' @param object An \code{\linkS4class{EMSet}} object.
#' @param training.set A training dataset containing pairs of marker genes.
#' @importFrom scran cyclone
#' @importFrom BiocParallel bpparam
#' @export
#'
scranCellCycle <- function(object, training.set) {
  # Cell Cycle Testing
  expression.matrix <- GetExpressionMatrix(object, format = "matrix")

  # Run cyclone with cell cycle assignments as a vector
  cc.assignments <- scran::cyclone(expression.matrix, pairs = training.set, rownames(expression.matrix), BPPARAM = BiocParallel::bpparam())

  cell.info <- GetCellInfo(object)
  cell.info$phase <- cc.assignments$phases

  object <- ReplaceCellInfo(object, cell.info)
  return(object)
}

#' ConvertToSCESet
#'
#' Convert a \code{\linkS4class{EMSet}} object into a \pkg{scater} SCESet for 
#' use with older versions of \pkg{scater} and \pkg{scran}. In order to use this 
#' function, you must have mitochondrial and ribosomal genes in your expression 
#' data.
#'
#' @param object An \code{\linkS4class{EMSet}} object.
#' @param control.list Optional - a named list containing mitochondrial and 
#' ribosomal genes.
#' @return A SCESet
#' @examples
#' \dontrun{
#' sce_set <- ConvertToSCESet(em.set, 
#' control.list = list(Mt = mt.genes, Rb = rb.genes))
#' }
#' @importFrom scater newSCESet calculateQCMetrics
#' @export
#'
ConvertToSCESet <- function(object, control.list = list()) {
  # Prepare control list
  control.names <- c("Mt", "Rb")
  
  # Retrieve controls from EMSet object if user hasn't supplied a list
  if (length(control.list) == 0) {
    control.list <- object@Controls
  }
  
  if (length(control.list) == 0) {
    # Verify Mt and Rb are names in supplied list
    if (!all(control.names %in% names(control.list))) {
      stop("Please make sure you have supplied mitochondrial and ribosomal gene identifiers in a named list.")
    }
    
    # Verify genes are present in the list
    if (!all(sapply(control.list, function(x) length(x) > 0))) {
      stop("Please make sure you have supplied genes to the mitochondrial and ribosomal gene lists.")
    }
    
    expression.matrix <- GetExpressionMatrix(object, "data.frame")
    sce.obj <- scater::newSCESet(countData = expression.matrix)
    sce.obj <- scater::calculateQCMetrics(sce.obj, feature_controls = control.list)
  } else {
    expression.matrix <- GetExpressionMatrix(object, "data.frame")
    sce.obj <- scater::newSCESet(countData = expression.matrix)
  }
  
  # Convert EMSet to SCESet
  return(sce.obj)
}

#' ConvertToSCE
#'
#' Convert a \code{\linkS4class{EMSet}} object into a SingleCellExperiment object for 
#' use with \pkg{scater}, \pkg{scran} and other Bioconductor packages.
#' 
#' In order to use this function, you must have mitochondrial and ribosomal 
#' genes in your expression data.
#'
#' @param object An \code{\linkS4class{EMSet}} object.
#' @param control.list Optional - a named list containing mitochondrial and 
#' ribosomal genes.
#' @return A SingleCellExperiment object
#' @examples
#' \dontrun{
#' single_cell_experiment <- ConvertToSCE(em.set, control.list = list(
#' Mt = mt.genes, Rb = rb.genes
#' ))}
#' @export
#' @importFrom scater calculateQCMetrics
#'
ConvertToSCE <- function(object, control.list = list()) {
    # Prepare control list
    control.names <- c("Mt", "Rb")

    # Retrieve controls from EMSet object if user hasn't supplied a list
    if (length(control.list) == 0) {
        control.list <- object@Controls
    }

    if (length(control.list) > 0) {
        # Verify Mt and Rb are names in supplied list
        if (!all(control.names %in% names(control.list))) {
            stop("Please make sure you have supplied mitochondrial and ribosomal gene identifiers in a named list.")
        }

        # Verify genes are present in the list
        if (!all(sapply(control.list, function(x) length(x) > 0))) {
            stop("Please make sure you have supplied genes to the mitochondrial and ribosomal gene lists.")
        }
        
        expression.matrix <- GetExpressionMatrix(object, "matrix")
        
        # Extract Controls
        mito.genes <- control.list[["Mt"]]
        ribo.genes <- control.list[["Rb"]]
        mito.bool <- rownames(expression.matrix) %in% mito.genes
        ribo.bool <- rownames(expression.matrix) %in% ribo.genes
        
        sce.obj <- SingleCellExperiment::SingleCellExperiment(list(counts = expression.matrix))
        sce.obj <- scater::calculateQCMetrics(sce.obj, feature_controls = list(Mt=mito.bool, Rb=ribo.bool))
        
    } else {
        expression.matrix <- GetExpressionMatrix(object, "data.frame")
        sce.obj <- SingleCellExperiment::SingleCellExperiment(list(counts = expression.matrix))
    }

    # Convert EMSet to SingleCellExpression object
    return(sce.obj)
}

#' SCESet2EMset
#'
#' Loads data from a SCESet to a pre-existing 
#' \linkS4class{EMSet} object.
#' 
#' @param SCESet A SCESet from \pkg{scater}.
#' @param EMSet An \code{\linkS4class{EMSet}} to load data from.
#' @return An \code{\linkS4class{EMSet}} with data retrieved from a SCESet.
#' @export
#'
SCESet2EMSet <- function(SCESet, EMSet) {
    # Retrieve counts from SCESet
    expression.matrix <- BiocGenerics::counts(SCESet)

    # Convert to sparse, re-run metrics and add to slot
    EMSet <- ReplaceExpressionMatrix(EMSet, expression.matrix)

    # Sync up the object
    EMSet <- SyncSlots(EMSet)

    # Return updated object
    return(EMSet)
}
