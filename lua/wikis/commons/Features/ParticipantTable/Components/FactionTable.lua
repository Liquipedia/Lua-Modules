---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/FactionTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Header = Lua.import('Module:Features/ParticipantTable/Components/FactionHeader')
local Section = Lua.import('Module:Features/ParticipantTable/Components/FactionSection')

---@param props {config: StarcraftParticipantTableConfig, factionColumns: string[],
---factionNumbers: table<string, integer>, sections: StarcraftParticipantTableSection[]}
---@return VNode
local function render(props)
	local config = props.config
	local colSpan = #props.factionColumns

	local display = Html.Div{
		classes = {'participantTable', 'participantTable-faction'},
		css = {
			['grid-template-columns'] = 'repeat(' .. colSpan .. ', 1fr)',
			width = (colSpan * config.soloColumnWidth) .. 'px',
		},
		children = WidgetUtil.collect(
			Header{
				config = config,
				factionColumns = props.factionColumns,
				factionNumbers = props.factionNumbers,
			},
			Array.map(props.sections, function(section)
				return Section{
					config = config,
					section = section,
					factionColumns = props.factionColumns,
				}
			end)
		)
	}

	return Html.Div{
		classes = {'table-responsive'},
		children = display,
	}
end

return Component.component(render)
