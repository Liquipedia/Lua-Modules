---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')

local Header = Class.new(
	Widget,
	function(self, input)
		self.name = input.name
		self.subHeader = input.subHeader
		self.image = input.image
		self.imageDefault = input.imageDefault
		self.imageDark = input.imageDark
		self.imageDefaultDark = input.imageDefaultDark
		self.size = input.size
	end
)

function Header:make()
	local header = {
		Header:_name(self.name),
		Header:_image(
			self.image,
			self.imageDark,
			self.imageDefault,
			self.imageDefaultDark,
			self.size
		)
	}

	local subHeader = Header:_subHeader(self.subHeader)
	if subHeader then
		table.insert(header, 2, subHeader)
	end

	return header
end

function Header:_name(name)
	local pagename = name or mw.title.getCurrentTitle().text
	local infoboxHeader = mw.html.create('div')
	infoboxHeader	:addClass('infobox-header')
					:addClass('wiki-backgroundcolor-light')
					:node(self:_createInfoboxButtons())
					:wikitext(pagename)
	return mw.html.create('div'):node(infoboxHeader)
end

function Header:_subHeader(subHeader)
	if not subHeader then
		return nil
	end
	local infoboxSubHeader = mw.html.create('div')
	infoboxSubHeader:addClass('infobox-header')
					:addClass('wiki-backgroundcolor-light')
					:addClass('infobox-header-2')
					:wikitext(subHeader)
	return mw.html.create('div'):node(infoboxSubHeader)
end

function Header:_image(fileName, fileNameDark, default, defaultDark, size)
	if (fileName == nil or fileName == '') and (default == nil or default == '') then
		return nil
	end

	local imageName = fileName or default
	local infoboxImage = Header:_makeSizedImage(imageName, fileName, size, 'lightmode')

	imageName = fileNameDark or fileName or defaultDark or default
	local infoboxImageDark = Header:_makeSizedImage(imageName, fileNameDark or fileName, size, 'darkmode')

	return mw.html.create('div'):node(infoboxImage):node(infoboxImageDark)
end

function Header:_makeSizedImage(imageName, fileName, size, mode)
	local infoboxImage = mw.html.create('div'):addClass('infobox-image ' .. mode)

	-- Number (interpret as pixels)
	size = size or ''
	if tonumber(size) then
		size = tonumber(size) .. 'px'
		infoboxImage:addClass('infobox-fixed-size-image')
	-- Percentage (interpret as scaling)
	elseif size:find('%%') then
		local scale = size:gsub('%%', '')
		scale = tonumber(scale)
		if scale then
			size = 'frameless|upright=' .. (scale / 100)
			infoboxImage:addClass('infobox-fixed-size-image')
		end
	-- Default
	else
		size = '600px'
	end

	local fullFileName = '[[File:' .. imageName .. '|center|' .. size .. ']]'
	infoboxImage:wikitext(mw.getCurrentFrame():preprocess('{{#metaimage:' .. (fileName or '') .. '}}') .. fullFileName)

	return infoboxImage
end

function Header:_createInfoboxButtons()
	local rootFrame
	local currentFrame = mw.getCurrentFrame()
	while currentFrame ~= nil do
		rootFrame = currentFrame
		currentFrame = currentFrame:getParent()
	end

	local moduleTitle = rootFrame:getTitle()

	local buttons = mw.html.create('span')
	buttons:addClass('infobox-buttons')
	buttons:node(
		mw.text.nowiki('[') .. '[' .. mw.site.server ..
		tostring(mw.uri.localUrl( mw.title.getCurrentTitle().prefixedText, 'action=edit&section=0' )) ..
		' e]' .. mw.text.nowiki(']')
	)
	buttons:node(
		mw.text.nowiki('[') ..
		'[[' .. moduleTitle ..
		'/doc|h]]' .. mw.text.nowiki(']')
	)

	return buttons
end

return Header
