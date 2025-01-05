----------------------------------------
--Aseprite file and globals
----------------------------------------
--Sprite constants
local sprite = app.activeSprite
local spriteFullPath
local spriteFileName
--Grab the title of our aseprite file
if sprite then
    spriteFullPath = sprite.filename
    spriteFilePath = spriteFullPath:match("(.+)%..+$")
    spriteFileName = spriteFullPath:match("([^/\\]+)$"):match("(.+)%..+$")
end

-- Check constraints
if sprite == nil then
	app.alert("No Sprite...")
	return
end

if sprite.bounds.width ~= 160 or sprite.bounds.height ~= 144 then
	app.alert("Attributes can only be made on a sprite that's 160x144 pixels!")
	return
end

--Palette Constants
local currentPal = Palette(sprite.palettes[1])
local currentPalNumColors = #sprite.palettes[1]
local sharedColor = currentPal:getColor(0)

--Palettes
local paletteSGB0 = Palette(4)
local paletteSGB1 = Palette(4)
local paletteSGB2 = Palette(4)
local paletteSGB3 = Palette(4)

--Number of ATRs that we have identified so far
local numBLK = 0
local numLIN = 0
local numCHR = 0
local numDIV = 0
local totalNumATR = 0
local bytesWritten = 0

--Arrays for each type of ATR that we have and for its corresponding palette
local arrayBLK = {}
local palBLK = {}
local arrayLIN = {}
local palLIN = {}
local arrayCHR = {}
local palCHR = {}
local arrayDIV = {}
local palDIV = {}

--ATR files to write to
local fileBLK
local fileLIN
local fileCHR
local fileDIV

--ATR type oes
local codeBLK = 4 * 8 --Plus number of data sets
local codeLIN = 5 * 8 --Plus number of data sets
local codeDIV = 6 * 8 --Plus number of data sets
local codeCHR = 7 * 8 --Plus number of data sets

--ATR sizes in bytes per data set
local sizeBLK = 6
local sizeLIN = 1
local sieDIV = 16
local sizeCHR = 2/8

--Other const
local packetSize = 16

----------------------------------------
--SGB Block Attributes
----------------------------------------

--Slices to be turned into SGB Attributes
local slices = sprite.slices

--Check if we have slices to work with
if slices == nil then
	app.alert("Please save desired SGB Blocks as Aseprite slices!")
	return
end

--More colors than allowed by the Super Game Boy
if currentPalNumColors > 16 then
	local dlg = Dialog{title = "SGB color limit exceeded!"}
	dlg:label{ 	id    = "manyColors",
				label = "Warning!",
				text  = "Only the first 16 indexed colors will be available!" }
	dlg:button{ id="continue", text="Continue" }
	dlg:button{ id="cancel", text="Cancel" }
	dlg:show()
	local data = dlg.data
	if data.cancel then
		return
	end
end

--Too few colors
if currentPalNumColors < 16 then
	currentPal:resize(16)
	--Avoid getting a warning about the shared color if we are inreasing the palette size
	for i = currentPalNumColors, 15, 4 do
		--(palLength) + (palLength mod 4)
		currentPal:setColor((i) + (i % 4), sharedColor)
	end
end

--The Shared Color is not saved properly
if sharedColor ~= currentPal:getColor(4) or sharedColor ~= currentPal:getColor(8) or sharedColor ~= currentPal:getColor(12) then
	local dlg = Dialog{title = "Shared Color isn't the same!"}
	dlg:label{ 	id    = "offSharedColor",
				label = "Warning!",
				text  = "Only color at index 0 will be used as the shared color. Do you want to continue?" }
	dlg:button{ id="continue", text="Continue" }
	dlg:button{ id="cancel", text="Cancel" }
	dlg:show()
	local data = dlg.data
	if data.cancel then
		return
	end
end

--Set up palettes
for i = 0, 3, 1 do
	paletteSGB0:setColor(i, currentPal:getColor(i))
	paletteSGB1:setColor(i, currentPal:getColor(i+4))
	paletteSGB2:setColor(i, currentPal:getColor(i+8))
	paletteSGB3:setColor(i, currentPal:getColor(i+12))
