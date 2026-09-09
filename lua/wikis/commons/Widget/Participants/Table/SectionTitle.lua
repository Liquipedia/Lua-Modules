---
-- @Liquipedia
-- page=Module:Widget/Participants/Table/SectionTitle
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local String = Lua.import('Module:StringUtils')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {tableConfig: ParticipantTableConfig, sectionConfig: ParticipantTableConfig, numEntries: integer}
---@return VNode?
local function ParticipantsTableSectionTitle(props)
	local tableConfig = props.tableConfig
	local sectionConfig = props.sectionConfig

	if String.isEmpty(sectionConfig.title) or sectionConfig.title == tableConfig.title then
		return
	end

	return Html.Div{
		classes = {'participantTable-title'},
		children = {
			sectionConfig.title,
			sectionConfig.showCountBySection and Html.I{
				children = {
					' (',
					(sectionConfig.count or props.numEntries),
					')'
				}
			} or nil
		}
	}
end

return Component.component(ParticipantsTableSectionTitle)
