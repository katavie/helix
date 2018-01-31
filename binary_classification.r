# load package to access Ensembl
library(biomaRt)

mart = useMart(biomart = 'ensembl', dataset = 'hsapiens_gene_ensembl')

# list of gene IDs
IDs <- read.csv('mart_export.csv')
# subset with gene type == 'protein_coding'
IDs <- IDs[IDs$Gene.type == 'protein_coding', ] # end up with 160,705 IDs
geneIDs <- IDs$Gene.stable.ID

# get individual exons: 523,351 observations
exons <- biomaRt::getSequence(id = geneIDs,
                              type = 'ensembl_gene_id',
                              seqType = 'gene_exon',
                              mart = mart)
exons$type <- 'exon'
colnames(exons) <- c('seq', 'geneID', 'type')
write.csv(exons, 'data_exons.csv')
#read.csv('data_exons.csv')

# get un-separated sequences of introns and exons: 22,650 observations
exons_introns <- biomaRt::getSequence(id = geneIDs,
                                      type = 'ensembl_gene_id',
                                      seqType = 'gene_exon_intron',
                                      mart = mart) # 5' to 3'
colnames(exons_introns) <- c('exon_intron', 'geneID')
write.csv(exons_introns, 'data_exons-introns.csv')
#read.csv('data_exons_introns.csv')

# match exons to exons_introns, replace exons with \n to be used as divider
for (exon in exons$exons) {
  for (i in 1:length(exons_introns$exon_intron)) {
    exons_introns[[1]][i] <- gsub(
      pattern = exon,
      replacement = ' ',
      x = exons_introns$exon_intron[i]
    )
  }
}

introns_vec <- as.vector(strsplit(exons_introns$exon_intron, ' '))
introns_df <- as.data.frame(as.matrix(unlist(introns_vec)))
introns_df$type <- 'intron'
colnames(introns_df) <- c('seq', 'type')
write.csv(introns_df, 'data_introns.csv')

# combined dataset
exons_df <- subset(exons, select=-geneID)
data <- rbind(introns_df, exons_df)
write.csv(data, 'data.csv')