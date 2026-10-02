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
local WidgetUtil = Lua.import('Module:Widget/Util')

local Entry = Lua.import('Module:Features/ParticipantTable/Components/Entry')
local SectionTitle = Lua.import('Module:Features/ParticipantTable/Components/SectionTitle')

---@param children Renderable|Renderable[]
---@return VNode
local makeRow = function(children)
	return Html.Div{classes = {'participantTable-row'}, children = children}
end

---@param props {config: StarcraftParticipantTableConfig, section: StarcraftParticipantTableSection,
---factionColumns: string[]}
---@return VNode[]
local function ParticipantTableFactionSection(props)
	local section = props.section

	local sectionTitleRow = makeRow(SectionTitle{
		tableConfig = props.config,
		sectionConfig = section.config,
		numEntries = #Array.filter(section.entries, function(entry)
			return not entry.dq
		end),
	})

	if Logic.isEmpty(section.entries) then
		return {
			sectionTitleRow,
			makeRow(Html.Div{
				classes = {'participantTable-tbd'},
				children = 'To be determined',
			})
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
			return Html.Div{classes = {'participantTable-entry'}}
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
		sectionTitleRow,
		Array.mapRange(1, maxFactionLength, function(rowIndex)
			return makeRow(Array.map(props.factionColumns, FnUtil.curry(entryCell, rowIndex)))
		end)
	)
end

return Component.component(ParticipantTableFactionSection)
