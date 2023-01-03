---
-- @Liquipedia
-- wiki=commons
-- page=Module:OpponentDisplay/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

---
-- InlineOpponent
---
function suite:testInlineOpponentSolo()
	local opponent = {type = 'solo', players = {{displayName = 'test', pageName = 'link', flag = 'de'}}}
	self:assertEquals(
		'<span class="inline-player" style="white-space:pre">'
			.. '<span class="flag">[[File:de_hd.png|Germany|link=]]</span>'
			.. '&nbsp;[[link|test]]</span>',
		tostring(OpponentDisplay.InlineOpponent{opponent = opponent}),
		'Unexpected default display'
	)
	self:assertEquals(
		'<span class="inline-player" style="white-space:pre">[[link|test]]</span>',
		tostring(OpponentDisplay.InlineOpponent{showFlag = false, opponent = opponent}),
		'Disabling flags did not work'
	)
	self:assertEquals(
		'<span class="inline-player" style="white-space:pre">'
			.. '<span class="flag">[[File:de_hd.png|Germany|link=]]</span>'
			.. '&nbsp;[[link|test]]</span>',
		tostring(OpponentDisplay.InlineOpponent{showFlag = true, opponent = opponent}),
		'Showing flags did not work'
	)
	self:assertEquals(
		'<span class="inline-player" style="white-space:pre">'
			.. '<span class="flag">[[File:de_hd.png|Germany|link=]]</span>'
			.. '&nbsp;test</span>',
		tostring(OpponentDisplay.InlineOpponent{showLink = false, opponent = opponent}),
		'Hiding links did not work'
	)
	self:assertEquals(
		'<span class="inline-player" style="white-space:pre">'
			.. '<span class="flag">[[File:de_hd.png|Germany|link=]]</span>'
			.. '&nbsp;[[link|test]]</span>',
		tostring(OpponentDisplay.InlineOpponent{showLink = true, opponent = opponent}),
		'Hiding links did not work'
	)
	self:assertEquals(
		'<span class="inline-player" style="white-space:pre">'
			.. '<span class="flag">[[File:de_hd.png|Germany|link=]]</span>'
			.. '&nbsp;<s>[[link|test]]</s></span>',
		tostring(OpponentDisplay.InlineOpponent{dq = true, opponent = opponent}),
		'Strikethrough/DQ did not work'
	)

	opponent.players[1].pageName = nil
	self:assertEquals(
		'<span class="inline-player" style="white-space:pre">'
			.. '<span class="flag">[[File:de_hd.png|Germany|link=]]</span>'
			.. '&nbsp;test</span>',
		tostring(OpponentDisplay.InlineOpponent{showLink = true, opponent = opponent}),
		'Unexpected display for missing links'
	)
end

return suite
