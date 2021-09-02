---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Links
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')
local UtilLinks = require('Module:Links')
local Table = require('Module:Table')

local Links = Class.new(
	Widget,
	function(self, input)
		self.links = input.content
		self.variant = input.variant
	end
)

local _ICON_KEYS_TO_RENAME = {
    matcherinolink = 'matcherino'
}

function Links:make()
    local infoboxLinks = mw.html.create('div')
    infoboxLinks    :addClass('infobox-center')
                    :addClass('infobox-icons')

    for key, value in Table.iter.spairs(self.links) do
        key = self:_removeAppendedNumber(key)
        local link = '[' .. UtilLinks.makeFullLink(key, value, self.variant) ..
            ' <i class="lp-icon lp-' .. (_ICON_KEYS_TO_RENAME[key] or key) .. '></i>]'
        infoboxLinks:wikitext(' ' .. link)
    end

	return {
		mw.html.create('div'):node(infoboxLinks)
	}
end

--remove appended number
--needed because the link icons require e.g. 'esl' instead of 'esl2'
function Links:_removeAppendedNumber(key)
    return string.gsub(key, '%d$', '')
end

return Links
