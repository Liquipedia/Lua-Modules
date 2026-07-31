---
-- @Liquipedia
-- page=Module:Widget/Customizable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local String = Lua.import('Module:StringUtils')

local Component = Lua.import('Module:Widget/Component')
local Context = Lua.import('Module:Widget/ComponentContext')
local CustomizableContext = Lua.import('Module:Widget/Contexts/Customizable')

---@param props {id: string, children: Renderable[]}
---@param context Context
---@return Renderable[]?
local function Customizable(props, context)
	assert(String.isNotEmpty(props.id), 'CustomizableWidget: id must be a nonempty string')
	local injector = Context.read(context, CustomizableContext.Customizable)
	if injector == nil then
		return props.children
	end
	return injector:parse(props.id, props.children)
end

return Component.component(Customizable)
