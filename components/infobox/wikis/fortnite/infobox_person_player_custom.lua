---
-- @Liquipedia
-- wiki=fortnite
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local ActiveYears = require('Module:YearsActive')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Role = require('Module:Role')
local Region = require('Module:Region')
local Math = require('Module:MathUtil')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local _pagename = mw.title.getCurrentTitle().prefixedText
local _role
local _role2
local _CURRENT_YEAR = tonumber(os.date('%Y'))

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _player

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args
	_player = player
	_args.autoTeam = true

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'history' then
		local manualHistory = _args.history
		local automatedHistory = TeamHistoryAuto._results{
			addlpdbdata = true,
			convertrole = true,
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
		_role = Role.run({role = _args.role})
		_role2 = Role.run({role = _args.role2})
		return {
			Cell{name = 'Role(s)', content = {_role.display, _role2.display}}
		}
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	local yearsActive = ActiveYears.display{
		player = _player.pagename,
	}

	local currentYearEarnings = _player.earningsPerYear[_CURRENT_YEAR]
	if currentYearEarnings then
		currentYearEarnings = Math.round(currentYearEarnings)
		currentYearEarnings = '$' .. mw.language.new('en'):formatNum(currentYearEarnings)
	end

	return {
		Cell{
			name = 'Approx. Winnings ' .. _CURRENT_YEAR,
			content = {currentYearEarnings}
		},
		Cell{name = 'Years active', content = {yearsActive}},
		Cell{
			name = Abbreviation.make(
				'Epic Creator Code',
				'Support-A-Creator Code used when purchasing Fortnite or Epic Games Store products'
			),
			content = {_args.creatorcode}
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


	lpdbData.region = String.nilIfEmpty(Region.name({region = _args.region, country = _args.country}))

	return lpdbData
end

return CustomPlayer
