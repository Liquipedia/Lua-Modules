---
-- @Liquipedia
-- page=Module:Standings/Documentation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')

local StandingsParameters = Lua.import('Module:Standings/Parameters')

local DocumentationParameters = Lua.import('Module:Widget/Documentation/Parameters')

local StandingsDocumentation = {}

local SECTIONS = {header = true, round = true, opponent = true}

---Lists the parameters of a section of a standings template.
---{{#invoke:Lua|invoke|module=Standings/Documentation|fn=parameters|tabletype=swiss|section=header}}
---@param frame Frame
---@return Renderable?
function StandingsDocumentation.parameters(frame)
	local args = Arguments.getArgs(frame)
	assert(SECTIONS[args.section], 'Unknown section "' .. tostring(args.section) .. '"')
	return DocumentationParameters{
		parameters = StandingsParameters[args.section],
		context = {tableType = args.tabletype},
	}
end

return StandingsDocumentation
