---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Image = require('Module:Image')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Widget = Lua.import('Module:Infobox/Widget')

---@class HeaderWidget: Widget
---@operator call(table): HeaderWidget
---@field name string?
---@field subHeader string?
---@field image string?
---@field imageDefault string?
---@field imageDark string?
---@field imageDefaultDark string?
---@field size number|string|nil
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
			self.size
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
---@return Html?
function Header:_image(fileName, fileNameDark, default, defaultDark, size)
	local imageName = fileName or default
	local imageDarkname = fileNameDark or fileName or defaultDark or default

	if String.isEmpty(imageName) and String.isEmpty(imageDarkname) then
		return nil
	end

	if imageName == imageDarkname then
		return mw.html.create('div'):node(Header:_makeSizedImage(imageName, size))
	end

	local infoboxImage = Header:_makeSizedImage(imageName, size, 'lightmode')
	local infoboxImageDark = Header:_makeSizedImage(imageDarkname, size, 'darkmode')

	return mw.html.create('div'):node(infoboxImage):node(infoboxImageDark)
end

---@param imageName string?
---@param size number|string|nil
---@param mode string?
---@return Html?
function Header:_makeSizedImage(imageName, size, mode)
	if String.isEmpty(imageName) then
		return
	end

	local infoboxImage = mw.html.create('div'):addClass('infobox-image'):addClass(mode)
	if Logic.isNumeric(size) then
		infoboxImage:addClass('infobox-fixed-size-image')
	else
		size = 600
	end

	infoboxImage:wikitext(Image.display(imageName, nil, {size = size}))

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

return Header
