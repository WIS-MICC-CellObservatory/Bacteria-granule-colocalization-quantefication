/* Bacteria-Granule colocalozation and metrics*/


/*	
 * Purpose:
 * The program segments and identifies bacteria cells and granule whithin the bacteria. 
 * The program identifies/filters legitimate bacteria and garnule based on predefined thresholds (size, circularity),
 * and calculates the size of each. it also provides the mean granule size per bacteria.
 * A summary table tracks the number of model-segmented bacteria and granule before (raw) and after (legit)  filtering
 * for each image. 
 * The summary table generates an summary statistics per analyzed image, a line per image.
 * 
 * Methodology:
 * The processing is initialized via a GUI prompting to provided input for the processing
 *  INPUT:
 * 	1.1. Two runs modes are appilcable, run on "directory mode" or single mode".
 * 	Directory mode - identifies all the relevant images to be processed and process a file at a time
 * 	Single mode - a signle file is selected for processing.
 * 	1.2. Segmentation/classification is based on a pretrained ilastik model. The path to the ilastik app and model should be provided
 * 	1.3 program run "degrees of freedom" are provided for processing 
 * 		- pre/post classfication, 
 * 		- redo/skip aready classified images, 
 * 		- use original or modified bacteria detection
 * 	1.4 User provided image units and objects (bacteria/granule) thresolds
 * 	
 *  PROCESSING:
 * 	1.1 In whole directory mode, a list of the relevant images is generated and the code loops over the images and processes them sequentially
 * 	1.2 depending on the selected process option the images are analyzed according to:
 * 	 - "Pre-segmentation" / "Post-segmentation" implies whether the image selected has been previously model-based segmented.
 * 	 	"Pre-segmentation" - will run the model on the image and segment (classify) it.
 * 	 	"Post-segmentation" - will load the previously segmented image and continue the process flow based on it.
 * 	 - "Redo" / "Skip" implies if to redo the model-based classification even if a classified image exists ,when running the "Pre-segmentation"
 * 	   "Redo" - segments again the images
 * 	   "Skip" - skips already segmented images
 * 	 - "Segmentation" / "Update" indicates whether the original model-segmented roiManager is used or a user modified/updated ROIs-roiManager is selected for bacteria/granule processing.
 * 	 
 * 	Rum mode Selection logics:
 * 	 - "Pre-segmentation" selection implies "Segmentation" mode.
 * 	 - "Post-segmentation" selection enables selecting between "Segmentation" / "Update" 
 * 	
 * 	Based on the model based segmentation:
 * 	2. The process flow starts with identifing the bacteria-labeled ROIs, followed by filtering out bateria based on size and shape (circularity) criteria (currently filtering by shape metric isn't applied)
 * 	3. Once legit bacteria ROIs are detected, granule-labeld ROIs are detected. 
 * 	3.1 Only granule whithin legit bacteria from (2.) filtered by size thresholds (currently filtering by shape metric isn't applied) are selected.
 * 	4. The size (area) of each bacteria along the number and mean of granule per bateria are calculated.
 * 	
 * Output:
 * Three tables:
 *  1. Bacteria summary table with data including size, number of granule residing in the bacteria and corresponding mean size. A table per file.
 *  2. Granule summary table with data corresponding to their estimated size and a "link" to the bacteria they reside in. A table per file.
 *  3. A "Summary Report Table" that stores information for all the files procesed. The metrics stored correspond to the number of bacteria and granule after segmentation and following filtering. 
 *  	Additionally, it includes a flag indicating if image processd resulted in detected bacteria or granule, or no bacteria/granule where detected.
 *  
 *  Two roiManager tables: 
 *  ROiManager tablescorresponding to the bacteria and granule both after segentation
 *  
 *  Two images:
 *  Model-segmentes image
 *  Raw image overlayed with bacterai + granule rois. ROIs arew from saved roiManagers.
 * 	  
 * 
 * 
 * 
 * 
 * 
 * 
 * 
 * 
 */

/* The mocro classifies in Fiji bacteria and granule whithin them
 *  by running pretrained ilaskic classifier. 
 *  Then, counts the number of granule per bacteria with additional metrics such as size and legit_granule_roi_vec
 *  
 *  
 * ToDo [20230321]
 * 1. Generate roiManager for initial granule
 * 2. Add granule idx to granuke results table
 * 3. Add bacteria idx to bacteria results table
 * 4. Calculate bacteria area 
 * 
 * 
 */
 close("*");
 
 /* General Global Variables */
 var ilastik_exe_file;
 var ilastik_project_file;
 var ilastik_classifier_mode;
 // var project_name_prefix;
 var run_process_mode;
 var img_classified_name = "img_classified";
 var img_classified_bacteria = img_classified_name + "_bacteria";
 var img_classified_granule = img_classified_name + "_granule";
 var img_masked_classified_bacteria = img_classified_bacteria + "_masked";
 var img_classified_bacteria_labeled = img_classified_bacteria + "_labeled";
 var classification_stage;
 var gran_per_full_bacteria_vec;
 var bactaria_size_intarval;
 var granule_size_intarval;
 var bactaria_size_lim;
 var granule_size_lim;
 var mean_bact_gran_area_vec;
 var legit_bacteria_roi_vec;
 var legit_bacteria_roi_name_vec;
 var Bacteria_idx_new; // After filtering //
 var functional_mode;
 var methodolofy_processing_mode_ext; // * data file Naming suffix  is segmented no extention; if Update - "update" added to file name * //
 var project_process_mode; // "Single File", "Whole Folder" /
 var filename_prefix;
 var redo_classification;
 var roi_gen_mode; // * Indicator on the generation of the roiManager/Rois: Segmentation or Manually updated/corrected * //
 var image_pathname;
 var graule_bacteria_list = "";
 var bacteria_roi_color; //  = "cyan";
 var granule_roi_color; //  = "magenta";
 var roi_obj_color;
 var user_run_ctrl;
 var project_name;
 var bacteria_segmentation_label = 1;
 var granule_segmentation_label = 2;
 var bg_segmentation_label = 3;
 var unclssified_segmentation_label = 4;
 
 
 /*  *** Input GUI *** */
