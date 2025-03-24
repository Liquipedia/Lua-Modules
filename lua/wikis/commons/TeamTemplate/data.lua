---
-- @Liquipedia
-- wiki=commons
-- page=Module:TeamTemplate/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, teamTemplateData>
local SPECIAL_TEMPLATES = {
	['tbd'] = {
		name = '<abbr title="To Be Determined">TBD</abbr>',
		imagename = 'To Be Determined',
		page = 'TBD',
		shortname = '<abbr title="To Be Determined">TBD</abbr>',
		bracketname = '<abbr title="To Be Determined">TBD</abbr>',
		templatename = 'tbd',
		image = 'Filler 600px.png',
		imagedark = 'Filler 600px.png',
		legacyimage = '',
		legacyimagedark = '',
		nolink = true,
	},
	['tba'] = {
		name = '<abbr title="To Be Announced">TBA</abbr>',
		imagename = 'To Be Announced',
		page = 'TBA',
		shortname = '<abbr title="To Be Announced">TBA</abbr>',
		bracketname = '<abbr title="To Be Announced">TBA</abbr>',
		templatename = 'tba',
		image = 'Filler 600px.png',
		imagedark = 'Filler 600px.png',
		legacyimage = '',
		legacyimagedark = '',
		nolink = true,
	},
	['bye'] = {
		name = '<i class="color-dimgray">BYE</i>',
		imagename = 'BYE',
		page = 'BYE',
		shortname = '<i class="color-dimgray">BYE</i>',
		bracketname = '<i class="color-dimgray">BYE</i>',
		templatename = 'bye',
		image = 'Filler 600px.png',
		imagedark = 'Filler 600px.png',
		legacyimage = '',
		legacyimagedark = '',
		nolink = true,
	},
	[''] = {
		name = '',
		page = '',
		shortname = '',
		bracketname = '',
		templatename = '',
		image = 'Filler 600px.png',
		imagedark = 'Filler 600px.png',
		legacyimage = '',
		legacyimagedark = '',
		nolink = true,
	}
}

SPECIAL_TEMPLATES['definitions'] = SPECIAL_TEMPLATES['tbd']
SPECIAL_TEMPLATES['noteam'] = SPECIAL_TEMPLATES['']
SPECIAL_TEMPLATES['filler'] = SPECIAL_TEMPLATES['']

return SPECIAL_TEMPLATES
