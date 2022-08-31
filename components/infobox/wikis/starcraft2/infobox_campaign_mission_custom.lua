---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/CampaignMission/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Mission = require('Module:Infobox/CampaignMission')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Header = require('Module:Infobox/Widget/Header')

local CustomMission = Class.new()

local CustomInjector = Class.new(Injector)

local _args

local _GAME_SWITCH = {
	wol = 'Wings of Liberty',
	hots = 'Heart of the Swarm',
	lotv = 'Legacy of the Void',
	nco = 'Nova Covert Ops',
	coop = 'Co-op Mission',
}
local _fullGameName

function CustomMission.run(frame)
	local mission = Mission(frame)
	_args = mission.args
	mission.createWidgetInjector = CustomMission.createWidgetInjector
	mission.getWikiCategories = CustomMission.getWikiCategories
	return mission:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
	return {
		Cell{ name = 'Credits Earned', content = {_args.credits}},
		Cell{ name = 'Research Points', content = {_args.research}},
		Cell{ name = 'Kerrigan Levels', content = {_args.Kerrigan}},
		Cell{ name = 'Evolution Unlock', content = {CustomMission._getEvolution()}},
		Cell{ name = 'New Units', content = {_args.units}},
		Cell{ name = 'Available Heroes', content = {_args.heroes}},
	}
end

function CustomMission._getEvolution()
	local evolution = _args.Evolution
	if String.isEmpty(evolution) then
		return nil
	elseif evolution == 'None' then
		return evolution
	else
		return '[[' .. evolution .. ' (Heart of the Swarm Campaign)|' .. evolution .. ']]'
	end
end

function CustomInjector:parse(id, widgets)
	if id == 'header' then
		--fallback for non main space
		_fullGameName = _fullGameName or _GAME_SWITCH[_args.game] or 'Wings of Liberty'

		return {
			Header{
				name = _fullGameName,
				subHeader = _args.name,
				image = _args.image,
				imageDark = _args.imagedark or _args.imagedarkmode
			}
		}
	end
	return widgets
end

function CustomMission.getWikiCategories()
	_fullGameName = _GAME_SWITCH[_args.game] or 'Wings of Liberty'
	return {
		_fullGameName .. ' Missions',
		_fullGameName .. ' Campaign',
	}
end

function CustomMission:createWidgetInjector()
	return CustomInjector()
end

return CustomMission
