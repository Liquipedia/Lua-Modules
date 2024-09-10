---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class HeaderWidget: Widget
---@operator call(table): HeaderWidget
---@field name string?
---@field subHeader string?
---@field image string?
---@field imageDefault string?
---@field imageDark string?
---@field imageDefaultDark string?
---@field size number|string|nil
---@field imageText string?
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
		self.imageText = input.imageText
	end
)

---@param injector WidgetInjector?
---@return Html[]
function Header:make(injector)
	local header = {
		Header:_name(self.name),
		Header:_image(
			self.image,
			self.imageDark,
			self.imageDefault,
			self.imageDefaultDark,
			self.size,
			self.imageText
		)
	}

	if self.image then
		mw.ext.SearchEngineOptimization.metaimage(self.image)
	end

	local subHeader = Header:_subHeader(self.subHeader)
	if subHeader then
		table.insert(header, 2, subHeader)
	end

	return header
end

---@param name string?
---@return Html
function Header:_name(name)
	local pagename = name or mw.title.getCurrentTitle().text
	local infoboxHeader = mw.html.create('div')
	infoboxHeader	:addClass('infobox-header')
					:addClass('wiki-backgroundcolor-light')
					:node(self:_createInfoboxButtons())
					:wikitext(pagename)
	return mw.html.create('div'):node(infoboxHeader)
end

---@param subHeader string?
---@return Html?
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

---@param fileName string?
---@param fileNameDark string?
---@param default string?
---@param defaultDark string?
---@param size number|string|nil
---@param imageText string?
---@return Html?
function Header:_image(fileName, fileNameDark, default, defaultDark, size, imageText)
	if (fileName == nil or fileName == '') and (default == nil or default == '') then
		return nil
	end

	local imageName = fileName or default
	---@cast imageName -nil
	local infoboxImage = Header:_makeSizedImage(imageName, fileName, size, 'lightmode')

	imageName = fileNameDark or fileName or defaultDark or default
	---@cast imageName -nil
	local infoboxImageDark = Header:_makeSizedImage(imageName, fileNameDark or fileName, size, 'darkmode')

	local imageTextNode = Header:_makeImageText(imageText)

	return mw.html.create('div'):addClass('infobox-image-wrapper')
		:node(infoboxImage)
		:node(infoboxImageDark)
		:node(imageTextNode)
end

---@param imageName string
---@param fileName string?
---@param size number|string|nil
---@param mode string
---@return Html
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
		local scaleNumber = tonumber(scale)
		if scaleNumber then
			size = 'frameless|upright=' .. (scaleNumber / 100)
			infoboxImage:addClass('infobox-fixed-size-image')
		end
	-- Default
	else
		size = '600px'
	end

	local fullFileName = '[[File:' .. imageName .. '|center|' .. size .. ']]'
	infoboxImage:wikitext(fullFileName)

	return infoboxImage
end

---@return Html
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
	buttons:addClass('navigation-not-searchable')

	-- Quick edit link
	buttons:node(
		mw.text.nowiki('[') .. '[' .. mw.site.server ..
		tostring(mw.uri.localUrl( mw.title.getCurrentTitle().prefixedText, 'action=edit&section=0' )) ..
		' e]' .. mw.text.nowiki(']')
	)

	-- Quick help link (links to template)
	if not mw.title.new(moduleTitle).exists then
		moduleTitle = 'lpcommons:'.. moduleTitle
	end
	buttons:node(mw.text.nowiki('[') .. '[[' .. moduleTitle ..'|h]]' .. mw.text.nowiki(']'))

	return buttons
end

---@param text string?
---@return Html?
function Header:_makeImageText(text)
	if not text then
		return
	end

	return mw.html.create('div'):addClass('infobox-image-text'):wikitext(text)
end

return Header
