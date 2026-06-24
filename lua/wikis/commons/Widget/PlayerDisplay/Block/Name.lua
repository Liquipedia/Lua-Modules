---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Block/Name
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DisplayUtil = Lua.import('Module:DisplayUtil')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local PagePreview = Lua.import('Module:PagePreview')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

local ZERO_WIDTH_SPACE = '&#8203;'

---@param props {player: standardPlayer, showLink: boolean?, dq: boolean?,
---overflow: OverflowModes?, useDefault: boolean?}
---@return VNode?
local function BlockPlayerName(props)
	local player = props.player
	local isLinked = not Opponent.playerIsTbd(player) and Logic.readBool(props.showLink)
		and Logic.isNotEmpty(player.pageName)

	---@return Renderable
	local function getChildren()
		if isLinked then
			return Link{link = player.pageName, children = player.displayName}
		elseif props.useDefault then
			return Logic.emptyOr(player.displayName, 'TBD') --[[@as string]]
		end
		return ZERO_WIDTH_SPACE
	end

	if isLinked then
		PagePreview.register(player.pageName)
	end

	return (props.dq and Html.S or Html.Span){
		classes = {'name', isLinked and 'link-preview' or nil},
		attributes = isLinked and {['data-preview-page'] = PagePreview.key(player.pageName)} or nil,
		css = DisplayUtil.getOverflowStyles(props.overflow or 'ellipsis'),
		children = getChildren(),
	}
end

return Component.component(BlockPlayerName, {showLink = true})
