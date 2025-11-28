---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Inline
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Span = HtmlWidgets.Span
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class InlinePlayerWidget: Widget
---@operator call(InlinePlayerProps): InlinePlayerWidget
---@field player standardPlayer
---@field props InlinePlayerProps
---@field teamTemplate teamTemplateData
---@field flip boolean
---@field displayType InlineType
---@field private useDefault boolean
local InlinePlayerWidget = Class.new(Widget,
	---@param self self
	---@param input InlinePlayerProps
	function (self, input)
		if Logic.isEmpty(input.player) then
			input.player = Opponent.readSinglePlayerArgs(input)
		end
		self.player = PlayerExt.syncPlayer(input.player)
		self.useDefault = Logic.nilOr(Logic.readBoolOrNil(input.showTbd), true) or not Opponent.playerIsTbd(self.player)
	end
)

---@return Widget
function InlinePlayerWidget:render()
	local children = WidgetUtil.collect(
		self:_getFlag(),
		self:_getFaction(),
		self:_getName()
	)
	return Span{
		classes = {
			'inline-player',
			self.props.flip and 'flipped' or nil,
		},
		css = {['white-space'] = 'pre'},
		children = Array.interleave(
			self.props.flip and Array.reverse(children) or children,
			'&nbsp;'
		)
	}
end

---@private
---@return string?
function InlinePlayerWidget:_getFlag()
	if not Logic.nilOr(Logic.readBoolOrNil(self.props.showFlag), true) then
		return
	end
	local flag = self.player.flag
	if Logic.isEmpty(flag) and self.useDefault then
		flag = 'unknown'
	end
	return Flags.Icon{flag = flag, shouldLink = false}
end

---@private
---@return string?
function InlinePlayerWidget:_getFaction()
	if not Logic.nilOr(Logic.readBoolOrNil(self.props.showFaction), true) then
		return
	elseif Logic.isEmpty(self.player.faction) then
		return
	elseif self.player.faction == Faction.defaultFaction then
		return
	end
	return Faction.Icon{size = 'small', showLink = false, faction = self.player.faction, game = self.props.game}
end

---@private
---@return string|Widget?
function InlinePlayerWidget:_getName()
	local player = self.player
	local name = self.props.showLink and Link{
		link = player.pageName, children = player.displayName
	} or player.displayName
	if self.props.dq then
		return HtmlWidgets.S{children = name}
	end
	return name
end

return InlinePlayerWidget
