# Aseprite SGB Attribute Export
 Save SGB Attributes from Aseprite
What is a Super Game Boy Attribute?
SGB attributes are rectangular regions on the screen of Super Game Boy games that apply a different color palette inside,
outside and/or around said region. There are 4 palettes with 3 unique colors each, and all of them must share the same 
background color. This is how games like Donkey Kong and Pokemon were able to have so many different colors displayed on 
the screen despite being black and white DMG Game Boy games. 

How to use:
Start by putting the Lua script into your scripts folder in Aseprite. 
The script uses Aseprite's "slice" feature to make the SGB attributes. So you first have to make sure that you:
1. Have slices created for your intended SGB attributes
2. Make sure your palette abides by SGB restrictions. The script will warn you if it doesn't though.

When you run the script, you'll be prompted to select a palette of four colors for each slice. When all of the slices
have had their palettes selected, a .inc file (or maybe more than one depending on which attributes your made) will be
generated. This is raw data that can be fed right into the SGB. 

NOTES:
For now this only supports the LIN and BLK attribute types. Perhaps in the future I will add CHR and DIV support as well. 
The BLK feature is also not fully robust, as it only allows for creating BLK attributes with color changes being applied
within the boundaries of your rectangle. This may also be updated later. 
