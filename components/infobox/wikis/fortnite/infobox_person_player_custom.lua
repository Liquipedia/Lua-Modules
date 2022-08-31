---
-- @Liquipedia
-- wiki=fortnite
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Player = require('Module:Infobox/Person')
local Abbreviation = require('Module:Abbreviation')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local ActiveYears = require('Module:YearsActive')
local Role = require('Module:Role')
local Region = require('Module:Region')
local Math = require('Module:Math')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local _pagename = mw.title.getCurrentTitle().prefixedText
local _role
local _role2
local _EMPTY_AUTO_HISTORY = '<table style="width:100%;text-align:left"></table>'
local _CURRENT_YEAR = tonumber(os.date('%Y'))

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _player

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args
	_player = player

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'history' then
		local manualHistory = _args.history
		local automatedHistory = TeamHistoryAuto._results({
			convertrole = 'true',
			player = _pagename
		}) or ''
		automatedHistory = tostring(automatedHistory)
		if automatedHistory == _EMPTY_AUTO_HISTORY then
			automatedHistory = nil
		end

		if String.isNotEmpty(manualHistory) or String.isNotEmpty(automatedHistory) then
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
		currentYearEarnings = Math.round{currentYearEarnings}
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

	local region = Region.run({region = _args.region, country = _args.country})
	if type(region) == 'table' then
		lpdbData.region = region.region
	end

	return lpdbData
end

return CustomPlayer
