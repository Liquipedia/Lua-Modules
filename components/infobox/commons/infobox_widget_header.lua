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
		self.name = self:assertExistsAndCopy(input.name)
		self.image = input.image
		self.imageDefault = input.imageDefault
		self.size = input.size
	end
)

function Header:make()
	return {
		Header:_name(self.name),
		Header:_image(self.image, self.imageDefault, self.size)
	}
end

function Header:_name(name)
    local pagename = name or mw.title.getCurrentTitle().text
    local infoboxHeader = mw.html.create('div'):addClass('infobox-header')
    infoboxHeader   :addClass('infobox-header')
                    :addClass('wiki-backgroundcolor-light')
                    :node(self:_createInfoboxButtons())
                    :wikitext(pagename)
    return mw.html.create('div'):node(infoboxHeader)
end

function Header:_image(fileName, default, size)
    if (fileName == nil or fileName == '') and (default == nil or default == '') then
        return self
    end

    local infoboxImage = mw.html.create('div'):addClass('infobox-image')
    size = tonumber(size or '')
    if size then
        size = size .. 'px'
        infoboxImage:addClass('infobox-fixed-size-image')
    else
        size = '600px'
    end
    local fullFileName = '[[File:' .. (fileName or default) .. '|center|' .. size .. ']]'
    infoboxImage:wikitext(self.frame:preprocess('{{#metaimage:' .. (fileName or '') .. '}}') .. fullFileName)
    return mw.html.create('div'):node(infoboxImage)
end

return Header
