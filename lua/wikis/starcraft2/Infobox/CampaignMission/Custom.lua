---
-- @Liquipedia
-- page=Module:Infobox/CampaignMission/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Game = require('Module:Game')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Mission = Lua.import('Module:Infobox/CampaignMission')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header

---@class Starcraft2CampaignMissionInfobox: CampaignMissionInfobox
local CustomMission = Class.new(Mission)

local CustomInjector = Class.new(Injector)

local NONE = 'None'

--those are only needed for this module nowhere else
local ADDITIONAL_GAME_NAMES = {
	nco = 'Nova Covert Ops',
	coop = 'Co-op Mission',
}

---@param frame Frame
---@return Html
function CustomMission.run(frame)
	local mission = CustomMission(frame)
	mission:setWidgetInjector(CustomInjector(mission))

	return mission:createInfobox()
end

---@return string?
function CustomMission:_getEvolution()
	local evolution = self.args.Evolution
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
	local args = self.caller.args

	if id == 'header' then
		local game = ADDITIONAL_GAME_NAMES[args.game] or Game.name{game = args.game, useDefault = true}

		return {
			Header{
				name = game,
				subHeader = args.name,
				image = args.image,
				imageDark = args.imagedark or args.imagedarkmode
			}
		}
	elseif id == 'custom' then
		return {
			Cell{ name = 'Credits Earned', content = {args.credits}},
			Cell{ name = 'Research Points', content = {args.research}},
			Cell{ name = 'Kerrigan Levels', content = {args.Kerrigan}},
			Cell{ name = 'Evolution Unlock', content = {self.caller:_getEvolution()}},
			Cell{ name = 'New Units', content = {args.units}},
			Cell{ name = 'Available Heroes', content = {args.heroes}},
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

return CustomMission
