---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/Wrapper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Button = Lua.import('Module:Widget/Basic/Button')
local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local SeedingList = Lua.import('Module:Features/ParticipantTable/Components/SeedList')

---@param props {displayComponent: Component, config: ParticipantTableConfig, sections: ParticipantTableSection[],
---hasSeed: boolean?, factionColumns?: string[], factionNumbers?: table<string, integer>}
---@return VNode[]
local function ParticipantTableWrapper(props)
	---@type VNode
	local participantTable = props.displayComponent(props)

	if not props.hasSeed then
		return participantTable
	end

	---@param buttonArea integer
	---@param toggleArea integer
	---@param text string
	---@return VNode<ButtonWidgetProps>
	local makebutton = function(buttonArea, toggleArea, text)
		return Button{
			size = 'sm',
			classes = {'toggle-area-button'},
			css = {['margin-bottom'] = '0.5rem'},
			attributes = {
				['data-toggle-area-btn'] = buttonArea,
				['data-toggle-area-content'] = toggleArea,
			},
			children = text,
		}
	end

	return Html.Div{
		classes = {'table-responsive', 'toggle-area toggle-area-1'},
		attributes = {['data-toggle-area'] = 1},
		children = {
			makebutton(1, 2, 'Show Participants'),
			makebutton(2, 1, 'Show Seedings'),
			participantTable,
			SeedingList(props)
		},
	}
end

return Component.component(ParticipantTableWrapper)