#@ String (label="Process Mode", choices=("Single File", "Whole Folder"), style="list", persist = true) project_process_mode
#@ File (label="Input Directory", style = "directory", persist=true, description="Select File input dir of Analysis") input_dir // image_input_dir// file_input_dir
#@ File (label="Input File", style = "File", persist=true, description="Select File input of Analysis") image_pathname // file_input_dir
#@ String (Label = "Set project name", value = "Bacteria_Granule_Colocalization") project_name
#@ String (Label = "Set input image prefix", value = "", persist = true, description = "Set input image prefix (leave empty if none)") filename_prefix
#@ File (label="Set Output Location", style = "directory", persist=true, description="Select Results dir of Analysis") output_root_dir // results_dir
#@ File (label = "ilastik exe file", style = "File", persist = true, description = "Set ilastik exe file") ilastik_exe_file
#@ File (label = "ilastic classifican project file", style = "File", persist = true, description = "Get ilastik classification project file") ilastik_project_file
#@ string (Label = "Set classifier run model", choices = ("Run Autocontext Prediction", "Run Pixel Classification"), style = "list", persist = true) ilastik_classifier_mode
#@ String (Label = "Choose image - pre/post classification", choices = ("pre-classification", "post-classification"), style = "list", persist = true) classification_stage
#@ String (Label = "Skip classification stage if already done", choices = ("Skip", "Redo"), style = "list", persist = true, description = "Skip or redo and override previous model-based classification") redo_classification
#@ String (Label = "Select methodology mode", choices = ("Segmentation", "Update"), style = "list", persist = true) functional_mode

#@ String (Label = "-------------------------------------------------------------------", Value = "-----------------------------------------------------------------------------" ) none
#@ String (Label = "Manualy set pixel width and pixel hight: pixel_width/pixel_hight", Value = "pixel_width/pixel_height", persist = true, description = "Manually set the values of the pixels width/hight. If extracted from image, leave empty") pixel_width_hight
#@ String (Label = "Set Lower/Uower bacteria size", Value = "2/6") bactaria_size_intarval
#@ String (Label = "Set Lower/Upper granule size", Value = "0.012/0.12") granule_size_intarval
// #@ String (Label = "Set Bacteria/Granule image overlay color: Bacteria/Granule", Value = "cyan/magenta") roi_obj_color
#@ String (Label = "Set Bacteria roi color", style = "list", choices = ("cyan", "magenta", "red", "green", "blue", "yellow"), persist = true, description = "Set bacteria roi color for overlay on image") bacteria_roi_color
#@ String (Label = "Set Granule roi color", style = "list", choices = ("cyan", "magenta", "red", "green", "blue", "yellow"), persist = true, description = "Set granule roi color for overlay on image") granule_roi_color
#@ String (Label = "Stop after each image", style = "list", choices = ("No", "Yes"), description = "Stop after each image analysis, and wait for used prompt to continue to next image") user_run_ctrl


 /* Image Parameters */
 var pixel_width = 0.0066636;
 var pixel_height = 0.0066636;
 
  /* Thresh Parameters */
 var bact_circ_min = 0.2;
 var bact_circ_max = 1.0;
 var gran_circ_min = 0.3;
 var gran_circ_max = 1.0;
 var bact_size_min_pixel = 1000;
 var gran_size_min_pixel = 10;


var img_name_no_ext;//  = File.nameWithoutExtension;
var prev_img_name_no_ext = "";
var output_dir = output_root_dir + "/"  + "Output_Dir/";
	File.makeDirectory(output_dir); // output_root_dir + File.separator  + "Output_Dir"

var Bacteria_Results_Table = "Bacteria_Results_Table";
var Granule_Results_Table = "Granule_Results_Table";
var Granule_Metrics_table = "Granule_Metrics_Table";
var Mean_Bact_Gran_Area_Table = "Mean_Bact_Gran_Area_Table";
var Summary_Report_Table = "Summary_Report_Table";
var Granule_Initial_roiManager = "Granule_Initial_roiManager";
var overlayed_roi_raw_img; 
var bacteria_roi_filename;
var area_normalization = pixel_width * pixel_height; // 4.440356496000001e-05;
var gran_idx_vec;
var img_name_ext;

