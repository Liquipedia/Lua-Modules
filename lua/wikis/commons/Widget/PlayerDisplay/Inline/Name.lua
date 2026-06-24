---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Inline/Name
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local PagePreview = Lua.import('Module:PagePreview')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

---@param props {player: standardPlayer, showLink: boolean?, dq: boolean?}
---@return Renderable?
local function InlinePlayerName(props)
	local player = props.player
	local isLinked = Logic.readBool(props.showLink) and Logic.isNotEmpty(player.pageName)
	local name = player.displayName
	if isLinked then
		PagePreview.register(player.pageName)
		-- the marker sits on a wrapper span rather than the link itself, since
		-- Link emits raw `[[...]]` wikitext that carries no attributes
		name = Html.Span{
			classes = {'link-preview'},
			attributes = {['data-preview-page'] = PagePreview.key(player.pageName)},
			children = Link{link = player.pageName, children = player.displayName},
		}
	end
	if props.dq then
		return Html.S{children = name}
	end
	return name
end

return Component.component(InlinePlayerName, {showLink = true})
