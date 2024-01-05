---
-- @Liquipedia
-- wiki=pokemon
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local GameAppearances = require('Module:GetGameAppearances')
local Lua = require('Module:Lua')
local Role = require('Module:Role')
local Region = require('Module:Region')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local _pagename = mw.title.getCurrentTitle().prefixedText

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	player:setWidgetInjector(CustomInjector(player))
	_args = player.args

	player.roleData = Role.run({role = _args.role})
	player.roleData2 = Role.run({role = _args.role2})

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'history' then
		local manualHistory = _args.history
		local automatedHistory = TeamHistoryAuto._results{
			convertrole = 'true',
			player = _pagename
		}

		if String.isNotEmpty(manualHistory) or automatedHistory then
			return {
				Title{name = 'History'},
				Center{content = {manualHistory}},
				Center{content = {automatedHistory}},
			}
		end
	elseif id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = {self.caller.roleData.display, self.caller.roleData2.display}}
		}
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	return {
		Cell{
			name = 'Game Appearances',
			content = GameAppearances.player({player = _pagename})
		},
	}
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.isplayer = self.roleData.isPlayer or 'true'
	lpdbData.extradata.role = self.roleData.role
	lpdbData.extradata.role2 = self.roleData2.role

	lpdbData.region = String.nilIfEmpty(Region.name({region = _args.region, country = _args.country}))

	return lpdbData
end

return CustomPlayer
