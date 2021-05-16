	
/************************************************************************************
 
	 __   __                             \    
	 |    |    ___    ___.   ___    ___  |   ,
	 |\  /|   /   ` .'   ` .'   ` .'   ` |  / 
	 | \/ |  |    | |    | |----' |----' |-<  
	 /    /  `.__/|  `---| `.___, `.___, /  \_
	                 \___/                    

                          a Bérenger DALLE-CORT and Marcela GARITA H. Fiji MACRO.

	This macro takes *.CZI files and convert them into separate RGB color
	channels and save them as *.TIFF (RGB)

***********************************************************************************/


/**
 * Here we define some constants
 */
SCRIPT_TITLE            = "MAGEEK";
ENABLE_PAUSE            = true;        // set to false to disable all pause() calls.
ANALYSED_SUBFOLDER_NAME = "ANALYSED";  // will be created if not exists.
FILE_EXTENSION          = ".czi";      // the script will only consider this extension.

/**
 * 1 - Create a startup dialog to explain to the user the following steps.
 */

{
	Dialog.create(SCRIPT_TITLE);
	
	Dialog.addMessage("");
	Dialog.addMessage(SCRIPT_TITLE);
	Dialog.addMessage("");
	
	Dialog.addMessage("This macro will help you to process a lot of CZI files located in a specific folder");
	Dialog.addMessage("");
	Dialog.addMessage("The script need you to set a source directory in order to locate your files.");
	Dialog.addMessage("");
	Dialog.addMessage("All files in this folder and its subfolders will be processed like that:");
	Dialog.addMessage(" - Split channels");
	Dialog.addMessage(" - Colorize each channel: Red, Green, Blue, Magenta (could change)");
	Dialog.addMessage(" - ZProjection (if needed)");
	Dialog.addMessage(" - Save each channel in a separate *.TIFF file as an RGB image.");
	Dialog.addMessage("");
	Dialog.addMessage("The macro will generate the output images into an \"" + ANALYSED_SUBFOLDER_NAME + "\" subfolder.");
	Dialog.addMessage("");
	Dialog.addMessage("\nPress OK when you're ready.");
	Dialog.show();
}

/** 
 * 2 - Get the file list
 */
print("\\Clear");
sourceDirectory      = getDirectory("Choose a directory");
destinationDirectory = sourceDirectory + ANALYSED_SUBFOLDER_NAME;

if ( File.exists(destinationDirectory) == false ){
	File.makeDirectory(destinationDirectory);
	
} else {
	// Here we ask the user if he wants to overwrite existing output directory:
	Dialog.create("output folder already exists !");
	Dialog.addMessage("The output folder " + destinationDirectory + " already exists.");
	Dialog.addMessage("");
	Dialog.addMessage("Do you want to continue and overwrite them ?");
	Dialog.show();
}

// Get recursively all the files (in subfolders too)
print("Scanning folder " + sourceDirectory + " (and subfolders)...");
allFiles = getFileListRecursively(sourceDirectory);
print(allFiles.length + " file(s) found.\n");

// Filter the files (keep only *.czi)
print("Filter " + FILE_EXTENSION + " files...");
filteredFiles = newArray(0);
ignoredFiles = newArray(0);
for (fileIndex = 0; fileIndex < allFiles.length; fileIndex++) {
	
	eachFilePath = allFiles[fileIndex];

	// cehck extension and ignore files already in an analysed folder
	if ( endsWith(eachFilePath, FILE_EXTENSION) && !matches(eachFilePath, "/ "+ ANALYSED_SUBFOLDER_NAME + "/") ){	     	
		filteredFiles = Array.concat(filteredFiles, eachFilePath);
	} else {
		ignoredFiles = Array.concat(ignoredFiles, eachFilePath);
	}
}

print("Filter details:\n");
print("*** These files will be ignored by " + SCRIPT_TITLE + ": ");
for (i = 0; i < ignoredFiles.length; i++) {		
	print("\t" + ignoredFiles[i] + " (not a " + FILE_EXTENSION + " file)");
}	

