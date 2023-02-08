---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Achievements = require('Module:Achievements in infoboxes')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Math = require('Module:Math')
local Placement = require('Module:Placement')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CURRENT_YEAR = tonumber(os.date('%Y'))

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _player
local _args

function CustomPlayer.run(frame)
	_player = Player(frame)
	_args = _player.args

	-- Automatic achievements
	_args.achievements = Achievements._player{player = _player.pagename}

	-- Profiles to links
	_args.esl = _args.esl or _args.eslprofile
	_args.nwc3l = _args.nwc3l or _args.nwc3lprofile

	-- Uppercase first letter in status
	if _args.status then
		_args.status = mw.getContentLanguage():ucfirst(_args.status)
	end

	_player.adjustLPDB = CustomPlayer.adjustLPDB
	_player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return _player:createInfobox()
end

function CustomInjector:addCustomCells(widgets)
	--Earnings this Year
	local currentYearEarnings = _player.earningsPerYear[CURRENT_YEAR]
	if currentYearEarnings then
		currentYearEarnings = Math.round{currentYearEarnings}
		currentYearEarnings = '$' .. mw.getContentLanguage():formatNum(currentYearEarnings)
	end

	table.insert(widgets, Cell{name = 'Approx. Earnings '.. CURRENT_YEAR, content = {currentYearEarnings}})

	--Ranking of Earnings this Year
	local smwRes = mw.smw.ask('[[-Has subobject::<q>[[Earnings/'.. CURRENT_YEAR .. ']]</q>]]' ..
		'[[Has player page::'.. _player.pagename .. ']] |link=none |mainlabel=- |headers=hide |?has earning ranking')

	if smwRes and smwRes[1] then
		local ranking = string.match(smwRes[1]['Has earning ranking'], '%d+')
		table.insert(widgets, Cell{name = 'Earnings Ranking '.. CURRENT_YEAR, content = {
			Placement.RangeLabel{ranking, ranking}
		}})
	end

	-- Race/Faction
	table.insert(widgets, Cell{name = 'Race', content = {Faction.toName(_args.race)}})

	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.faction = Faction.toName(_args.race)
	lpdbData.extradata.factionhistorical = Variables.varDefault('racecount') and 'true' or 'false'

	return lpdbData
end

return CustomPlayer
