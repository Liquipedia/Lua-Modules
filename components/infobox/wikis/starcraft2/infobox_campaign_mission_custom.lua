---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/CampaignMission/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Game = require('Module:Game')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Mission = Lua.import('Module:Infobox/CampaignMission', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header

---@class CustomMissionInfobox: BuildingInfobox
local CustomMission = Class.new()

local CustomInjector = Class.new(Injector)

local _args

local NONE = 'None'

--those are only needed for this module nowhere else
local ADDITIONAL_GAME_NAMES = {
	nco = 'Nova Covert Ops',
	coop = 'Co-op Mission',
}

---@param frame Frame
---@return Html
function CustomMission.run(frame)
	local mission = Mission(frame)
	_args = mission.args
	mission.createWidgetInjector = CustomMission.createWidgetInjector
	mission.getWikiCategories = CustomMission.getWikiCategories
	return mission:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
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

---@return string?
function CustomMission._getEvolution()
	local evolution = _args.Evolution
	if String.isEmpty(evolution) then
		return nil
	elseif evolution == NONE then
		return evolution
	else
		return '[[' .. evolution .. ' (Heart of the Swarm Campaign)|' .. evolution .. ']]'
	end
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'header' then
		local game = ADDITIONAL_GAME_NAMES[_args.game] or Game.name{game = _args.game, useDefault = true}

		return {
			Header{
				name = game,
				subHeader = _args.name,
				image = _args.image,
				imageDark = _args.imagedark or _args.imagedarkmode
			}
		}
	end
	return widgets
end

---@param args table
---@return table
function CustomMission:getWikiCategories(args)
	local game = ADDITIONAL_GAME_NAMES[args.game] or Game.name{game = args.game, useDefault = true}
	return {
		game .. ' Missions',
		game .. ' Campaign',
	}
end

---@return WidgetInjector
function CustomMission:createWidgetInjector()
	return CustomInjector()
end

return CustomMission
