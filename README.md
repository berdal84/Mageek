# Mageek

Mageek is a script to process *.czi files in Fiji.

Mageek drives Fiji to project image slices and to colorize image channels for one or several file(s) (process folders recursively). We are using presets to facilitate the configuration.

Here is the result of processing a single *.czi file and putting the 4 channels in a row:

![image](https://user-images.githubusercontent.com/942052/118412778-31b48680-b69c-11eb-9c92-3dac930e49ba.png)


# How to use ?

- Download `Mageek.ijm` last release from [here](https://github.com/berdal84/Mageek/releases).

- Download and install Fiji from https://imagej.net/Fiji/Downloads

- Run Fiji

- On the main menu, click on `Plugins -> Macros -> Run` and select the downloaded `Mageek.ijm` file.

![image](https://user-images.githubusercontent.com/942052/118412408-0af55080-b69a-11eb-98b2-0ca301b8bbe6.png)

# How to add a new color preset ?

Open `Mageek.ijm` and look at the color presets part at the begining of the files (~line 30)

```javascript
/*
 * Color presets
 *
 * they will be sorted alphabetically.
 * 
 * Q: How to add a new one ?
 * A: Copy an existing preset and replace the name and the colors (they must be separated by a space).
 */
List.set( "Confocal (Magenta Red Green Blue)", "Magenta Red Green Blue" );
List.set( "Legacy   (Blue Green Red Magenta)", "Blue Green Red Magenta" );
// List.set( "<preset name>", "<color1> <color2> <color3> <color4>" );
```

Simply copy one of the preset and adapt name and colors (colors must be separated with spaces):

```javascript
List.set( "Confocal (Magenta Red Green Blue)", "Magenta Red Green Blue" );
List.set( "Legacy   (Blue Green Red Magenta)", "Blue Green Red Magenta" );
List.set( "My preset example", "Red Magenta Green Blue" );
```
