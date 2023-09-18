# Bacteria-granule-quantefication 
## Size quantification and distribution of Polyphosphate-like granules (pPLGs) located within Deinococcus indicus bacteria


## Problem Statement
Quantify the number and size of granules residing within Deinococcus indicus bacteria based on EM imaging.

## Methodology
### Imaging
To quantify the size and distribution of pPLGs within the bacteria, we used tiling and stitching to cover large field of view with multiple bacteria. 
Stitching was done using Fiji Grid/Collection stitching plugin [1].
We then segmented individual bacteria and individual granules residing within them and measured the number of granules and their average and total size within each bacterium.  

### Model training
To segment the bacteria and granules, we used a workflow combining Ilastik [2] pixel classifier followed by further processing using dedicated Fiji [3] macro. We used multiple fields of view from different conditions for training two-stage machine-learning classifier in Ilastik "autocontext" approach to classify pixels into four categories: bacteria, granules, background and unclassified.

### Bacteria, granules identification and quantification
The trained classifier was applied to the stitched images in Fiji [3]. Bacteria were segmented based on connected component analysis of a filled mask of all pixels classified as bacteria, followed by size (1.6 < size[µm2] < 6]) and shape filtering (circularity > 0.2).
Granules were then segmented based on connected component analysis of a mask of all pixels classified as granules within segmented bacteria and further filtered by size (0.012 < size[µm2] < 0.12]) and shape (circularity > 0.3).
Manual correction was applied to correct the segmentation of some missed or falsely detected bacteria. (Fiji macro: quantitative_estimation_of_granules_in_bacteria.ijm)
The size and number of all valid bacteria and granules were extracted and used for further analysis.

![Bacteria-Granule images] ()
