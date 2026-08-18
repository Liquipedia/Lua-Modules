---
-- @Liquipedia
-- page=Module:Widget/ReferenceTag
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Renderer = Lua.import('Module:Widget/Renderer')

--[[
Widget component that is roughly equivalent to <ref> tags in MediaWiki.

For example, the following Lua code snippet:

```lua
ReferenceTag{
	name = 'Hello World',
	children = {
		'Lorem ipsum ',
		'dolor sit amet'
	}
}
```

is roughly equivalent to the following wikicode snippet:

```html
<ref name="Hello World">Lorem ipsum dolor sit amet</ref>
```
]]
---@param props {frame: Frame?, name: string?, group: string?, children: Renderable|Renderable[]?}
---@param context Context?
---@return string
local function ReferenceTag(props, context)
	local frame = props.frame or mw.getCurrentFrame()
	return frame:extensionTag(
		'ref',
		--[[
		Because Frame:extensionTag expects string argument for content, we cannot directly
		pass children in its raw form. Thus, we manually call Renderer.render here instead
		of letting it be called after processing the parent component.
		]]
		Renderer.render(props.children, context),
		{
			name = props.name,
			group = props.group
		}
	)
end

return Component.component(ReferenceTag)
