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
local Link = Lua.import('Module:Widget/Basic/Link')
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

---@param prefix string
---@param items Renderable[]
---@return Renderable
local function Enumeration(prefix, items)
	return Html.Dd{children = Array.flatten{prefix, Array.interleave(items, ', '), '.'}}
end

---The values of an `enum`, or the templates whose output a `json` takes.
---@param parameter ArgSchemaParameter
---@return Renderable?
local function AcceptedValues(parameter)
	if parameter.values then
		return Enumeration('One of ', Array.map(parameter.values, function(value)
			return Html.Code{children = value}
		end))
	elseif parameter.templates then
		return Enumeration('Takes ', Array.map(parameter.templates, function(template)
			return Link{
				link = 'Template:' .. template,
				children = Html.Code{children = mw.text.nowiki('{{' .. template .. '}}')},
			}
		end))
	end
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
			AcceptedValues(parameter),
		}
	end)}
end

return Component.component(DocumentationParameters)
