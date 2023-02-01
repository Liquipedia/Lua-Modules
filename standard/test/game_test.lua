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

local suite = ScribuntoUnit:new()

local COMMONS_IDENTIFIER = 'commons'
local COMMONS_DATA = Lua.import('Module:Info', {requireDevIfEnabled = true}).games.commons
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
	self:assertEquals(COMMONS_ICON, Game.icon())
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
