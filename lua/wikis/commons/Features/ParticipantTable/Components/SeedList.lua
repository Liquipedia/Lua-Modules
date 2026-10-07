---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/SeedList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local Entry = Lua.import('Module:Features/ParticipantTable/Components/Entry')

---@param props {config: ParticipantTableConfig, sections: ParticipantTableSection[]}
---@return VNode[]
local function ParticipantTableSeedList(props)
	local width = tostring(50 + (props.config.showTeams and 242 or 186)) .. 'px'

	---@type ParticipantTableEntry[]
	local entries = Array.sortBy(
		Array.filter(Array.flatMap(props.sections, function(section)
			return section.entries
		end), Logic.isNotEmpty),
		Operator.property('seed'),
		function (a, b)
			return a and b and a < b or false
		end
	)

	local display = TableWidgets.Table{
		css = {
			width = width,
			['max-width'] = '100%!important',
		},
		children = {
			TableWidgets.TableHeader{children = {
				TableWidgets.Row{children = {
					TableWidgets.CellHeader{
						attributes = {colspan = 2},
						children = 'Seeding',
					}
				}},
			}},
			TableWidgets.TableBody{children = Array.map(entries, function(entry)
				return TableWidgets.Row{children = {
					TableWidgets.Cell{
						css = {width = '50px'},
						children = entry.seed,
					},
					Entry{
						config = props.config,
						dq = entry.dq,
						note = entry.note,
						opponent = entry.opponent,
						additionalProps = {oneLine = true},
					},
				}}
			end)}
		}
	}

	return Html.Div{
		classes = {'participantTable'},
		attributes = {['data-toggle-area-content'] = 2},
		css = {
			width = width,
			['vertical-align'] = 'middle',
			['max-width'] = '100%!important',
		},
		children = display,
	}
end

return Component.component(ParticipantTableSeedList)
