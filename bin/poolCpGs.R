#!/usr/bin/env Rscript

# Usage:
# poolCpGs.R input_dir output_file [libraries.csv]
# libraries.csv is an optional single-column csv file specifying which libraries
# in input_dir to pool (by filename). If not specified, all libraries will be pooled.



library(data.table)
library(rtracklayer)
library(getopt)
library(dplyr)

spec <- matrix(c(
  'beddir', 'i', 1, "character",
  'outfile', 'o', 1, "character",
  'libraries', 'l', '1', "character"
), byrow=TRUE, ncol=4)

opt <- getopt(spec)

if (length(opt)<3) {
	stop("Usage: poolCpGs.R -i input_dir -o output_file [-l libraries.csv]", call.=FALSE)
}

bed.dir <- opt$beddir
out.file <- opt$outfile
bed.dir
out.file
if(length(opt)==3)
{
	library.list <- dir(bed.dir)#, pattern='CpG')
}
library.list
if(length(opt)==4)
{
	library.spec <- read.csv(opt$libraries)
	library.list <- dir(bed.dir)#, pattern='CpG')
	library.file.indices <- sub('\\..*', '', library.list)
	library.list <- library.list[which(library.file.indices %in% library.spec[,1])]
}

readOneLibrary <- function(cpg.file.name)
	{
		cpg.bed <- fread(cpg.file.name)
		colnames(cpg.bed) <- c('chr', 'start', 'direction' , 'cpg', 'meth_reads', 'all_reads')
		cpg.bed <- mutate(cpg.bed, end = start+1)
		cpg.bed <- cpg.bed[,c("chr","start","end","direction", "cpg", "meth_reads", "all_reads")]
		cpg.bed
	}


#' Pool two GenomicRanges, by summing specified fields from elementMetadata
#' when there are overlaps between the two.
#' @param grange.1 First GenomicRanges
#' @param grange.2 Second GenomicRanges
#' @param sum.fields Vector of names of fields to sum
#' @return A GenomicRanges object, pooled from grange.1 and grange.2
poolTwoGRanges <- function(grange.1, grange.2, sum.fields)
{
	overlaps <- findOverlaps(grange.1, grange.2, minoverlap = 2)
	if(length(overlaps)==0)
		return(c(grange.1[-c(queryHits(overlaps))], grange.2[-c(subjectHits(overlaps))]))

	overlap.metadata <- as.data.frame(elementMetadata(grange.1)[queryHits(overlaps),sum.fields]) +
	as.data.frame(elementMetadata(grange.2)[subjectHits(overlaps), sum.fields])
	overlap.gr <- grange.1[queryHits(overlaps)]
	elementMetadata(overlap.gr) <- overlap.metadata

	elementMetadata(grange.1) <- elementMetadata(grange.1)[,sum.fields]
   	elementMetadata(grange.2) <- elementMetadata(grange.2)[,sum.fields]


	return(c(grange.1[-c(queryHits(overlaps))], grange.2[-c(subjectHits(overlaps))], overlap.gr))

}

poolGRangesFromDir <- function(bed.dir, library.list,
							   sum.fields= c('meth_reads', 'all_reads'))
{
	pooled.bed <- readOneLibrary(file.path(bed.dir, library.list[1]))
	pooled.bed
	pooled.grange <- makeGRangesFromDataFrame(pooled.bed, keep.extra.columns=TRUE)

	for (library.name in library.list[-1])
	{
		message(paste('Pooling library', library.name))
		new.bed <- readOneLibrary(file.path(bed.dir, library.name))
		new.grange <- makeGRangesFromDataFrame(new.bed, keep.extra.columns=TRUE)
		pooled.grange <- poolTwoGRanges(pooled.grange, new.grange, sum.fields )
		gc()
	}

	return(pooled.grange)
}

pooled <- poolGRangesFromDir(bed.dir, library.list)

write.csv(as.data.frame(pooled)[, c('seqnames', 'start', 'all_reads', 'meth_reads')],
		  file=out.file, row.names = FALSE)



#Next:
# Load in tables to be pooled, one at a time
# Cumulatively pool them
# Write output to a new bed file, in DSS/BSmooth-preferred format
