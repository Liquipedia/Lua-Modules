---
-- @Liquipedia
-- page=Module:ArgSchema/Documentation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')

local DocumentationParameters = Lua.import('Module:Widget/Documentation/Parameters')

local ArgSchemaDocumentation = {}

---Lists the parameters a module declares, see Module:ArgSchema. The other args are the context of the documentation.
---{{#invoke:Lua|invoke|module=ArgSchema/Documentation|fn=parameters|schema=Standings/Parameters|section=header}}
---@param frame Frame
---@return Renderable?
function ArgSchemaDocumentation.parameters(frame)
	local args = Arguments.getArgs(frame)
	assert(args.schema, 'No schema given')
	-- The field of the module that holds the parameters
	local section = args.section or 'parameters'
	local parameters = Lua.import('Module:' .. args.schema)[section]
	assert(type(parameters) == 'table', 'Module:' .. args.schema .. ' declares no parameters "' .. section .. '"')
	return DocumentationParameters{parameters = parameters, context = args}
end

return ArgSchemaDocumentation
