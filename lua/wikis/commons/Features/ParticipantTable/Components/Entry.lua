---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/Entry
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Table = Lua.import('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props ParticipantsTableEntryProps
---@return VNode
local function ParticipantsTableEntry(props)
	---@type HtmlNodeProps
	local entryProps = {
		classes = {'participantTable-entry'},
		css = props.useDefaultWidth and {width = props.config.columnWidth} or nil,
		children = OpponentDisplay.BlockOpponent(Table.merge(
			{
				dq = props.dq,
				note = props.note,
				showPlayerTeam = props.config.showTeams,
				opponent = props.opponent,
			},
			props.additionalProps
		))
	}

	return Html.Div(DisplayHelper.addOpponentHighlightToProps(entryProps, props.opponent))
end

return Component.component(ParticipantsTableEntry)
