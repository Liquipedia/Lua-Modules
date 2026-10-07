---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/FactionSection
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Entry = Lua.import('Module:Features/ParticipantTable/Components/Entry')

---@param props {config: ParticipantTableConfig, section: ParticipantTableSection,
---factionColumns: string[]}
---@return VNode[]
local function ParticipantTableFactionSection(props)
	local section = props.section

	---@return VNode<Table2RowProps>?
	local makeSectionTitleRow = function()
		local sectionConfig = section.config
		if Logic.isEmpty(sectionConfig.title) then
			return
		end

		local makeCount = function()
			return #Array.filter(section.entries, function(entry)
				return not entry.dq
			end)
		end

		return TableWidgets.Row{children = TableWidgets.CellHeader{
			attributes = {colspan = #props.factionColumns},
			children = {
				sectionConfig.title,
				sectionConfig.showCountBySection and Html.I{
					children = {
						' (',
						sectionConfig.count or makeCount(),
						')'
					}
				} or nil
			},
		}}
	end

	if Logic.isEmpty(section.entries) then
		return {
			makeSectionTitleRow(),
			TableWidgets.Row{children = TableWidgets.Cell{
				attributes = {colspan = #props.factionColumns},
				children = 'To be determined',
			}}
		}
	end

	-- Group entries by faction
	local _, byFaction = Array.groupBy(section.entries, function(entry) return entry.opponent.players[1].faction end)

	-- Find the faction with the most players
	local maxFactionLength = Array.max(
		Array.map(props.factionColumns, function(faction) return #(byFaction[faction] or {}) end)
	) or 0

	---@param rowIndex integer
	---@param faction string
	---@return VNode
	local entryCell = function(rowIndex, faction)
		local entry = byFaction[faction] and byFaction[faction][rowIndex]
		if not entry then
			return TableWidgets.Cell{}
		end
		return Entry{
			config = props.config,
			dq = entry.dq,
			note = entry.note,
			opponent = entry.opponent,
			additionalProps = {showFaction = false},
		}
	end

	return WidgetUtil.collect(
		makeSectionTitleRow(),
		Array.mapRange(1, maxFactionLength, function(rowIndex)
			return TableWidgets.Row{children = Array.map(props.factionColumns, FnUtil.curry(entryCell, rowIndex))}
		end)
	)
end

return Component.component(ParticipantTableFactionSection)
