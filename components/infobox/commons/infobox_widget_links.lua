---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Links
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local UtilLinks = Lua.import('Module:Links', {requireDevIfEnabled = true})
local Widget = Lua.import('Module:Infobox/Widget', {requireDevIfEnabled = true})

local Links = Class.new(
	Widget,
	function(self, input)
		self.links = Table.copy(input.content)
		self.variant = input.variant
	end
)

local _ICON_KEYS_TO_RENAME = {
	['bilibili-stream'] = 'bilibili',
	daumcafe = 'cafe-daum',
	['esea-d'] = 'esea-league',
	['faceit-c'] = 'faceit',
	['faceit-c2'] = 'faceit',
	['faceit-hub'] = 'faceit',
	['faceit-org'] = 'faceit',
	matcherinolink = 'matcherino',
	playlist = 'music',
	privsteam = 'steam',
	pubsteam = 'steam',
	steamalternative = 'steam',
	tlpdint = 'tlpd',
	tlpdkr = 'tlpd-wol-korea',
	tlpdsospa = 'tlpd-sospa',
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
		'apexlegendsstatus',
		'battlefy',
		'b5csgo',
		'challengermode',
		'challonge',
		'cybergamer',
		'datdota',
		'dotabuff',
		'esea',
		'esea-d',
		'esl',
		'esportal',
		'faceit',
		'faceit-c',
		'faceit-hub',
		'faceit-org',
		'factor',
		'gamersclub',
		'halodatahive',
		'letsplaylive',
		'matcherino',
		'matcherinolink',
		'siege-gg',
		'sk',
		'smash-gg',
		'sostronk',
		'start-gg',
		'stratz',
		'toornament',
		'trackmania-io',
		'vlr',
		'bracket',
		'rules',
		'rulebook',
	},
	social = {
		'discord',
		'facebook',
		'instagram',
		'privsteam',
		'pubsteam',
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
		'stream',
		'afreeca',
		'dlive',
		'facebook-gaming',
		'vidio',
		'booyah',
		'douyu',
		'huyatv',
		'zhangyutv',
		'bilibili-stream',
		'kuaishou',
	}
}

function Links:make()
	local infoboxLinks = mw.html.create('div')
	infoboxLinks	:addClass('infobox-center')
					:addClass('infobox-icons')

	for _, group in Table.iter.spairs(_PRIORITY_GROUPS) do
		for _, key in ipairs(group) do
			if self.links[key] ~= nil then
				infoboxLinks:wikitext(' ' .. self:_makeLink(key, self.links[key]))
				-- Remove link from the collection
				self.links[key] = nil

				local index = 2
				while self.links[key .. index] ~= nil do
					infoboxLinks:wikitext(' ' .. self:_makeLink(key, self.links[key .. index]))
					-- Remove link from the collection
					self.links[key .. index] = nil
					index = index + 1
				end
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
