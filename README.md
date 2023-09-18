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

![image](https://github.com/danidean/Bacteria-granule-quantefication/assets/11374080/16f563e4-48ad-4e2e-afca-e657ec6ac1ff)

## Workflow
1.	Open selected image
2.	Segment the bacteria and granules
  •	Apply ilastik autocontext classifier to obtain segmentation map model
  •	Segment bacteria using thresholding (default) applied to the segmentation map, to output a binary mask followed by hole filling.
  •	Filter the masked bacteria ROIs based on size (area) and shape (circularity) metrics to obtain legit bacteria ROIs. 
  •	Run Roi to label image on the bacteria ROIs to generate bacteria labeled image.
  •	Segment the granules using thresholding (default) to the segmentation map, to output binary mask.
  •	Filter the masked granules ROIs based on size (area) and shape (circularity) metrics to obtain legit bacteria ROIs. Apply granules-bacteria colocalization analysis by applying (measuring)   granules ROIs on bacteria labeled image. This step colocalizes the granules to their respective bacteria.
  •	Obtain the area of each granule, the number of granules per bacteria and the average size of the granules per bacteria.


## Output
The macro saves the following output files (see below for details):
1.	Bacteria and granules ROI tables
2.	Bacteria and granules result tables
3.	Summary table for all image files analyzed
4.	The original image with the bacteria and granules ROIs overlays

## Dependencies
•	Fiji: https://imagej.net/Fiji
•	Ilastik pixel classifier (ilastik-1.4.0rc8) https://www.ilastik.org/
•	Ilastik Fiji Plugin (we used ilastik4ij-1.8.2.jar which is available in: https://sites.imagej.net/Ilastik/plugins/. 

## User Guide
•	Run the code, upon which UI will open:

![image](https://github.com/danidean/Bacteria-granule-quantefication/assets/11374080/922f8a8d-fc02-4358-a311-2dc6f65c5940)
