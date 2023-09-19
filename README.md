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
<!-- https://github.com/danidean/Bacteria-granule-quantefication/assets/11374080/16f563e4-48ad-4e2e-afca-e657ec6ac1ff -->
## Workflow
1.	Open selected image
2.	Segment the bacteria and granules
*  Apply ilastik autocontext classifier to obtain segmentation map model
* Segment bacteria using thresholding (default) applied to the segmentation map, to output a binary mask followed by hole filling.
* Filter the masked bacteria ROIs based on size (area) and shape (circularity) metrics to obtain legit bacteria ROIs. 
* Run Roi to label image on the bacteria ROIs to generate bacteria labeled image.
* Segment the granules using thresholding (default) to the segmentation map, to output binary mask.
* Filter the masked granules ROIs based on size (area) and shape (circularity) metrics to obtain legit bacteria ROIs.  Apply granules-bacteria colocalization analysis by applying (measuring)   
    granules ROIs on bacteria labeled image. This step colocalizes the granules to their respective bacteria.
* Obtain the area of each granule, the number of granules per bacteria and the average size of the granules per bacteria.


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
•	Run the code (Bacteria_Granule_colocalization_v3.ijm), upon which UI will open:

![image](https://github.com/danidean/Bacteria-granule-quantefication/assets/11374080/922f8a8d-fc02-4358-a311-2dc6f65c5940)

## INPUT
•	Two runs modes are applicable, “directory mode" or “single mode".
-	Directory mode - identifies all the relevant images to be processed and process a file at a time
-	Single mode - a single file is selected for processing.
•	Classification is based on a pretrained ilastik model. The path to the ilastik app and model should be provided
•	Several Program-run-modes "degrees of freedom" are provided for processing:
-	Use pre/post classification images
-	redo/skip already classified images, 
-	use original or modified bacteria detection
•	User provided image units (e.g. [µm/pixel]) and objects (bacteria/granule) thresholds in the same units

## Processing
•	In whole directory mode, a list of the relevant images is generated and the code loops over the images and processes them sequentially
•	depending on the selected process option the images are analyzed according to:
-	"Pre-segmentation" / "Post-segmentation" implies whether the image selected has been previously model-based segmented:
"Pre-segmentation" - will run the model on the image and segment (classify) it.
"Post-segmentation" - will load the previously segmented image and continue the process flow based on it.

-	"Redo" / "Skip" implies if to redo the model-based classification even if a classified image exists, when running the "Pre-segmentation":
"Redo" - segments again the images.
"Skip" - skips already segmented images.
-	"Segmentation" / "Update" indicates whether the original model-segmented roiManager is used or a user modified/updated ROIs-roiManager is selected for bacteria/granule processing.

Run-Mode selection logic:
"Pre-segmentation" selection implies "Segmentation" mode;
"Post-segmentation" selection enables selecting between "Segmentation" / "Update".

## Manuel correction
The above described process correctly segments most of the bacteria. Additional, manual annotation is supported ny selecting update mode for “Select methodology mode”:

![image](https://github.com/danidean/Bacteria-granule-quantefication/assets/11374080/f3de54a2-39cc-4cc3-867a-daaf7c3959dc)

In Update mode the macro skips the segmentation, instead it gets the segmented ROIs from a file, and calculate their updated measurements. The ROIs are read either from manually updated file (naming convention –  FN_Fused_Raw_Bacteria_Roi_Update.zip if exist) or otherwise from the original file (FN_Fused_Raw_Bacteria_Roi.zip).
The manual correction is done offline and the update ROI file (uploads into imageJ/Fiji roiMnanger) is appended with the “_Update” suffix (see example above) to distinguish it from the original model-based segmentation/classification.

## Output
-	Three tables:
	Bacteria summary table with data including size, number of granule residing in the bacteria and corresponding mean size. A table per file (FN__Fused_Granule_Results_Table.txt).
	Granule summary table with data corresponding to their estimated size and a "link" to the bacteria they reside in. A table per file (FN__Fused_Bacteria_Results_Table.txt).
	A "Summary Report Table" that stores information for all the files processed. The metrics stored correspond to the number of bacteria and granule after segmentation and following filtering (FN_ Summary_Report_Table.txt). 
Additionally, it includes a flag indicating whether the image processed resulted in detected bacteria or granule, or no bacteria/granule where detected.
-	Two ROI files (imagej/Fiji roiManager tables): 
	 ROIs corresponding to the bacteria and granules
(FN_Bacteria_Roi.zip, FN_Granule_In_Bacteria_Roi.zip, respectively).
-	Two images:
	Model-segmented image (FN_classified.tif)
	Raw image overplayed with bacteria + granule ROIs (overlayed_img_FN.tif). 

## References
[1] Preibisch S, Saalfeld S, Tomancak P. Globally optimal stitching of tiled 3D microscopic image acquisitions. Bioinformatics. 2009 Jun 1;25(11):1463-5. doi: 10.1093/bioinformatics/btp184. Epub 2009 Apr 3. PMID: 19346324; PMCID: PMC2682522. 

[2] Stuart Berg, Dominik Kutra, Thorben Kroeger, Christoph N. Straehle, Bernhard X. Kausler, Carsten Haubold, Martin Schiegg, Janez Ales, Thorsten Beier, Markus Rudy, Kemal Eren, Jaime I Cervantes, Buote Xu, Fynn Beuttenmueller, Adrian Wolny, Chong Zhang, Ullrich Koethe, Fred A. Hamprecht & Anna Kreshuk.  ilastik: interactive machine learning for (bio)image analysis. Nat Methods 16, 1226–1232 (2019). https://doi.org/10.1038/s41592-019-0582-9 

[3] Schindelin, J., Arganda-Carreras, I., Frise, E., Kaynig, V., Longair, M., Pietzsch, T., … Cardona, A. (2012). Fiji: an open-source platform for biological-image analysis. Nature Methods, 9(7), 676–682. doi:10.1038/nmeth.2019
