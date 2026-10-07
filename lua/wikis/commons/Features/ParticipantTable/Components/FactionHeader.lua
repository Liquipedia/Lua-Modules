---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/FactionHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Faction = Lua.import('Module:Faction')

local Component = Lua.import('Module:Widget/Component')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param props {config: ParticipantTableConfig, factionColumns: string[],
---factionNumbers: table<string, number>}
---@return VNode
local function ParticipantTableFactionHeader(props)
	local config = props.config

	local makeFactionHeaderCell = function(faction)
		local parts = WidgetUtil.collect(
			config.isRandomEvent and Faction.Icon{faction = 'r'} or nil,
			faction ~= Faction.defaultFaction and Faction.Icon{faction = faction} or nil,
			' ',
			Faction.toName(faction),
			config.isRandomEvent and ' Main' or nil,
			config.showCountByFaction and " ''(" .. props.factionNumbers[faction .. 'Display'] .. ")''" or nil
		)

		return TableWidgets.CellHeader{
			classes = {Faction.bgClass(faction)},
			css = {width = config.factionColumnWidth},
			children = parts,
		}
	end

	return TableWidgets.Row{children =  Array.map(props.factionColumns, makeFactionHeaderCell)}
end

return Component.component(ParticipantTableFactionHeader)
