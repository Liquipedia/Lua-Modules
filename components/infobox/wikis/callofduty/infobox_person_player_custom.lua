---
-- @Liquipedia
-- wiki=callofduty
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local GameAppearances = require('Module:GetGameAppearances')
local Lua = require('Module:Lua')
local Role = require('Module:Role')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _pagename = mw.title.getCurrentTitle().prefixedText
local _role
local _role2

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args
	_args.autoTeam = true
	_role = Role.run({role = _args.role})
	_role2 = Role.run({role = _args.role2})

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox(frame)
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
	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = {_role.display, _role2.display}}
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

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.isplayer = _role.isPlayer or 'true'
	lpdbData.extradata.role = _role.role
	lpdbData.extradata.role2 = _role2.role

	return lpdbData
end

return CustomPlayer