print("");
print("*** These files will be processed by " + SCRIPT_TITLE + ": ");
for (i = 0; i < filteredFiles.length; i++) {		
	print("\t(" + (i+1) + ") " + filteredFiles[i]);
}	
	
/** 
 * 3 - Ask the Z Project mode and also if we run the macro in batch (in background) or not
 *    (really usefull to check if script works great before to run it in batch)
 */

// Create a dialog window to select the stack Z projection with an option to run in background (batch processing)
Dialog.createNonBlocking("Processing settings");
Dialog.addMessage("We've found " + filteredFiles.length + " file(s) in " + sourceDirectory);
Dialog.addMessage(" (a detailed list is available in the Log window)");
Dialog.addMessage("");
Dialog.addMessage("Please check the settings bellow before to launch the process");
Dialog.addMessage("");
Zchoice = newArray(
	"Max_Intensity",
	"Average_Intensity",
	"Sum_Slices",
	"Min_Intensity",
	"Standard_Deviation",
	"Median",
	"none");
Dialog.addChoice("Z Project", Zchoice);

availableColors = newArray( "Blue", "Green", "Red", "Magenta" );
Dialog.addChoice("Channel 1", availableColors, availableColors[0] );
Dialog.addChoice("Channel 2", availableColors, availableColors[1] );
Dialog.addChoice("Channel 3", availableColors, availableColors[2] );
Dialog.addChoice("Channel 4", availableColors, availableColors[3] );

Dialog.addCheckbox("batch (process in background)", true);
Dialog.addMessage("");
Dialog.addMessage("Process the images " + filteredFiles.length + " files?");
Dialog.show();

// Apply the choices
zProjUserChoice  = Dialog.getChoice();
colorsUserChoice = newArray(
	Dialog.getChoice(),
	Dialog.getChoice(),
	Dialog.getChoice(),
	Dialog.getChoice()
);
batchModeUserChoice       = Dialog.getCheckbox();
setBatchMode(batchModeUserChoice);

/**
 * 4 - Iterate on each files from list (source directoy)
 */
print("\nStart processing files..."); 
imageProcessedCount = 0;
for (fileIndex = 0; fileIndex < filteredFiles.length; fileIndex++)
{
	eachFilePath = filteredFiles[fileIndex];
	imageProcessedCount++;

	// Open the file
	run("Bio-Formats Importer", "open='" + eachFilePath + "' autoscale=false view=Hyperstack");
	name = File.nameWithoutExtension;	
	getDimensions(width, height, channels, slices, frames);	
	Colorize(eachFilePath, colorsUserChoice );
	
	print("    DONE ! ");
	
}

/**
 * Displays a end message and wait the user to press OK.
 */
title = "End of process";
msg   = 

Dialog.create("End of process");
Dialog.addMessage("Image processing done !");
Dialog.addMessage("");
Dialog.addMessage("Quick resume:");
Dialog.addMessage(" - Files found : " + allFiles.length);
Dialog.addMessage(" - Files processed : " + imageProcessedCount + "/" + allFiles.length);
Dialog.addMessage(" - Files ignored : " + ignoredFiles.length+ "/" + allFiles.length);
Dialog.addMessage("");
Dialog.addMessage("Hasta La Vista Baby. ^^");
Dialog.show();

/**
 * Unified function to colorize an image with N channels, with N in [1,4].
 * 
 * _colorForChannel should be an Array containing N color names that could be used like that: run(_colorForChannel[i]);
 * 
 * for example, if _colorForChannel = ["Magenta", "Blue"] it will work because run("Magenta") and run("Blue") exists in Fiji.
 * 
 */