/* Flags */
var process_img_flag;
var raw_bacteria_num;
var legit_bacteria_num;
var raw_granule_num;
var legit_granule_num;

/*   Main   */
Cleanup();
Setup();
Initialize();

main();
		
/*  *** Functions *** */
/*--------------------*/

function Cleanup() 
{		
	close("*");
	/*
	  roiManager = RoiManager.getRoiManager();
	  roiManager.close();
	*/	 
	if (isOpen("ROI Manager")) 
	{
	     selectWindow("ROI Manager");
	     run("Close");
	}

	if (isOpen("Results")) 
	{
	     selectWindow("Results"); 
	     run("Close" );	      
	}	
	
	if (isOpen(Bacteria_Results_Table))
	{
		selectWindow(Bacteria_Results_Table);
		run("Close");
	}
	
	
	if (isOpen(Granule_Results_Table))
	{
		selectWindow(Granule_Results_Table);
		run("Close");
	}
	
	if (isOpen(Granule_Metrics_table))
	{
		selectWindow(Granule_Metrics_table);
		run("Close");
	}
	
	if (isOpen("Summary")) 
	{
	     selectWindow("Summary"); 
	     run("Close" );	      
	}

	if (isOpen("Log")) 
	{
	     print("\\Clear");
	}
}

function clear_Img_Prefixed_Resultes_Tables()
{
	
	filename = prev_img_name_no_ext + "_" + Bacteria_Results_Table +".txt";
	// // waitForUser("Delete Bacteria_Results_Table = " + filename);
	// // waitForUser(isOpen(filename));
	if (isOpen(filename))
	{
		selectWindow(filename);
		run("Close");
		wait(5);
	}	
	
	filename = prev_img_name_no_ext + "_" + Granule_Results_Table+ ".txt";
	// // waitForUser("Delete Granule_Results_Table = " + filename);
	if (isOpen(filename))
	{
		selectWindow(filename);
		run("Close");
		wait(5);
	}	
	
	filename = prev_img_name_no_ext + "_" + Mean_Bact_Gran_Area_Table + ".txt";
	if (isOpen(filename))
	{
		selectWindow(filename);
		run("Close");
		wait(5);
	}	
}

function Setup()
{
	// run("Properties...", "channels=1 slices=1 frames=1 pixel_width = pixel_width pixel_height = pixel_height voxel_depth=1.0000000");
	//run("Set Measurements...", "area mean standard min centroid perimeter fit integrated median area_fraction redirect=None decimal=3");
	//run("Set Measurements...", "area mean standard min centroid perimeter fit integrated median area_fraction redirect=None decimal=3");
	run("Set Measurements...", "area mean min centroid redirect=None decimal=3");
}

function Initialize()
{	
	/* Get bacteria size limits */
	ii = bactaria_size_intarval.indexOf("/");
	bactaria_size_lim = newArray(parseFloat(bactaria_size_intarval.substring(0, ii)), parseFloat(bactaria_size_intarval.substring(ii+1, bactaria_size_intarval.length))); // 20230416 Added parseFloat to bactaria_size_lim
	ii = granule_size_intarval.indexOf("/");
	granule_size_lim = newArray(parseFloat(granule_size_intarval.substring(0, ii)), parseFloat(granule_size_intarval.substring(ii+1, granule_size_intarval.length)));

	if (!pixel_width_hight.matches(""))
	{				
		jj = pixel_width_hight.indexOf("/");
		pixel_width = parseFloat( pixel_width_hight.substring(0, jj) );
		pixel_height = parseFloat( pixel_width_hight.substring(jj + 1, pixel_width_hight.length) );
		area_normalization = pixel_width * pixel_height; 
	}	
	/*
	else
	{
		getPixelSize(unit, pixelWidth, pixelHeight);
		area_normalization = pixel_width * pixel_height; 
	}
	*/
}

