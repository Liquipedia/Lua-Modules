---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/FactionTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Header = Lua.import('Module:Features/ParticipantTable/Components/FactionHeader')
local Section = Lua.import('Module:Features/ParticipantTable/Components/FactionSection')

---@param props {config: ParticipantTableConfig, factionColumns: string[],
---factionNumbers: table<string, integer>, sections: ParticipantTableSection[], hasSeed: boolean?}
---@return VNode
local function ParticipantTableFactionTable(props)
	return TableWidgets.Table{
		attributes = props.hasSeed and {['data-toggle-area-content'] = 1} or nil,
		columns = Array.rep({width = props.config.factionColumnWidth}, #props.factionColumns),
		children = {
			Header{
				config = props.config,
				factionColumns = props.factionColumns,
				factionNumbers = props.factionNumbers,
			},
			TableWidgets.TableBody{
				children = Array.flatMap(props.sections, function(section)
					return Section{
						config = props.config,
						section = section,
						factionColumns = props.factionColumns,
					}
				end),
			},
		}
	}
end

return Component.component(ParticipantTableFactionTable)
