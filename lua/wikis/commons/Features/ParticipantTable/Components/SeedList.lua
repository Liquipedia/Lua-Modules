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

local Entry = Lua.import('Module:Features/ParticipantTable/Components/Entry')

---@param props {hasSeed: boolean?, config: ParticipantTableConfig, sections: ParticipantTableSection[]}
---@return VNode[]
local function ParticipantTableSeedList(props)
	local width = tostring(50 + (props.config.showTeams and 242 or 186)) .. 'px'

	local entries = Array.sortBy(
		Array.filter(Array.flatMap(props.sections, function(section)
			return section.entries
		end), Logic.isNotEmpty),
		Operator.property('seed'),
		function (a, b)
			return a and b and a < b or false
		end
	)

	local display = Html.Div{
		classes = {'participantTable-seeding'},
		children = Array.flatMap(entries, function(entry)
			return {
				Html.Div{
					classes = {'participantTable-seed'},
					children = entry.seed
				},
				Entry{
					config = props.config,
					dq = entry.dq,
					note = entry.note,
					opponent = entry.opponent,
					additionalProps = {oneLine = true},
				}
			}
		end)
	}

	return Html.Div{
		classes = {'participantTable'},
		attributes = {['data-toggle-area-content'] = 2},
		css = {
			width = width,
			['vertical-align'] = 'middle',
			['max-width'] = '100%!important',
		},
		children = {
			Html.Div{
				classes = {'participantTable-title'},
				children = 'Seeding',
			},
			display,
		}
	}
end

return Component.component(ParticipantTableSeedList)
