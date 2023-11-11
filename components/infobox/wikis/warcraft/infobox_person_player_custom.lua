---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Variables = require('Module:Variables')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CURRENT_YEAR = tonumber(os.date('%Y'))
local NON_BREAKING_SPACE = '&nbsp;'

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _player
local _args

function CustomPlayer.run(frame)
	_player = Player(frame)
	_args = _player.args

	-- Automatic achievements
	_args.achievements = Achievements.player{noTemplate = true}

	-- Profiles to links
	_args.esl = _args.esl or _args.eslprofile
	_args.nwc3l = _args.nwc3l or _args.nwc3lprofile

	-- Uppercase first letter in status
	if _args.status then
		_args.status = mw.getContentLanguage():ucfirst(_args.status)
	end

	_player.adjustLPDB = CustomPlayer.adjustLPDB
	_player.createWidgetInjector = CustomPlayer.createWidgetInjector
	_player.nameDisplay = CustomPlayer.nameDisplay

	return _player:createInfobox()
end

function CustomInjector:addCustomCells(widgets)
	--Earnings this Year
	local currentYearEarnings = _player.earningsPerYear[CURRENT_YEAR]
	if currentYearEarnings then
		currentYearEarnings = Math.round(currentYearEarnings)
		currentYearEarnings = '$' .. mw.getContentLanguage():formatNum(currentYearEarnings)
	end

	table.insert(widgets, Cell{name = 'Approx. Earnings '.. CURRENT_YEAR, content = {currentYearEarnings}})

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'role' then
		-- WC doesn't show any roles, but rather shows the Race/Faction instead
		return {
			Cell{name = 'Race', content = {Faction.toName(_args.race)}}
		}
	end
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

function CustomPlayer.nameDisplay()
	local factionIcon = Faction.Icon{faction = Faction.read(_args.race)}

	return (factionIcon and (factionIcon .. NON_BREAKING_SPACE) or '')
		.. (_args.id or _player.pagename)
end

return CustomPlayer