function main()
{	
	Table.create(Summary_Report_Table);
	input_dir += File.separator;
	
	if (project_process_mode.matches("Whole Folder"))
	{	
		img_list = get_File_List();
		img_num  = img_list.length;
		
		
	 	title = "[Progress]";
	  	run("Text Window...", "name="+ title +" width=25 height=2 monospaced");
		
		for (img_i = 0; img_i < img_list.length; img_i++)
		{
			
			
		     print(title, "\\Update:" + (img_i + 1) + "/" + img_num +" (" + ((img_i + 1) * 100)/img_num + "%)\n" + get_Bar(img_i, img_num));
		     wait(200);
			
			
			if (img_i == 0)
				{ prev_img_name_no_ext = File.getNameWithoutExtension(img_list[img_i]); }
			else 
				{ prev_img_name_no_ext = File.getNameWithoutExtension(img_list[img_i - 1]); }
				
			img_name_no_ext = File.getNameWithoutExtension(img_list[img_i]); 

			Cleanup();
			
			/* --- Main Processing function --- */
			selectWindow(Summary_Report_Table);
			Table.set("File name", img_i, img_name_no_ext, Summary_Report_Table);
			
			/* Main processing function */
			process_img_flag = process_Img(input_dir + img_list[img_i], img_i);		
			
			/* Save Summary_Report_Table after each image for process tracking */
			selectWindow(Summary_Report_Table);
			saveAs("results", output_dir + project_name + "_" + Summary_Report_Table + ".txt");
			Table.rename(project_name + "_" + Summary_Report_Table + ".txt", Summary_Report_Table);
			
			if (process_img_flag.matches("no_legit_bacteria"))
			{
				continue;
			}
			
			else 
			{
				overlay_Rois_On_Image(img_name_ext); /* --- Overlay bacteria & granule ROIs on raw image --- */
				save_Results_Tables();			
				// waitForUser("After process_Img = " + img_i);
			}
			
			// waitForUser(user_run_ctrl);
			if (user_run_ctrl.matches("Yes"))
			{
				waitForUser("User run controll" , "Continue with next image [" + toString(img_i + 1) +"/" + toString(img_num) + "]?"); 
			}
			selectWindow("Progress");
		}
		print(title, "\\Close"); // Close progress bar

	}
	
	else	 //* Singl file analysis *//
	{			
		img_i = 0;
		img_name_no_ext = File.getNameWithoutExtension(image_pathname); 
		selectWindow(Summary_Report_Table);
		Table.set("File name", img_i, img_name_no_ext, Summary_Report_Table);
		process_img_flag = process_Img(image_pathname, img_i);	
		
		selectWindow(Summary_Report_Table);
		saveAs("results", output_dir + project_name + "_" + Summary_Report_Table + ".txt");
		Table.rename(project_name + "_" + Summary_Report_Table + ".txt", Summary_Report_Table);
		

		selectWindow(Summary_Report_Table);
		saveAs("results", output_dir + img_name_no_ext + "_" + Summary_Report_Table + ".txt");
		
		if (process_img_flag.matches("no_legit_bacteria"))
		{ 						
			continue;
		}
		
		else 
		{	
			overlay_Rois_On_Image(img_name_ext); /* --- Overlay bacteria & granule ROIs on raw image --- */
			save_Results_Tables();
		}

	}
	
	
	waitForUser(" *** Process Completed *** ");

}

