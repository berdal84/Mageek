	
/************************************************************************************
 
	 __   __                             \    
	 |    |    ___    ___.   ___    ___  |   ,
	 |\  /|   /   ` .'   ` .'   ` .'   ` |  / 
	 | \/ |  |    | |    | |----' |----' |-<  
	 /    /  `.__/|  `---| `.___, `.___, /  \_
	                 \___/                    

                          a Bérenger DALLE-CORT and Marcela GARITA H. Fiji MACRO.

	This macro takes any Fiji compatible file and convert them into separate color
	channels and save them as RBG *.TIFF.

	Mageek handle multiple series (unlimited), slices (unlimited) and channels(up to 4) files.

***********************************************************************************/


/**
 * Here we define some constants
 */
SCRIPT_TITLE            = "MAGEEK";
SCRIPT_VERSION          = "0.3.0";
SCRIPT_SHORT_DESCRIPTION= SCRIPT_TITLE + " is an ImageJ Macro to combine channels from different slices and to colorize them.\nIt works with multiple images/series/channels/slices.";
ENABLE_PAUSE            = true;        // set to false to disable all pause() calls.
ANALYSED_SUBFOLDER_NAME = "ANALYSED";  // will be created if not exists.
EXT_FOUND_NAME_PREFIX   = "EXT_FOUND_";
ENABLE_TUTORIAL_BY_DEFAULT = false;
ANY_EXTENSION           = "*";
Z_PROJECT_NONE          = "None";
Z_PROJECT_MODES         = newArray( "Max Intensity", "Average Intensity", "Sum Slices", "Min Intensity"
                                    , "Standard Deviation", "Median", Z_PROJECT_NONE);
PRETTY_SEPARATOR        = " - ";

/*
 * File extension presets
 */
List.clear();
List.set( "Recommended", "czi, lif, nd2" );     
List.set( "_Legacy", ".czi" );
List.set( "_Any", ANY_EXTENSION );
List.set( "_Custom", "" );
// List.set( "NewPreset", "" ); <-- Feel free to add any extension you want.
EXT_PRESETS = List.getList();

/*
 * Color presets
 *
 * they will be sorted alphabetically.
 * 
 * Q: How to add a new one ?
 * A: Copy an existing preset and replace the name and the colors (they must be separated by a space).
 */
List.clear();
List.set( "Confocal", "Magenta, Red, Green, Blue" );
List.set( "Legacy",   "Blue, Green, Red, Magenta" );
// List.set( "my preset", "Red Magenta Green Blue" ); <-- Feel free to add any preset you want,
COLOR_PRESETS = List.getList();

/* Colors */
PRESET_COLOR_FALLBACK = "..."; // this will identify that user want's to use the color preset, this will be replaced.
                               // Though the text will be visible in drop down list.
COLORS = newArray( PRESET_COLOR_FALLBACK, "Blue", "Green", "Red", "Magenta" ); // Colors available through the color drop down list.

/**
 * 0 - Prepare environment vars
 * ============================
 */

g_scannedFiles = newArray(0);
g_filteredFiles = newArray(0);
g_ignoredFiles = newArray(0);
g_processedFilesCount = 0;

/**
 * 1 - Create a startup dialog to explain to the user the following steps.
 * =======================================================================
 */
openStartupDialog(ENABLE_TUTORIAL_BY_DEFAULT);
isTutorialEnable = Dialog.getCheckbox();
if ( isTutorialEnable ) {
	openHelpDialog();
}

/** 
 * 2 - Get the file list
 * =====================
 */
print("\\Clear");
sourceDirectory = getDirectory("Choose a directory");
destinationDirectory = sourceDirectory + ANALYSED_SUBFOLDER_NAME;