function Colorize(eachFilePath, _colorForChannel)
{	
	// Print some information in logs
	print("Colorize... ", eachFilePath);
	print("     [", channels, " channel(s), ", slices, " slice(s), ", frames, " frame(s) ]");	
	
	count = channels;	
	// in some cases we could have more channels than colors, so we skip the channels without color
	if ( count  > _colorForChannel.length ) {
		count = _colorForChannel.length;
	}

	// Stack.setDisplayMode("color");

	// Colorize each channels using specified color (_colorForChannel is an Array of strings)
	for( i=0; i < count; i++) {
		Stack.setChannel(i+1);
		colorScriptName = _colorForChannel[i];
		print("Colorizing channel ", i+1, " as ", colorScriptName, "...");
		run(colorScriptName);
	}

	if( frames > 1 || slices > 1) { 
		RunZProject();
		selectImage(1);
		close();
	}
	
	run("Split Channels");	
	
	// Rename the splitted images
	for( i=0; i < count; i++) {
		selectImage(i+1);
		rename(_colorForChannel[i]);
	}

	/** Merge channel is disabled for now...
	options = "";
	for( i=0; i < count; i++) {
		options = options + "c"+(i+1)+"=" + _colorForChannel[i] + " ";
	}
	run("Merge Channels...", options + "keep");
	*/
	
	// Save each image
	outputFileName = destinationDirectory + File.separator + name;
	for( i=0; i < count; i++) {
		selectWindow(_colorForChannel[i]);
		run("RGB Color");
		saveAs("Tiff", outputFileName + "_" + _colorForChannel[i] + ".tif");
	}

	// Create a Montage with N images
	run("Images to Stack", "name=name title=[] use keep");
	run("Make Montage...", "columns=" + count + " rows=1 scale=0.5 first=1 last="+ count +" increment=1 border=1 font=12");
	saveAs("Tiff", outputFileName + "_Montage.tif");

	// Close opened images
	while (nImages() > 0 ){ 		
		selectImage(nImages); 
		close(); 
	}
}

function RunZProject(){
	
	if (zProjUserChoice == "Sum_Slices"){
		run("Z Project...", "projection=[Sum Slices]");
		
	} else if (zProjUserChoice == "Average_Intensity"){
		run("Z Project...", "projection=[Average Intensity]");
		
	} else if (zProjUserChoice == "Max_Intensity"){
		run("Z Project...", "projection=[Max Intensity]");
		
	} else if (zProjUserChoice == "Min_Intensity"){
		run("Z Project...", "projection=[Min Intensity]");
		
	} else if (zProjUserChoice == "Standard_Deviation"){
		run("Z Project...", "projection=[Standard Deviation]");
		
	} else if (zProjUserChoice == "Median"){
		run("Z Project...", "projection=Median");
		
	} else if (zProjUserChoice=="none"){
		
	}
}


function getFileListRecursively(dir) {	
	files = listFiles(dir);
	return files;
}


/*
 * Recursive function that return the list of all the files located somewhere.
 * The result is an Array containing the absolute path of all files.
 */
function listFiles(dir) {
	
	 files = newArray(0);
     list  = getFileList(dir);
     
     for (i=0; i < list.length; i++) {

		absolutePath = dir + list[i];                 // compute the absolute path
     	
        if (endsWith(list[i], "/")) {                 // if it is a directory.
           	subdirFiles = listFiles(absolutePath);    // get its files (recursive call).
           	files = Array.concat(files, subdirFiles); // add them to the file list.

        } else {                                      // (else) if it is a file.
        	files = Array.concat(files, absolutePath);// we add it to the file list.
        }
     }
     
     return files;
  }

function pause(message) {

	if( !ENABLE_PAUSE || batchModeUserChoice) // pause are always disabled in batch mode.
		return;
	
	Dialog.createNonBlocking("Pause");
	Dialog.addMessage(message);
	Dialog.addMessage("\nWould you like to continue the macro ?");
	Dialog.addMessage("Note: to disable these dialogs run in batch mode or set ENABLE_PAUSE = false in script.");
	Dialog.show();
}


