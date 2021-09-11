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

	local infoboxImage = mw.html.create('div'):addClass('infobox-image lightmode')
	size = tonumber(size or '')
	if size then
		size = size .. 'px'
		infoboxImage:addClass('infobox-fixed-size-image')
	else
		size = '600px'
	end
	local fullFileName = '[[File:' .. (fileName or default) .. '|center|' .. size .. ']]'
	infoboxImage:wikitext(mw.getCurrentFrame():preprocess('{{#metaimage:' .. (fileName or '') .. '}}') .. fullFileName)

	local infoboxImageDark = mw.html.create('div'):addClass('infobox-image darkmode')
	if size then
		size = size .. 'px'
		infoboxImageDark:addClass('infobox-fixed-size-image')
	else
		size = '600px'
	end
	fileNameDark = fileNameDark or fileName or fileNameDark or default
	fullFileName = '[[File:' .. (fileNameDark .. '|center|' .. size .. ']]'
	infoboxImageDark:wikitext(mw.getCurrentFrame():preprocess('{{#metaimage:' .. (fileName or '') .. '}}') .. fullFileName)
	return mw.html.create('div'):node(infoboxImage):node(infoboxImageDark)
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