function process_Img(image_full_name, img_i)
{
	/* ----- Main processing part ----- */
	// Cleanup();
	open(image_full_name);
	img_name_ext = File.name;
	overlayed_roi_raw_img = "overlayed_img_" + img_name_ext;
	img_name_no_ext = File.nameWithoutExtension;
	
	
	/* --- Clear previouse Results tables --- */
	if (img_i > 0) 
		{clear_Img_Prefixed_Resultes_Tables();} // * Delete results tables with namemin prefixed by image name * //
	
	
	selectWindow(img_name_ext);

	if (classification_stage.matches("pre-classification"))
	{	
		if (redo_classification.matches("Redo"))
		{
			if (ilastik_classifier_mode.matches("Run Pixel Classification"))
			{	run(ilastik_classifier_mode, "projectfilename=" + ilastik_project_file + " inputimage=" + img_name_ext + " pixelclassificationtype=Segmentation");	}
			
			else 
			{	run(ilastik_classifier_mode, "projectfilename=" + ilastik_project_file + " inputimage=" + img_name_ext + " autocontextpredictiontype=Segmentation");	}
			saveAs("tiff", output_dir + File.separator + img_name_no_ext + "_classified");
		}
		
		else 
		{	
			classified_img_name = img_name_no_ext + "_classified.tif"; // "_classified.tif"
			classified_img_flag = File.exists(output_dir + classified_img_name);
			
			// * Verify classified image exists * //
			if (classified_img_flag == 1)
			{
				open(output_dir + classified_img_name);
			}
			
			else 
			{
				if (ilastik_classifier_mode.matches("Run Pixel Classification"))
				{	run(ilastik_classifier_mode, "projectfilename=" + ilastik_project_file + " inputimage=" + img_name_ext + " pixelclassificationtype=Segmentation");	}
				
				else 
				{	run(ilastik_classifier_mode, "projectfilename=" + ilastik_project_file + " inputimage=" + img_name_ext + " autocontextpredictiontype=Segmentation");	}
					saveAs("tiff", output_dir + File.separator + img_name_no_ext + "_classified");
			}
		}

	}
	
	else // * Use classified ("post-classification") image * //
	{
		classified_img_name = img_name_no_ext + "_classified.tif"; // "_classified.tif"
		classified_img_flag = File.exists(output_dir + classified_img_name);

		// * Verify calssified image exists * //
		if (classified_img_flag == 1)
		{
			open(output_dir + classified_img_name);
		}
		
		else {
			Table.set("Process Summary", img_i, "Not Classified", Summary_Report_Table);
			continue;
		}
	}
	
	rename(img_classified_name);

	run("Brightness/Contrast...");
	run("Enhance Contrast", "saturated=0.35");
	run("Options...", "iterations=1 count=1 black do=Nothing");

	/******* Bacteria ROIs *******/

			/* Segmentation */
	run("Duplicate...", "title=" + img_classified_bacteria);
	selectWindow(img_classified_bacteria);
			/* **** */
	
	/*  - Bacteria segmantation includes the garanule labelinf in order to take care of granule on hte bourders of he bacteria -  */
	setThreshold(bacteria_segmentation_label - 0.1, granule_segmentation_label + 0.1);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Fill Holes");
	rename(img_masked_classified_bacteria);

			/* --- Labeling ---- */
	selectWindow(img_masked_classified_bacteria);
	
	getPixelSize(unit, pixelWidth, pixelHeight);
	if (pixel_width_hight.matches(""))
	{
		getPixelSize(unit, pixel_width, pixel_height);
		area_normalization = pixelWidth * pixelHeight;
		pixel_width = pixelWidth;
		pixel_height = pixelHeight;
	}
	
	if (matches(unit,"pixels") || matches(unit,"pixel"))
	{
		size_factor = area_normalization;
		length_factor = sqrt(size_factor);
	}
	
	else 
	{	
		size_factor = 1; // area_normalization; 
		length_factor = 1; // sqrt(size_factor); 
	}
	
	// * Segmentation processing mode* //
	if (classification_stage.matches("pre-classification")) // Force segmentation processing if the image was just classified //
		{functional_mode = "Segmentation";}
		
	if (functional_mode.matches("Segmentation"))
	{	
		run("Set Measurements...", "area mean min centroid redirect=None decimal=3");
		run("Analyze Particles...", "size=" + bact_size_min_pixel + "-Infinity circularity=" + bact_circ_min + "-" + bact_circ_max + " show=[Overlay Masks] display summarize add");
		roi_gen_mode = "Segmented";
		Table.set("Classification Mode", img_i, roi_gen_mode, Summary_Report_Table);
		raw_bacteria_roiManager = output_dir + img_name_no_ext + "_Raw_Bacteria_Roi.zip";
		roiManager("save", raw_bacteria_roiManager);
	}	
	
	else  // * Use "Update" processing mode * //
	{
		bacteria_roi_filename = img_name_no_ext + "_Raw_Bacteria_Roi_Update.zip";
		bacteria_roi_pathname = output_dir + bacteria_roi_filename; 
		print(bacteria_roi_pathname);
		update_roi_flag = File.exists(bacteria_roi_pathname); 
		if (update_roi_flag == 1)
		{			
			roiManager("open", bacteria_roi_pathname );			
			run("Set Measurements...", "area mean min centroid fit redirect=None decimal=3");
			roiManager("measure");		
			roi_gen_mode = "Updated";
			Table.set("Classification Mode", img_i, roi_gen_mode , Summary_Report_Table);
		}
		
		else
		{	
			bacteria_roi_filename = img_name_no_ext + "_Bacteria_Roi.zip";
			bacteria_roi_pathname = output_dir + bacteria_roi_filename; 
			update_roi_flag = File.exists(bacteria_roi_pathname);
			if (update_roi_flag == 0)
			{
				 /* The same as 'Segmantation' mode */
				run("Set Measurements...", "area mean min centroid redirect=None decimal=3");
				run("Analyze Particles...", "size=" + bact_size_min_pixel + "-Infinity circularity=" + bact_circ_min + "-" + bact_circ_max + " show=[Overlay Masks] display summarize add");
				roi_gen_mode = "Segmented";
				Table.set("Classification Mode", img_i, roi_gen_mode, Summary_Report_Table);
			}
			roiManager("open", bacteria_roi_pathname );
			roi_gen_mode = "Segmented";
			Table.set("Classification Mode", img_i, roi_gen_mode, Summary_Report_Table);
			run("Set Measurements...", "area mean min centroid fit redirect=None decimal=3");
			roiManager("measure");				
			// continue;
		}
	}	
	bacteria_num = roiManager("count");	
	
	/* --- Update Summary Table --- */
	raw_bacteria_num = bacteria_num;
	Table.set("Raw Bacteria Num", img_i, raw_bacteria_num, Summary_Report_Table);
	
	if (bacteria_num == 0)
	{			/* --- Update Summary Table --- */
		Table.set("Process Summary", img_i, "No bacteria roi", Summary_Report_Table);
		return "no_bacteria";
	}
	
	selectWindow("Results");
	Table.rename("Results", Bacteria_Results_Table);
	selectWindow(Bacteria_Results_Table);

	/* Set legit Bacteria idx */
	legit_bacteria_roi_vec = Array.getSequence(bacteria_num);  
	legit_bateria_idx_vec = newArray(1);

	bacteria_area_vec = newArray(bacteria_num); // * Bacteria area vector * //
	roi_n = 0;
	for (roi_i = bacteria_num - 1; roi_i >= 0; roi_i--) // (roi_i = 0; roi_i < bacteria_num; roi_i++)
	{
		bacteria_area = Table.get("Area", roi_i) * size_factor;
		print("roi_i = " + roi_i + ", bacteria_area = " + bacteria_area);
		roiManager("select", roi_i);
		if (bacteria_area <= bactaria_size_lim[1] && bacteria_area >=  bactaria_size_lim[0])
		{			
			roiManager("rename", "b_" + toString(roi_i + 1));
			// Table.set("Area", roi_i, bacteria_area);
			legit_bateria_idx_vec[roi_n] = roi_i;
			bacteria_area_vec[roi_i] = bacteria_area;
			roiManager("Set Color", bacteria_roi_color);
			roiManager("Set Line Width", 3);
			roi_n += 1;
		}
		else 
		{
			roiManager("delete");
			Table.deleteRows(roi_i, roi_i, Bacteria_Results_Table);
			legit_bacteria_roi_vec = Array.deleteIndex(legit_bacteria_roi_vec, roi_i);
			bacteria_area_vec = Array.deleteIndex(bacteria_area_vec, roi_i); 
		}
	}

	roi_num = roiManager("count");	
	
	/* --- Update Summary Table --- */
	legit_bactaria_num = roi_num;
	Table.set("Legit Bacteria Num", img_i,  legit_bactaria_num, Summary_Report_Table);
	
	if (roi_num == 0)
	{ 	
		/* --- Update Summary Table --- */
		Table.set("Process Summary", img_i, "No legit bacteria roi", Summary_Report_Table);
		return "no_legit_bacteria";
	}

	/* Get array of legit bacteria roi */
	legit_bacteria_roi_name_vec = newArray(legit_bactaria_num);
	for (roi_n = 0; roi_n < legit_bactaria_num; roi_n++)
	{
		roiManager("select", roi_n);
		legit_bacteria_roi_name_vec[roi_n] = Roi.getName;
	}
	roiManager("deselect");

	Table.applyMacro("Area = Area*" + toString(size_factor)  , Bacteria_Results_Table);
	column_headings = Table.headings;

			/* Save bacteria ROIs */
	
	bacteria_roi_filename = output_dir + img_name_no_ext + "_Bacteria_Roi.zip";
	roiManager("save", bacteria_roi_filename);
	/******* End of Bacteria ROIs *******/
				  /* --- */

	/* ****** Granule ROIs ****** */
		 /* Segmentation */
		 
	run("ROIs to Label image");
	rename(img_classified_bacteria_labeled);
	selectWindow(img_classified_name);
	run("Duplicate...", "title=" + img_classified_granule);
	selectWindow(img_classified_granule);
		
	setThreshold(granule_segmentation_label, granule_segmentation_label);
	run("Convert to Mask");
	run("Analyze Particles...", "size=" + gran_size_min_pixel + "-Infinity circularity=" + gran_circ_min +"-" + gran_circ_max + " show=[Overlay Masks] display clear summarize add");
	
	raw_granule_roiManager = output_dir + img_name_no_ext + "_Raw_Granule_Roi.zip";
	roiManager("save", raw_granule_roiManager);

	granule_num = roiManager("count");
	
	/* --- Update Summary Table --- */
	raw_granule_num = granule_num;
	Table.set("Raw Granule Num", img_i, raw_granule_num, Summary_Report_Table);
	
	if (granule_num == 0)
	{	
		/* --- Update Summary Table --- */
		Table.set("Process Summary", img_i, "No raw granule roi", Summary_Report_Table);
		return "no_granule";
	}
	
	gran_idx_vec = newArray(granule_num);
	for (gran_i = 0; gran_i< granule_num; gran_i++)
	{
		roiManager("select", gran_i);
		gran_idx = "g_" + toString(gran_i+1);
		roiManager("rename", gran_idx);
		roiManager("Set Color", granule_roi_color);
		roiManager("Set Line Width", 2);
		gran_idx_vec[gran_i] = gran_idx;
		print("gran_i = " + gran_i);
	}
	roiManager("deselect");
	roiManager("save", output_dir + img_name_no_ext + Granule_Initial_roiManager + ".zip");

	/* --- --- Get labeled granule from Colocalization --- --- */
	granule_bacteria_flag = Colocalization();
	
	if (granule_bacteria_flag.matches("no_legit_granule"))
	{
		/* --- Update Summary Table --- */
		Table.set("Process Summary", img_i, "No legit granule roi", Summary_Report_Table);
		return granule_bacteria_flag; // "no_legit_granule";
	}
	
	else 
	{
		/* --- Update Summary Table --- */
		Table.set("Process Summary", img_i, "Legit granule roi", Summary_Report_Table);
		granule_bacteria_flag = "legit_bacteria_granule";
	}

	/* --- Get mean granule per bacteria --- */
	get_Granule_Per_Bacteria_Metrics(bacteria_num);

	return granule_bacteria_flag; // "granule_in_bacteria";
	
}

