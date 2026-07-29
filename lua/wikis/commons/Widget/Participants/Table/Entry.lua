---
-- @Liquipedia
-- page=Module:Widget/Participants/Table/Entry
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Table = Lua.import('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class ParticipantsTableEntryProps
---@field opponent standardOpponent
---@field note string?
---@field dq boolean?
---@field config ParticipantTableConfig
---@field additionalProps table?

---@param props ParticipantsTableEntryProps
---@return VNode
local function ParticipantsTableEntry(props)
	---@type HtmlNodeProps
	local entryProps = {
		classes = {'participantTable-entry'},
		css = {width = props.config.columnWidth},
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