end

----------------------------------------
--Function to be called by script
----------------------------------------

local function writeBLKAttribute(palette, blockATR, blockFile)
	--Check if we have a BLK file open
	if blockFile ~= nil then
	--Control Code
		blockFile:write(";Control Code\n")
		blockFile:write(";Byte 2 - Control Code (0-7)\n")
		blockFile:write(";Bit 0 - Change Colors inside of surrounded area     (1=Yes)\n")
		blockFile:write(";Bit 1 - Change Colors of surrounding character line (1=Yes)\n")
		blockFile:write(";Bit 2 - Change Colors outside of surrounded area    (1=Yes)\n")
		blockFile:write(";Bit 3-7 - Not used (zero)\n")
		--[[
		At some point this will be customizeable, but for now it is hard wired for 
		only changing the color of the inside of the slice's area, which is either
		considered to be the inside of the BLK or the surrounding character line
		depending on the size
		]]
		if blockATR.width / 8 < 3 or blockATR.height / 8 < 3 then
			blockFile:write(".DB %00000010\n\n")
		else
			blockFile:write(".DB %00000001\n\n")
			
		end
		bytesWritten = bytesWritten + 1
		if bytesWritten % 16 == 0 then
			blockFile:write(";Data Packet # " .. string.format("%d", bytesWritten / 16  + 1) .. "\n\n")
		end
	--Color Palette(s)
		blockFile:write(";Color Palette Desgination\n")
		blockFile:write(";Byte 3 - Color Palette Designation\n")
		blockFile:write(";Bit 0-1 - Palette Number for inside of surrounded area\n")
		blockFile:write(";Bit 2-3 - Palette Number for surrounding character line\n")
		blockFile:write(";Bit 4-5 - Palette Number for outside of surrounded area\n")
		blockFile:write(";Bit 6-7 - Not used (zero)\n")
	--[[
		Again, at some point this will be updated to incorporate multiple palettes for the
		Outside, Inside and Surrounding portions
		Something like this:
		--Bitshift palette outside by 4
		--Bitshift palette character line by 2
		--Outside AND Character Line AND Inside
	]]
		if blockATR.width / 8 < 3 or blockATR.height / 8 < 3 then
			blockFile:write(".DB $" .. string.format("%02X", palette << 2) .. "\n\n")
		else
			blockFile:write(".DB $" .. string.format("%02X", palette) .. "\n\n")
			
		end
		bytesWritten = bytesWritten + 1
		if bytesWritten % 16 == 0 then
			blockFile:write(";Data Packet # " .. string.format("%d", bytesWritten / 16  + 1) .. "\n\n")
		end
	--X1
		blockFile:write(";Coordinate X1\n")
		blockFile:write(";Byte 4 - Top Left X Coordinate in # of 8x8 Columns\n")
		blockFile:write(".DB $" .. string.format("%02X", blockATR.x / 8) .. "\n\n")
		bytesWritten = bytesWritten + 1
		if bytesWritten % 16 == 0 then
			blockFile:write(";Data Packet # " .. string.format("%d", bytesWritten / 16  + 1) .. "\n\n")
		end
	--Y1
		blockFile:write(";Coordinate Y1\n")
		blockFile:write(";Byte 5 - Top Left Y Coordinate in # of 8x8 rows\n")
		blockFile:write(".DB $" .. string.format("%02X", blockATR.y / 8) .. "\n\n")
		bytesWritten = bytesWritten + 1
		if bytesWritten % 16 == 0 then
			blockFile:write(";Data Packet # " .. string.format("%d", bytesWritten / 16  + 1) .. "\n\n")
		end
	--X2
		blockFile:write(";Coordinate X2\n")
		blockFile:write(";Byte 6 - Bottom Right X Coordinate in # of 8x8 Columns\n")
		blockFile:write(".DB $" .. string.format("%02X", (blockATR.x + blockATR.width - 1) / 8) .. "\n\n")
		bytesWritten = bytesWritten + 1
		if bytesWritten % 16 == 0 then
			blockFile:write(";Data Packet # " .. string.format("%d", bytesWritten / 16  + 1) .. "\n\n")
		end
	--X2
		blockFile:write(";Coordinate Y2\n")
		blockFile:write(";Byte 7 - Bottom Right Y Coordinate in # of 8x8 Rows\n")
		blockFile:write(".DB $" .. string.format("%02X", (blockATR.y + blockATR.height - 1) / 8) .. "\n\n")
		bytesWritten = bytesWritten + 1	
		if bytesWritten % 16 == 0 then
			blockFile:write(";Data Packet # " .. string.format("%d", bytesWritten / 16  + 1) .. "\n\n")
		end
	else
		app.alert("Write file not properly loaded!")
		return
	end
