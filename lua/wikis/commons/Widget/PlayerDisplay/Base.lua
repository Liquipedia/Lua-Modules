---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class BasePlayerDisplayProps: PlayerExtSyncOptions
---@field flip boolean?
---@field player standardPlayer?
---@field showFlag boolean?
---@field showLink boolean?
---@field dq boolean?
---@field showFaction boolean?
---@field game string?
---@field showTbd boolean?

---@class BasePlayerDisplayWidget: Widget
---@operator call(BasePlayerDisplayProps): BasePlayerDisplayWidget
---@field protected player standardPlayer
---@field props BasePlayerDisplayProps
---@field protected useDefault boolean
local BasePlayerDisplayWidget = Class.new(Widget,
	---@param self self
	---@param input BasePlayerDisplayProps
	function (self, input)
		if Logic.isEmpty(input.player) then
			local parsedPlayer = Opponent.readSinglePlayerArgs(input)
			self.player = PlayerExt.syncPlayer(parsedPlayer, input)
		else
			self.player = input.player
		end
		self.useDefault = Logic.nilOr(Logic.readBoolOrNil(input.showTbd), true) or not Opponent.playerIsTbd(self.player)
	end
)

---@return Widget
function BasePlayerDisplayWidget:render()
	error('BasePlayerDisplayWidget:render() cannot be called directly and must be overridden.')
end

---@orotected
---@return string?
function BasePlayerDisplayWidget:getFlag()
	if not Logic.nilOr(Logic.readBoolOrNil(self.props.showFlag), true) then
		return
	end
	local flag = self.player.flag
	if Logic.isEmpty(flag) and self.useDefault then
		flag = 'unknown'
	end
	return Flags.Icon{flag = flag, shouldLink = false}
end

---@orotected
---@return string?
function BasePlayerDisplayWidget:getFaction()
	if not Logic.nilOr(Logic.readBoolOrNil(self.props.showFaction), true) then
		return
	elseif Logic.isEmpty(self.player.faction) then
		return
	elseif self.player.faction == Faction.defaultFaction then
		return
	end
	return Faction.Icon{size = 'small', showLink = false, faction = self.player.faction, game = self.props.game}
end

---@orotected
---@return string|Widget?
function BasePlayerDisplayWidget:getName()
	local player = self.player
	local showLink = Logic.nilOr(Logic.readBoolOrNil(self.props.showLink), true)
	local name = showLink and Link{
		link = player.pageName, children = player.displayName
	} or player.displayName
	if self.props.dq then
		return HtmlWidgets.S{children = name}
	end
	return name
end

return BasePlayerDisplayWidget
