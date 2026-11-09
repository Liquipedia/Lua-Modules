---
-- @Liquipedia
-- page=Module:Widget/Documentation/Parameters
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local ArgSchema = Lua.import('Module:ArgSchema')
local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Para = Lua.import('Module:Widget/Documentation/Para')

---@param parameter ArgSchemaParameter
---@return Renderable[]
local function ParameterNames(parameter)
	if ArgSchema.isUnnamed(parameter) then
		return {Para{value = parameter.example}}
	end
	local value = Logic.nilOr(parameter.default, parameter.example)
	local names = Array.map(ArgSchema.displayNames(parameter), function(variants)
		local paras = Array.map(variants, function(variant, index)
			if index > 1 then
				return Para{name = variant}
			end
			return Para{name = variant, value = value}
		end)
		if #variants > 1 then
			table.insert(paras, '…')
		end
		return Array.interleave(paras, ', ')
	end)
	return Array.flatten(Array.interleave(names, {', '}))
end

---Lists the parameters that apply in a context, with their descriptions.
---@param props {parameters: ArgSchemaParameter[], context: table}
---@return Renderable?
local function DocumentationParameters(props)
	local parameters = ArgSchema.applicable(props.parameters, props.context)
	if #parameters == 0 then
		return
	end
	local frame = mw.getCurrentFrame()
	return Html.Dl{children = Array.flatMap(parameters, function(parameter)
		return {
			Html.Dt{children = ParameterNames(parameter)},
			Html.Dd{children = {
				-- Descriptions use templates such as {{para}}, which the output of a module does not expand
				frame:preprocess(ArgSchema.description(parameter, props.context)),
			}},
		}
	end)}
end

return Component.component(DocumentationParameters)