end

local function writeLINAttribute(palette, lineATR, lineFile)
	--The data for the Data set byte
	local lineNumber
	local modeHV
	local horizontal = 1
	local vertical = 0
	local dataSetByte
	lineFile:write(";Bit 0- 4 - Line Number ( X or Y coordinate, depending on bit 7)\n")
	lineFile:write(";Bit 5- 6 - Palette Number ( 0- 3)\n")
	lineFile:write(";Bit 7 - H/V Mode Bit ( 0=Vertical line, 1=Horizontal Line)\n")
	if lineATR.width > lineATR.height then
	--This is a horizontal LIN
		lineNumber = lineATR.y / 8
		modeHV = horizontal
	else
	--This is a vertical LIN
		lineNumber = lineATR.x / 8
		modeHV = vertical
	end
	--Write our data
	dataSetByte = lineNumber | (palette << 5) | (modeHV << 7)
	lineFile:write(string.format(".DB $%02X", dataSetByte) .. "\n\n")

	bytesWritten = bytesWritten + 1	
	if bytesWritten % 16 == 0 then
		lineFile:write(";Data Packet # " .. string.format("%d", bytesWritten / 16  + 1) .. "\n\n")
	end

end

local function writeCHRAttribute(palette, numRows, numCols)

end

local function writeDIVAttribute(palette, numRows, numCols)

end

----------------------------------------
--Start of script
----------------------------------------