/* ------------ Get Lgit Files in Directory for Processing -------------*/
function get_File_List()
{	
	img_list = newArray(1);
	filelist = getFileList(input_dir);
	img_n = 0;
	for (file_i = 0; file_i < lengthOf(filelist); file_i++) 
	{
	    if (startsWith(filelist[file_i], filename_prefix) && endsWith(filelist[file_i], ".tif") || endsWith(filelist[file_i], ".tiff")) 
	    { 
	    	img_list[img_n] = filelist[file_i];
	    	img_n += 1;
	        // open(directory + File.separator + filelist[i]);
	    } 
	}
	Array.show(img_list);
	
	return img_list;
	
}


function get_Size_Calibration(width, height, pixelWidth, pixelHeight)
{
	area_normalization = (pixelWidth * pixelHeight)/ (width * height);
	
	return area_normalization;	
}

function Colocalization()
{	
	selectWindow("Bacteria_Results_Table");
	bacteria_num = Table.size;
	graule_bacteria_list = "granule=NA";
	if (bacteria_num > 0)
	{
		selectWindow(img_classified_bacteria_labeled);	
		getPixelSize(unit, pixelWidth, pixelHeight);
		if (unit.matches(toLowerCase("pixels")))
		{
			size_factor = area_normalization;
			length_factor = sqrt(size_factor);
		}
		else 
		{	
			size_factor = 1;
			length_factor = 1;
		}
		
		roiManager("show all without labels");
		Table.reset("Results");
		roiManager("Measure");		
		granule_num = RoiManager.size;
		for (row_i = 0; row_i < granule_num; row_i++)
		{
			Table.set("Granule idx", row_i, gran_idx_vec[row_i]);
		}
		Table.setColumn("Granule idx", gran_idx_vec);
		legit_granule_roi_vec = Array.getSequence(granule_num);  
		for (ii = 0; ii < granule_num; ii ++)
			{legit_granule_roi_vec[ii] += 1;}	
		
		gran_per_full_bacteria_vec  = newArray(bacteria_num);
		
		granule_area_vec = newArray(granule_num); // * Granule area vector * //
		selectWindow("Results");
		bact_n = 0;
		prev_min_val = -1;
		for (roi_i = granule_num - 1; roi_i >= 0; roi_i--) // (roi_i = 0; roi_i < granule_num; roi_i++) 
		{	
				min_val = Table.get("Min", roi_i); // min_val, max_val == bacteria_idx //
				max_val = Table.get("Max", roi_i);
				granule_area = Table.get("Area", roi_i) * size_factor;
				roiManager("select", roi_i);
				if ((min_val == max_val) && (min_val != 0) && (granule_area >= granule_size_lim[0] && granule_area <= granule_size_lim[1])) // * Can add  (roi) area filter for excluding granule based on size * //
				{	
					
					List.set("g_"+toString(roi_i + 1), min_val);
					print("g_"+toString(roi_i + 1) + " = " + toString(min_val));
					gran_per_full_bacteria_vec[min_val - 1] += 1; 
										
					roiManager("select", roi_i);
					roiManager("rename", "g_" + toString(roi_i + 1) + "_b_" + toString(min_val));
					granule_area_vec[roi_i] = granule_area;	
					bact_n + =1;			
				} 
				else
				{
					roiManager("delete");
					Table.deleteRows(roi_i, roi_i);
					Array.deleteIndex(legit_granule_roi_vec, roi_i);
					Array.deleteIndex(granule_area_vec, roi_i);
				}
		}
		
		legit_gran_num = roiManager("count");
		
		/* --- Update Summary Table --- */
		legit_granule_num = legit_gran_num;
		Table.set("Legit Granule Num", img_i,  legit_granule_num, Summary_Report_Table);
		
		if (legit_gran_num == 0)
		{	
			/* --- Update Summary Table --- */
			Table.set("Process Summary", img_i, "No legit granule roi", Summary_Report_Table);
			return "no_legit_granule";
		}
		
		
		/* Update and save Granule results table */
		Table.applyMacro("Area = Area*" + toString(size_factor)  , "Results");
		Table.rename("Results", Granule_Results_Table);
		Table.renameColumn("Mean", "Bacteria_idx", Granule_Results_Table); 
		Table.sort("Bacteria_idx", Granule_Results_Table); 
		Bacteria_idx_new = Table.getColumn("Bacteria_idx");

		/* Save Granule roiManager */
		granule_roi_filename = output_dir + img_name_no_ext + "_Granule_In_Bacteria_Roi.zip";
		roiManager("save", granule_roi_filename);
		
		print("********");
		graule_bacteria_list = List.getList();	
	}
	
	return "legit_granule"; 
	
} // * function Colocalization(legit_bacteria_roi_vec) * //

