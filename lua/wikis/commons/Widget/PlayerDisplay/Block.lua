---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Block
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DisplayUtil = Lua.import('Module:DisplayUtil')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local BasePlayerDisplay = Lua.import('Module:Widget/PlayerDisplay/Base')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TeamPartWidget = Lua.import('Module:Widget/TeamDisplay/Part')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Span = HtmlWidgets.Span
local WidgetUtil = Lua.import('Module:Widget/Util')

local ZERO_WIDTH_SPACE = '&#8203;'

---@class BlockPlayerProps: BasePlayerDisplayProps
---@field playerClass string|string[]?
---@field overflow OverflowModes?
---@field showPlayerTeam boolean?
---@field note string|number|nil
---@field team string?

---@class BlockPlayerWidget: BasePlayerDisplayWidget
---@operator call(BlockPlayerProps): BlockPlayerWidget
---@field props BlockPlayerProps
local BlockPlayerWidget = Class.new(BasePlayerDisplay)

---@return Widget
function BlockPlayerWidget:render()
	local props = self.props
	local factionDisplay = self:getFaction()
	return Div{
		classes = Array.extend(
			'block-player',
			self.props.flip and 'flipped' or nil,
			self.props.showPlayerTeam and 'has-team' or nil,
			self.props.playerClass
		),
		css = {['white-space'] = 'pre'},
		children = WidgetUtil.collect(
			self:getFlag(),
			factionDisplay and Span{
				classes = {'race'},
				children = factionDisplay
			} or nil,
			self:getName(),
			Logic.isNotEmpty(props.note) and HtmlWidgets.Sup{children = props.note} or nil,
			self:getTeam()
		)
	}
end

---@protected
---@return Widget
function BlockPlayerWidget:getName()
	local player = self.player
	local props = self.props

	---@return string|Widget
	local function getChildren()
		if not Opponent.playerIsTbd(player) and Logic.nilOr(
			Logic.readBoolOrNil(props.showLink), true
		) and Logic.isNotEmpty(player.pageName) then
			return Link{link = player.pageName, children = player.displayName}
		elseif self.useDefault then
			return Logic.emptyOr(player.displayName, 'TBD') --[[@as string]]
		end
		return ZERO_WIDTH_SPACE
	end

	return (props.dq and HtmlWidgets.S or Span){
		classes = {'name'},
		css = DisplayUtil.getOverflowStyles(props.overflow or 'ellipsis'),
		children = getChildren(),
	}
end

---@protected
---@return (string|Widget)[]?
function BlockPlayerWidget:getTeam()
	local team = self.player.team
	local props = self.props

	if not Logic.readBool(props.showPlayerTeam) then
		return
	elseif Logic.isEmpty(team) then
		return
	end
	---@cast team -nil
	if team:lower() == 'tbd' then
		return
	end
	return {
		'&nbsp;',
		TeamPartWidget{name = team}
	}
end

return BlockPlayerWidget