--User determines the palette used for each ATR
for i = 1, #slices, 1 do
	if slices[i] ~= nil then
		--Save our User Selected Palette
		local palIndex

		--Show which ATR we are talking about, and adjust to nearest tile
		local tiledRect = slices[i].bounds
		--X
		if tiledRect.x % 8 > 4 then
			tiledRect.width = tiledRect.width - (8 - tiledRect.x % 8)
			tiledRect.x = tiledRect.x + (8 - tiledRect.x % 8)
		else
			tiledRect.width = tiledRect.width + (tiledRect.x % 8)
			tiledRect.x = tiledRect.x - tiledRect.x % 8
		end
		--Y
		if tiledRect.y % 8 > 4 then
			tiledRect.height = tiledRect.height - (8 - tiledRect.y % 8)
			tiledRect.y = tiledRect.y + (8 - tiledRect.y % 8)
		else
			tiledRect.height = tiledRect.height + (tiledRect.y % 8)
			tiledRect.y = tiledRect.y - tiledRect.y % 8
		end
		--WIDTH
		if tiledRect.width % 8 > 4 then
			tiledRect.width = tiledRect.width + (8 - (tiledRect.width) % 8)
		else
			tiledRect.width = tiledRect.width - tiledRect.width % 8
		end
		--HEIGHT
		if tiledRect.height % 8 > 4 then
			tiledRect.height = tiledRect.height + (8 - (tiledRect.height) % 8)
		else
			tiledRect.height = tiledRect.height - tiledRect.height % 8
		end

		--Save slice as a specific type of ATR
		local numRows
		local numCol
		numRows = tiledRect.height / 8
		numCol = tiledRect.width / 8
		
		local dlg = Dialog {title = "Select SGB Attribute palette  ", hexpand = true}	
	-- DIALOGUE
		dlg:newrow{ always=false }
		dlg:label{
			id = "positionInfo",
			text = "Choose a palette for the selected SGB ATR at " .. string.format("%02X",slices[i].bounds.x / 8 ).. ", " .. string.format("%02X",slices[i].bounds.y / 8)
			}
		dlg:shades {
			--Display our color palette
			id = "pal0",
			--label = "Palette 0",
			colors = {sharedColor, paletteSGB0:getColor(1), paletteSGB0:getColor(2) ,paletteSGB0:getColor(3)}
			}
		dlg:shades {
			--Display our color palette
			id = "pal1",
			--label = "Palette 1",
			colors = {sharedColor, paletteSGB1:getColor(1), paletteSGB1:getColor(2) ,paletteSGB1:getColor(3)}
			}
		dlg:shades {
			--Display our color palette
			id = "pal2",
			--label = "Palette 2",
			colors = {sharedColor, paletteSGB2:getColor(1), paletteSGB2:getColor(2) ,paletteSGB2:getColor(3)}
			}
		dlg:shades {
			--Display our color palette
			id = "pal3",
			--label = "Palette 3",
			colors = {sharedColor, paletteSGB3:getColor(1), paletteSGB3:getColor(2) ,paletteSGB3:getColor(3)}
			}
		dlg:button{
			id = "pal0Btn",
			text = "Palette 0",
			focus = false,
			selected = false,
			onclick = function()
				palIndex = 0
				dlg:close()
			end
			}
		dlg:button{
			id = "pal1Btn",
			text = "Palette 1",
			focus = false,
			selected = false,
			onclick = function()
				palIndex = 1
				dlg:close()
			end
			}
		dlg:button{
			id = "pal2Btn",
			text = "Palette 2",
			focus = false,
			selected = false,
			onclick = function()
				palIndex = 2
				dlg:close()
			end
			}
		dlg:button{
			id = "pal3Btn",
			text = "Palette 3",
			focus = false,
			selected = false,
			onclick = function()
				palIndex = 3
				dlg:close()
			end
			}
		if numRows == 1 and numCol == 1 then
			dlg:label{
				id = "exportTypeATR",
				--text = "Slice will export as a CHR ATR"
				text = "Slice will export as a BLK ATR"
				}
			--[[
			dlg:check{ 
					id="saveBLK",
					text="Export this ATR as a BLK",
					selected=false
				} 
			]]
			
		elseif numRows == sprite.height / 8 or numCol == sprite.width / 8 then
			dlg:label{
				id = "exportTypeATR",
				text = "Slice will export as a LIN ATR"
				}
			dlg:check{ 
					id="saveBLK",
					text="Export this ATR as a BLK",
					selected=false
				} 
			--[[
				dlg:check{ 
				id="exportDIV",
				text="Export this ATR as a DIV",
				selected=false
			}
			]]
			--Might add DIV support later. For now it's a bit tricky.
		else
			dlg:label{
				id = "exportTypeATR",
				text = "Slice will export as a BLK ATR"
				}
		end
		dlg:newrow()
		dlg:button{
			id = "skipSlice",
			text = "Skip this slice",
			focus = false,
			selected = false
			}
		dlg:newrow()
		dlg:button{ id="cancel", text="Cancel" }

		sprite.selection:deselect()
		app.refresh()
		sprite.selection:select(tiledRect)
		dlg:show()
		local data = dlg.data
	--Save the palette index for each attribute
		if data.cancel then
			sprite.selection:deselect()
			return
		end

	--Skip this one
		if palIndex == nil or data.skipSlice then
			--Do nothing
			
	--Is it actually a DIV?
		elseif data.exportDiv and data.skipSlice ~= true then
			--It is a DIV
			arrayDIV[numDIV + 1] = tiledRect
			palDIV[numDIV + 1] = palIndex
			numDIV = numDIV + 1
			totalNumATR = totalNumATR + 1

	--If the size is bigger than 1x1, it's a BLK
		elseif numRows > 1 and numCol > 1 or data.saveBLK then
				arrayBLK[numBLK + 1] = tiledRect
				palBLK[numBLK + 1] = palIndex
				numBLK = numBLK + 1
				totalNumATR = totalNumATR + 1

				--NOTE: BLK will only be able to change the color inside for the time
				--being. Perhaps at some point I will update it to be more robust. 
			--end

	--Is it a CHR, DIV or a LIN?
		elseif numRows == 1 or numCol == 1 then
			if numRows == sprite.height / 8 or numCol == sprite.width / 8 then
				--It's a LIN
				arrayLIN[numLIN + 1] = tiledRect
				palLIN[numLIN + 1] = palIndex
				numLIN = numLIN + 1
				totalNumATR = totalNumATR + 1
			else
				--[[
				arrayCHR[numCHR + 1] = tiledRect
				palCHR[numCHR + 1] = palIndex
				numCHR = numCHR + 1
				totalNumATR = totalNumATR + 1
				]]
				--It's a CHR

				--For now, save everything as BLK
				arrayBLK[numBLK + 1] = tiledRect
				palBLK[numBLK + 1] = palIndex
				numBLK = numBLK + 1
				totalNumATR = totalNumATR + 1
				
			end
		end
	end