function get_Granule_Per_Bacteria_Metrics(bacteria_num)
{	
	/*  Calculate the average area of granule per bacteria */	
	selectWindow(Bacteria_Results_Table);
	bacteria_num = Table.size(Bacteria_Results_Table);
	Table.create(Granule_Metrics_table);
	selectWindow(Granule_Results_Table);
	granule_num = Table.size(Granule_Results_Table);
	gran_area_vec = Table.getColumn("Area", Granule_Results_Table);
	
	mean_bact_gran_area_vec = newArray(bacteria_num);
	st = 0;
	print("st = " + st);
	for (bact_i = 0; bact_i < bacteria_num; bact_i++)
	{
		if (gran_per_full_bacteria_vec[bact_i] > 0)
		{	
			cumsum = 0;
			for (gran_i = 0; gran_i < gran_per_full_bacteria_vec[bact_i]; gran_i++)
			{
				cumsum += gran_area_vec[st+gran_i];
			}
			mean_area = cumsum/gran_per_full_bacteria_vec[bact_i];
			st += gran_per_full_bacteria_vec[bact_i]; // + 1
			print("st = " + st + ", " + mean_area);			
		}
		else 
		{
			mean_area = 0;
		}
		mean_bact_gran_area_vec[bact_i] = mean_area;

	}
	bact_idx_vec = Array.getSequence(bacteria_num);
	for (bct_i = 0; bct_i < bact_idx_vec.length; bct_i++)
	{
		bact_idx_vec[bct_i] += 1;
	}
	
	Table.setColumn("Bacteria idx", bact_idx_vec, Granule_Metrics_table);
	Table.setColumn("Mean graule area", mean_bact_gran_area_vec, Granule_Metrics_table);
	legit_bacteria_num = legit_bacteria_roi_vec.length;
	
	bacteria_idx_to_roi = newArray(Bacteria_idx_new.length);
	for (ii = 0; ii < bacteria_idx_to_roi.length; ii++)
	{
		bacteria_idx_to_roi[ii] = legit_bacteria_roi_name_vec[Bacteria_idx_new[ii] - 1];		
	}
	
	if (isOpen(Bacteria_Results_Table))
	{
		Table.setColumn("Bacteria_roi", legit_bacteria_roi_name_vec, Bacteria_Results_Table);
		Table.setColumn("Granule_per_bacteria", gran_per_full_bacteria_vec, Bacteria_Results_Table);
		Table.setColumn("Mean graule area", mean_bact_gran_area_vec, Bacteria_Results_Table);
		
		Table.deleteColumn("StdDev", Bacteria_Results_Table);
		Table.deleteColumn("Mean", Bacteria_Results_Table);
		Table.deleteColumn("Min", Bacteria_Results_Table);
		Table.deleteColumn("Max", Bacteria_Results_Table);
		Table.deleteColumn("Median", Bacteria_Results_Table);
		Table.deleteColumn("%Area", Bacteria_Results_Table);
		Table.deleteColumn("RawIntDen", Bacteria_Results_Table);
	}
	
	if (isOpen(Granule_Results_Table))
	{
		Table.setColumn("bacteria_roi", bacteria_idx_to_roi, Granule_Results_Table);
		Table.deleteColumn("StdDev", Granule_Results_Table);
		Table.deleteColumn("Min", Granule_Results_Table);
		Table.deleteColumn("Max", Granule_Results_Table);
		Table.deleteColumn("Median", Granule_Results_Table);
		Table.deleteColumn("%Area", Granule_Results_Table);
		Table.deleteColumn("RawIntDen", Granule_Results_Table);	
	}

} // * function get_Granule_Per_Bacteria_Metrics(bacteria_num) * //

