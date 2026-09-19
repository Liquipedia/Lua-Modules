---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/Wrapper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local SeedingList = Lua.import('Module:Features/ParticipantTable/Components/SeedList')
local ParticipantTable = Lua.import('Module:Features/ParticipantTable/Components/Table')

---@param props {hasSeed: boolean?, config: ParticipantTableConfig, sections: ParticipantTableSection[]}
---@return VNode
local function render(props)
	local participantTable = ParticipantTable(props)

	if not props.hasSeed then
		return participantTable
	end

	return Html.Div{
		classes = {'table-responsive', 'toggle-area toggle-area-1'},
		attributes = {['data-toggle-area'] = 1},
		children = {
			participantTable,
			SeedingList(props)
		},
	}
end

return Component.component(render)
