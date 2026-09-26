---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Section = Lua.import('Module:Features/ParticipantTable/Components/Section')

---@param props {hasSeed: boolean?, config: ParticipantTableConfig, sections: ParticipantTableSection[]}
---@return VNode
local function ParticipantTableTable(props)
	local titleText = props.config.showTitle and (props.config.title or 'Participants') or nil

	return Html.Div{
		classes = {'participantTable'},
		css = {width = props.config.width},
		attributes = props.hasSeed and {['data-toggle-area-content'] = 1} or nil,
		children = WidgetUtil.collect(
			titleText and Html.Div{
				classes = {'participantTable-title'},
				children = titleText,
			} or nil,
			Array.map(props.sections, function(section)
				return Section{
					config = props.config,
					section = section,
				}
			end)
		)
	}
end

return Component.component(ParticipantTableTable)
