---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Section = Lua.import('Module:Features/ParticipantTable/Components/Section')
local Title = Lua.import('Module:Features/ParticipantTable/Components/Title')

---@param props {hasSeed: boolean?, config: ParticipantTableConfig, sections: ParticipantTableSection[]}
---@return VNode
local function ParticipantTableTable(props)
	return Html.Div{
		classes = {'participantTable'},
		css = Table.merge({width = props.config.width}, props.hasSeed and {
			['max-width'] = '100%!important',
			['vertical-align'] = 'middle',
		} or nil),
		attributes = props.hasSeed and {['data-toggle-area-content'] = 1} or nil,
		children = WidgetUtil.collect(
			(props.hasSeed or props.config.showTitle) and Title{
				titleText = props.config.title or 'Participants',
				buttonText = 'Seeding',
				buttonArea = 2,
				hasSeed = props.hasSeed,
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
