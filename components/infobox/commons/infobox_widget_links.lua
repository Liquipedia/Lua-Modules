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

local _PRIORITY_GROUPS = {
	core = {
		'home',
		'site',
		'website'
	},
	league = {
		'5ewin',
		'abiosgaming',
		'aligulac',
		'battlefy',
		'challonge',
		'cybergamer',
		'esea',
		'easa-d',
		'esl',
		'faceit',
		'gamersclub',
		'matcherino',
		'matcherinolink',
		'sostronk',
		'toornament',
		'bracket',
		'rules',
		'rulebook',
	},
	social = {
		'discord',
		'facebook',
		'instagram',
		'reddit',
		'snapchat',
		'steam',
		'steamalternative',
		'telegram',
		'tiktok',
		'twitter',
		'vk',
		'weibo'
	},
	streams = {
		'twitch',
		'youtube',
		'afreeca',
		'dlive'
	}
}

function Links:make()
	local infoboxLinks = mw.html.create('div')
	infoboxLinks	:addClass('infobox-center')
					:addClass('infobox-icons')

	for _, group in Table.iter.spairs(_PRIORITY_GROUPS) do
		for _, key in ipairs(group) do
			if self.links[self:_removeAppendedNumber(key)] ~= nil then
				infoboxLinks:wikitext(' ' .. self:_makeLink(key, self.links[key]))

				-- Remove links from the collection
				self.links[key] = nil
			end
		end
	end

	for key, value in Table.iter.spairs(self.links) do
		infoboxLinks:wikitext(' ' .. self:_makeLink(key, value))
	end

	return {
		mw.html.create('div'):node(infoboxLinks)
	}
end

function Links:_makeLink(key, value)
	key = self:_removeAppendedNumber(key)
	return '[' .. UtilLinks.makeFullLink(key, value, self.variant) ..
		' <i class="lp-icon lp-' .. (_ICON_KEYS_TO_RENAME[key] or key) .. '></i>]'
end

--remove appended number
--needed because the link icons require e.g. 'esl' instead of 'esl2'
function Links:_removeAppendedNumber(key)
	return string.gsub(key, '%d$', '')
end

return Links