function save_Results_Tables()
{	
	updated = "";
	if (roi_gen_mode.matches("Updated")) {updated = "_Update";}
	if (isOpen(img_classified_bacteria_labeled) == 1)
	{
		selectWindow(img_classified_bacteria_labeled);
		saveAs("tiff", output_dir + img_name_no_ext + "_" + img_classified_bacteria_labeled + ".tiff");
	}
	if (isOpen(img_masked_classified_bacteria) == 1)
	{
		selectWindow(img_masked_classified_bacteria);
		saveAs("tiff", output_dir + img_name_no_ext + "_" + img_masked_classified_bacteria + ".tiff");
	}
	if (isOpen(Bacteria_Results_Table) == 1)
	{
		selectWindow(Bacteria_Results_Table);
		saveAs("results", output_dir + img_name_no_ext + "_" + Bacteria_Results_Table +".txt");
	}
	
	if (isOpen(Granule_Results_Table) == 1)
	{	
		selectWindow(Granule_Results_Table);
		saveAs("results", output_dir + img_name_no_ext + "_" + Granule_Results_Table + updated + ".txt");
	}
	if (isOpen(Granule_Metrics_table) == 1)
	{
		selectWindow(Granule_Metrics_table);
		saveAs("results", output_dir + img_name_no_ext + "_" + Mean_Bact_Gran_Area_Table + updated + ".txt");
	}
} // * function save_Results_Tables() * //

function overlay_Rois_On_Image(img_name_ext)
{
	selectWindow(img_name_ext);
	roiManager("deselect");
	roiManager("Open", bacteria_roi_filename);
	roiManager("Show None");
	roiManager("Show All");
	run("Flatten");
	overlayed_roi_img = output_dir + overlayed_roi_raw_img;
	saveAs("tiff", overlayed_roi_img);
	overlayed_roiManager = output_dir + overlayed_roi_raw_img + "_roiManager_.zip";
	roiManager("save", overlayed_roiManager);
}

function in_vec(vec, val)
{
	value_in_vec = false;
	for (idx = 0; idx <= vec.length; idx++)
	{
		if (val == vec[idx]) 
		{
			value_in_vec = true; 
			break;
		}		
	}
	
	return value_in_vec;
} // * function in_vec(vec, val) * //

function Diff(vec, gap)
{
	diff_vec = newArray(vec.length - 1);
	if (gap >= 1)
	{
		vec_1 = Array.slice(vec,0,vec.length - gap);
		vec_2 = Array.slice(vec,1);
		for (ii = 0; ii < vec.length - gap - 1; ii++)
		{
			diff_vec[ii] = vec_2[ii] - vec_1[ii];
		}
	}	
	
	return diff_vec;
}

function get_Bar(p1, p2) {
        n = 20;
        bar1 = "--------------------";
        bar2 = "********************";
        n = bar1.length;
        index = round(n*(p1/p2));
        if (index<1) index = 1;
        if (index>n-1) index = n-1;
        return substring(bar2, 0, index) + substring(bar1, index+1, n);
  }	


