---
-- @Liquipedia
-- page=Module:Widget/Standings/Cells
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Label = Lua.import('Module:Widget/Basic/Label')
local Participant = Lua.import('Module:Widget/Standings/Participant')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

---The cells shared by the standings displays: rank, participant and the stats columns.
local StandingsCells = {}

---@param text string?
---@return Renderable
function StandingsCells.header(text)
	return TableWidgets.CellHeader{children = text}
end

---@param statsToShow {id: string, title: string?}[]
---@return table[]
function StandingsCells.statColumns(statsToShow)
	return Array.map(statsToShow, function()
		return {align = 'center'}
	end)
end

---@param statsToShow {id: string, title: string?}[]
---@return Renderable[]
function StandingsCells.statHeaders(statsToShow)
	return Array.map(statsToShow, function(stat)
		return StandingsCells.header(stat.title)
	end)
end

---@param slot StandingsEntryModel
---@return Renderable
function StandingsCells.placement(slot)
	return TableWidgets.Cell{children = Label{
		children = slot.placement,
		attributes = {['data-placement-type'] = Logic.nilIfEmpty(slot.definitiveStatus)},
		labelScheme = 'placement',
	}}
end

---@param slot StandingsEntryModel
---@return Renderable
function StandingsCells.participant(slot)
	return TableWidgets.Cell{children = Participant{opponent = slot.opponent, disqualified = slot.disqualified}}
end

---@param slot StandingsEntryModel
---@param statsToShow {id: string, title: string?}[]
---@return Renderable[]
function StandingsCells.stats(slot, statsToShow)
	return Array.map(statsToShow, function(stat, statIndex)
		local statValue = slot.additionalStatsValues[stat.id]
		return TableWidgets.Cell{
			css = {['font-weight'] = statIndex == 1 and 'bold' or nil},
			children = statValue and statValue.display or '',
		}
	end)
end

return StandingsCells