end
	sprite.selection:deselect()
	app.refresh()

--By this point, all of our ATRs should be solved for so all we have to do is...
local arrayFile = {fileBLK, fileLIN, fileDIV, fileCHR}
local arrayATR = {arrayBLK, arrayLIN, arrayDIV, arrayCHR}
local arrayPals = {palBLK, palLIN, palDIV, palCHR}
local arrayNames = {"BLK", "LIN", "DIV", "CHR"}
local arrayCodes = {codeBLK, codeLIN, codeDIV, codeCHR}
local arraySizes = {sizeBLK, sizeLIN, sieDIV, sizeCHR}

for i = 1, #arrayATR do
	if arrayFile[i] == nil and arrayATR[i][1] ~= nil then
		bytesWritten = 0
		--Command Byte
		local file = io.open(spriteFullPath:gsub("%.%w+$", "") .. arrayNames[i] ..".inc", "w")
		file:write(";Data Packet # 1\n\n")
		file:write(";Data for 16 byte packet that creates a " .. arrayNames[i] .. " ATR\n")
		file:write(";Command Code:\n")
		file:write(";Byte 0 - Command*8+Length (length=1..7)\n")
		file:write(".DB $")
		bytesWritten = bytesWritten + 1
		--Calculate number of data packets for the Command Byte
		--						Size of BLKs      +  Remainder of Data packet sie             				  / Packet Size
		local numDataPackets = ((arraySizes[i]*#arrayATR[i] + 2) + ((packetSize - ((arraySizes[i]*#arrayATR[i] + 2) % 16)) % packetSize)) / packetSize
		file:write(string.format("%02X", arrayCodes[i] + numDataPackets) .. "\n\n")

		--Data Set Byte
		file:write(";Number of Data sets\n")
		file:write(";Byte 1	- Number of Data Sets\n")
		file:write(".DB $")
		file:write(string.format("%02X", #arrayATR[i]) .. "\n\n")
		bytesWritten = bytesWritten + 1

		--Write the ATR data
		if i == 1 then
		--BLK
			for j = 1, #arrayATR[i] do
				file:write(";Data Set #" .. string.format("%d", j) .. "\n\n")
				writeBLKAttribute(arrayPals[i][j], arrayATR[i][j], file)
			end
		elseif i == 2 then
		--LIN
			for j = 1, #arrayATR[i] do
				file:write(";Data Set #" .. string.format("%d", j) .. "\n\n")
				writeLINAttribute(arrayPals[i][j], arrayATR[i][j], file)
			end

		elseif i == 3 then
		--DIV
		
		elseif i == 4 then
		--CHR

		end
			
		--Write any extra $00s if we need to 
		local extraData = (packetSize - ((arraySizes[i]*#arrayATR[i] +2) % packetSize) % packetSize)
		file:write(";Extra Bytes to fill up the Data Packet\n")
		file:write(".DB ")
		for i = 1, extraData do 
			file:write("$00 ")
		end
		file:write("\n")
		file:write(";End of SGB Data Packets")

		file:close()
	end
end