if ( File.exists(destinationDirectory) == false ) {
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
print( "Scanning for files ...");
g_scannedFiles = getFileListRecursively(sourceDirectory, ANALYSED_SUBFOLDER_NAME);
allFileExtensions = getFileExtensions(g_scannedFiles, true);
print( "Scan DONE");
print( "Scan result:");
print( " - " + g_scannedFiles.length + " file(s)");
print( " - " + allFileExtensions.length + " extension(s)");
Array.print(g_scannedFiles);
Array.print(allFileExtensions);

/** 
 * 3 - Configure and launch the process
 * ====================================
 */  
Dialog.createNonBlocking("Process settings");
Dialog.addMessage("Mageek found " + g_scannedFiles.length + " file(s) with " + allFileExtensions.length + " extension(s) in " + sourceDirectory);
Dialog.addMessage(" (a detailed list is available in the Log window)");
Dialog.addMessage("");
Dialog.addMessage("Please check the settings bellow before to launch the process");
Dialog.addMessage("");

/*
 * 3.1 - Ask which type of file to process (using presets) 
 */
prettyExtPresets = makePrettyArray( EXT_PRESETS );
Dialog.addChoice("Extensions", prettyExtPresets );
Dialog.addMessage("");

/*
 * 3.2 - Ask the Z Project mode and also if we run the macro in batch (in background) or not
 *    (really usefull to check if script works great before to run it in batch)
 */
Dialog.addChoice("Z Project", Z_PROJECT_MODES);
Dialog.addMessage("");

prettyColorPresets = makePrettyArray( COLOR_PRESETS );
Dialog.addChoice("Color preset", prettyColorPresets, prettyColorPresets[0] );

Dialog.addMessage("Overrides:");
Dialog.addChoice("  Channel 1", COLORS, PRESET_COLOR_FALLBACK );
Dialog.addChoice("  Channel 2", COLORS, PRESET_COLOR_FALLBACK );
Dialog.addChoice("  Channel 3", COLORS, PRESET_COLOR_FALLBACK );
Dialog.addChoice("  Channel 4", COLORS, PRESET_COLOR_FALLBACK );
Dialog.addMessage("");
Dialog.addCheckbox("batch (process in background)", true);
Dialog.addMessage("");
Dialog.addMessage("Process the images files?");
Dialog.show();

// Apply the choices
extensionPresetChoice = Dialog.getChoice();
zProjUserChoice  = Dialog.getChoice();
colorPresetUserChoice = Dialog.getChoice();
colorsUserChoice = newArray(
	Dialog.getChoice(),
	Dialog.getChoice(),
	Dialog.getChoice(),
	Dialog.getChoice()
);

// Filter files depending on Extension Preset
selectedExtensionPreset = getPresetArray(extensionPresetChoice, EXT_PRESETS);
g_filteredFiles = filterFilesByExtension( g_scannedFiles, selectedExtensionPreset );

// apply the preset colors for each color except if user set something different
selectedColorPreset = getPresetArray(colorPresetUserChoice, COLOR_PRESETS);
for (colorIndex = 0; colorIndex < colorsUserChoice.length; colorIndex++)
{
	if ( colorsUserChoice[colorIndex] == PRESET_COLOR_FALLBACK )
	{
		colorsUserChoice[colorIndex] = selectedColorPreset[colorIndex];
	}
}
print( "Before user overrides, the selected preset colors are:");
Array.print( selectedColorPreset );
print( "After user overrides:");
Array.print( colorsUserChoice );
print("The filtered extensions are:");
Array.print( selectedExtensionPreset );
// batch mode on/off
batchModeUserChoice = Dialog.getCheckbox();
setBatchMode(batchModeUserChoice);

// Check if at least one file has been filtered
if ( g_filteredFiles.length == 0) {
	message = "Sorry, no files to process... \n";
	message += "Are you certain " + sourceDirectory + " contains files matching with the selected filter? \n";
	message += "Your choice was: \""+ extensionPresetChoice + "\"\n";
	message += SCRIPT_TITLE + " only found " + arraytoString(allFileExtensions, ", ") + ".";
	displayStats(message);
	exit();
}

/**
 * 4 - Iterate on each files from list (source directoy)
 */
print("\nStart processing files..."); 
g_processedFilesCount = 0;
for (fileIndex = 0; fileIndex < g_filteredFiles.length; fileIndex++)
{
	eachFilePath = g_filteredFiles[fileIndex];
	g_processedFilesCount++;

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
displayStats("Process complete!");

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
	
	channelToProcessCount = channels;	
	// in some cases we could have more channels than colors, so we skip the channels without color
	if ( channelToProcessCount  > _colorForChannel.length ) {
		channelToProcessCount = _colorForChannel.length;
	}

	// Stack.setDisplayMode("color");

	// Colorize each channels using specified color (_colorForChannel is an Array of strings)

	for( i=0; i < channelToProcessCount; i++) {
		if( channelToProcessCount > 1 ) { 
			Stack.setChannel(i+1);
		}
		colorScriptName = _colorForChannel[i];
		print("Colorizing channel ", i+1, " as ", colorScriptName, "...");
		run(colorScriptName);
	}

	if( frames > 1 || slices > 1) { 
		if (zProjUserChoice != Z_PROJECT_NONE ){
			run("Z Project...", "projection=["+ zProjUserChoice +"]");	
		}
		selectImage(1);
		close();
	}
	
	// Split channels if needed
	if ( channelToProcessCount > 1 ) {
		run("Split Channels");
	}	
	
	// Rename the channel(s) image(s)
	for( i=0; i < channelToProcessCount; i++) {
		selectImage(i+1);
		rename(_colorForChannel[i]);
	}

	/** Merge channel is disabled for now...
	options = "";
	for( i=0; i < channelToProcessCount; i++) {
		options = options + "c"+(i+1)+"=" + _colorForChannel[i] + " ";
	}
	run("Merge Channels...", options + "keep");
	*/
	
	// Save each image
	outputFileName = destinationDirectory + File.separator + name;
	for( i=0; i < channelToProcessCount; i++) {
		selectWindow(_colorForChannel[i]);
		run("RGB Color");
		saveAs("Tiff", outputFileName + "_" + _colorForChannel[i] + ".tif");
	}

	// Create a Montage with colored channels (only if we have more than one channel)
	if ( channelToProcessCount > 1 ) {
		run("Images to Stack", "name=name title=[] use keep");
		run("Make Montage...", "columns=" + channelToProcessCount + " rows=1 scale=0.5 first=1 last="+ channelToProcessCount +" increment=1 border=1 font=12");
		saveAs("Tiff", outputFileName + "_Montage.tif");
	}

	// Close opened images
	while (nImages() > 0 ){ 		
		selectImage(nImages); 
		close(); 
	}
}

function getFileListRecursively(dir, _ignoreFolderName) {	
	files = listFiles(dir, _ignoreFolderName);
	return files;
}


/*
 * Recursive function that return the list of all the files located somewhere.
 * The result is an Array containing the absolute path of all files.
 */
function listFiles(dir, _ignoreFolderName) {

	if ( File.getName(dir) == _ignoreFolderName){
		return newArray(0);
	}

	print("Scanning folder " + dir + " (and subfolders recursively) ...");

	 files = newArray(0);
     fileList  = getFileList(dir);
     
     for (i=0; i < fileList.length; i++) {
		absolutePath = dir + fileList[i];                 // compute the absolute path
		
		if ( File.isDirectory(absolutePath) ) {                 // if it is a directory.
			subdirFiles = listFiles(absolutePath , _ignoreFolderName);    // get its files (recursive call).
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

/**
 * Get all unique extensions from a file path array
 * @param _files 
 * @param _ignoreNoExt if set true, no extension files will be ignored
 * @returns an array of extensions like [ "*.ext", "*.tiff", ... ]
 */
function getFileExtensions(_files, _ignoreNoExt) {

	// Filter the files (keep only *.czi)
	print("Getting file extensions ...");

	if(_ignoreNoExt)
		print(" ignoring no extension: ON");

	_result = newArray(0);

	for (fileIndex = 0; fileIndex < _files.length; fileIndex++) {	

		_ext = getExtension(_files[fileIndex]);

		if ( _ext != "" || !_ignoreNoExt ) {

			_key = EXT_FOUND_NAME_PREFIX + _ext;				
			if ( List.get(_key) == "" ){
				_newVal = 1;
				_result = Array.concat(_result, _ext); 
				print(" - found: " + _ext);
			} else {
				_newVal = List.getValue(_key) + 1;
				// print(" - found: " + _ext + " (" + _newVal + " occurences)");				
			}
			List.set( _key, _newVal );	
		}
	}
	print("Getting file extensions DONE");
	return _result;	
}

/**
 * Get file extension.
 * @param path a directory or file path
 * @returns the extension as *.<ext> or an empty string if no extension.
 */
function getExtension(path){

	print("getting extension for " + path );

	result = "";
	if ( File.isDirectory(path))
		exit("Mageek's getExtension(path) shall not be called using a directory path, check before use.");

	arr = split(File.getName(path),  ".");
	if ( arr.length == 1){
		result = "";
	} else {
		result = arr[1];
	}

	print(" -> result: " + result );


	return result;
}

function openStartupDialog(_tutorial){
	Dialog.create(SCRIPT_TITLE + " - version " + SCRIPT_VERSION );	
	Dialog.addMessage("");
	Dialog.addMessage("Welcome to " + SCRIPT_TITLE + " !");
	Dialog.addMessage("\n" + SCRIPT_SHORT_DESCRIPTION);
	Dialog.addMessage("\nIf you are beginner, we suggest you to enable the tutorial:");
	Dialog.addCheckbox("Enable Tutorial", _tutorial);
	Dialog.addMessage("\n\t\t\t\tPress OK when you're ready.");
	Dialog.show();
}

function openHelpDialog(){

	Dialog.create(SCRIPT_TITLE + "'s Help");

	Dialog.addMessage(SCRIPT_TITLE + " will help you to process a lot of files located in a specific folder.");
	Dialog.addMessage("To do so you have to pick a source directory.");
	Dialog.addMessage("Note that by default " + SCRIPT_TITLE + " will navigate recursively from that folder.");
	Dialog.addMessage("It means all files in this folder and its subfolders and so on will be scanned. You can uncheck that option.");
	Dialog.addMessage("");

	Dialog.addMessage("Once " + SCRIPT_TITLE + " has found files and get their extensions, you will be able to filter them.");
	Dialog.addMessage("After the filter is applied, you will be able to configure the color preset to apply");
	Dialog.addMessage("");

	Dialog.addMessage("More details about the algorithm of " + SCRIPT_TITLE +":");
	Dialog.addMessage("The files will be processed like that:")
	Dialog.addMessage(" - For each file:");
	Dialog.addMessage("  - For each serie in the file:");
	Dialog.addMessage("   - For each channel in the serie:");
	Dialog.addMessage("    - Colorize in: Red, Green, Blue or Magenta (depends on user preset)");
	Dialog.addMessage("    - Apply a ZProjection (if needed)");
	Dialog.addMessage("    - Save channel in a *.TIFF file as an RGB image.");
	Dialog.addMessage("");
	Dialog.addMessage("The " + SCRIPT_TITLE + " will generate an output folder to store its result into a \"" + ANALYSED_SUBFOLDER_NAME + "\" subfolder.");
	Dialog.addMessage("In case that folder exists, " + SCRIPT_TITLE + " will ask you if you want to delete it or to abort");
	Dialog.addMessage("");
	Dialog.addMessage("Hope you understand a bit more, let's click on OK to continue.");
	Dialog.addMessage("");
	Dialog.show();
}

function cleanExtension( _ext ){
	_ext = replace(_ext," ", "");
	return _ext;
}

function filterFilesByExtension( _files, _extensions){
	g_ignoredFiles = newArray(0);
	print("Filtering files using the extension bellow ...");
	Array.print(_extensions);
	print("");

	_result = newArray(0);
	for (fileIndex = 0; fileIndex < _files.length; fileIndex++) {
		_file = _files[fileIndex];
		_ext = getExtension(_file);
		_keep_file = false;
		
		print("File extension is \"" + _ext + "\"");
		for (extIndex = 0; (extIndex < _extensions.length); extIndex++) {
			eachAllowedExt = cleanExtension(_extensions[extIndex]);
			print("Confronting with allowed \"" + eachAllowedExt + "\"");

			if ( _ext == eachAllowedExt || eachAllowedExt == ANY_EXTENSION ) {
				_keep_file = true;
				print(" match.");
			}else{
				print(" do NOT match.");
			}			
		}
		if ( _keep_file ){
			_result = Array.concat(_result, _file);
		}else{
			g_ignoredFiles = Array.concat(g_ignoredFiles, _file);
			print("Discarding file " + _file + ", because extension "+_ext+" is not allowed.");		
		}
	}
	print("Filtering files DONE");
	return _result;
}

function makePrettyArray( list ) {
	result = split(list, "\n");
	for(i=0; i<result.length; i++){
		result[i] = replace(result[i], "=", PRETTY_SEPARATOR + "(" ) + ")";
	}
	return result;
}

function getPresetArray(prettyItem, list) {	
	splitted = split(prettyItem, PRETTY_SEPARATOR);
	key = replace(splitted[0], " ", "");
	List.setList(list);
	presetString = List.get(key);
	return split(presetString, ",");
}

function displayStats( message ){
	Dialog.create("End of process");
	Dialog.addMessage(message);
	Dialog.addMessage("");
	Dialog.addMessage("Quick resume:");
	Dialog.addMessage(" - scanned : "   + g_scannedFiles.length);
	Dialog.addMessage(" - ignored : "   + g_ignoredFiles.length   + "/" + g_scannedFiles.length);
	Dialog.addMessage(" - filtered : "  + g_filteredFiles.length  + "/" + g_scannedFiles.length);
	Dialog.addMessage(" - processed : " + g_processedFilesCount   + "/" + g_filteredFiles.length);
	Dialog.addMessage("");
	Dialog.addMessage("Hasta La Vista Baby. ^^");
	Dialog.show();
}

function arraytoString( arr , separator) {
	result = "";
	for(i = 0; i<arr.length; i++){
		if ( i != 0 ){
			result += separator;
		}
		result += arr[i];		
	}
	return result;
}
