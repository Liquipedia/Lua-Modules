---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/Section
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local Entry = Lua.import('Module:Features/ParticipantTable/Components/Entry')
local SectionTitle = Lua.import('Module:Features/ParticipantTable/Components/SectionTitle')

---@param children Renderable|Renderable[]
---@return VNode
local makeRow = function(children)
	return Html.Div{classes = {'participantTable-row'}, children = children}
end

---@param props {config: ParticipantTableConfig, section: ParticipantTableSection, entries: ParticipantTableEntry[]}
---@return VNode[]
local function render(props)
	local section = props.section
	local entries = props.entries
	local sectionEntryCount = #Array.filter(entries, function(entry) return not entry.dq end)

	local sectionTitleRow = makeRow(SectionTitle{
		tableConfig = props.config,
		sectionConfig = section.config,
		numEntries = sectionEntryCount,
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

	local entriesDisplay = Array.map(entries, function(entry)
		return Entry{
			config = props.config,
			dq = entry.dq,
			note = entry.note,
			opponent = entry.opponent,
			additionalProps = {oneLine = true},
			useDefaultWidth = true,
		}
	end)

	local tbdsToAdd = (not section.config.count) and 0
		or (section.config.count - sectionEntryCount)
	if tbdsToAdd > 0 then
		Array.extendWith(entriesDisplay, Array.rep(Entry{
			config = props.config,
			opponent = Opponent.tbd(),
			useDefaultWidth = true,
		}, tbdsToAdd))
	end

	local currentColumn = (#entries + tbdsToAdd) % props.config.colSpan
	if currentColumn ~= 0 then
		Array.extendWith(entriesDisplay, Array.mapRange(currentColumn + 1, props.config.colSpan, function()
			return Html.Div{classes = {'participantTable-entry', 'participantTable-empty'}}
		end))
	end

	return {
		sectionTitleRow,
		makeRow(entriesDisplay)
	}
end

return Component.component(render)
