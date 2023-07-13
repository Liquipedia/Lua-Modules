---
-- @Liquipedia
-- wiki=commons
-- page=Module:Game/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Game = Lua.import('Module:Game', {requireDevIfEnabled = true})
local Info = Lua.import('Module:Info', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

local COMMONS_IDENTIFIER = 'commons'
local COMMONS_DATA = Info.games.commons
local COMMONS_ICON = mw.text.decode('[[File:Liquipedia logo.png|link=lpcommons:Main Page|class=|25x25px]]')
local GAME_TO_THROW = 'please throw'

function suite:testToIdentifier()
	self:assertEquals(COMMONS_IDENTIFIER, Game.toIdentifier())
	self:assertEquals(nil, Game.toIdentifier{useDefault = false})
	self:assertEquals(nil, Game.toIdentifier{game = 'lp'})
	self:assertEquals(COMMONS_IDENTIFIER, Game.toIdentifier{game = 'comMoNs'})
end

function suite:testDataRetrieve()
	self:assertDeepEquals(COMMONS_DATA, Game.raw())
	self:assertEquals(COMMONS_DATA.abbreviation, Game.abbreviation())
	self:assertEquals(COMMONS_DATA.name, Game.name())
	self:assertEquals(COMMONS_DATA.link, Game.link())
	self:assertDeepEquals(COMMONS_DATA.defaultTeamLogo, Game.defaultTeamLogoData())
end

function suite:testIcon()
	self:assertEquals(COMMONS_ICON,
		Game.icon({noSpan = true}))
	self:assertEquals('<span class="span-class">' .. COMMONS_ICON .. '</span>',
		tostring(Game.icon({spanClass = 'span-class'})))
	self:assertEquals('<span class="icon-16px">' .. COMMONS_ICON .. '</span>',
		tostring(Game.icon()))
end

function suite:testText()
	self:assertEquals('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.name .. ']]', Game.text())
	self:assertEquals('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.name .. ']]', Game.text({}))
	self:assertEquals('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.name .. ']]', Game.text({game = ''}))
	self:assertEquals(COMMONS_DATA.name, Game.text({noLink = true}))
	self:assertEquals('[[' .. 'ABC123' .. '|' .. COMMONS_DATA.name .. ']]', Game.text({link = 'ABC123'}))
	self:assertEquals('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.abbreviation .. ']]',
		Game.text({useAbbreviation = true}))
	self:assertEquals(COMMONS_DATA.abbreviation, Game.text({noLink = true, useAbbreviation = true}))
	self:assertEquals('[[' .. 'ABC123' .. '|' .. COMMONS_DATA.abbreviation .. ']]',
		Game.text({useAbbreviation = true, link = 'ABC123'}))
	self:assertEquals('<abbr title="The specified game input is not recognized">Unknown Game</abbr>',
		Game.text({useDefault = false}))
	self:assertEquals('<abbr title="The specified game input is not recognized">Unkwn.</abbr>',
		Game.text({useDefault = false, useAbbreviation = true}))
end

function suite:testList()
	self:assertEquals(COMMONS_IDENTIFIER, Game.listGames()[1])
	self:assertEquals(COMMONS_IDENTIFIER, Game.listGames({ordered = true})[1])
	self:assertEquals(COMMONS_IDENTIFIER, Game.listGames({ordered = false})[1])
end

function suite:testIsDefaultTeamLogo()
	self:assertEquals(true, Game.isDefaultTeamLogo{logo = 'Liquipedia logo.png'})
	self:assertEquals(false, Game.isDefaultTeamLogo{logo = 'Liquipedia logo.jpg'})
	self:assertEquals(false, Game.isDefaultTeamLogo{logo = 'bviarBRVNUI.jpg'})

	self:assertThrows(function()
		Game.isDefaultTeamLogo{logo = 'Liquipedia logo.png', game = GAME_TO_THROW}
	end, 'Invalid game input "' .. GAME_TO_THROW .. '"')
end

return suite
