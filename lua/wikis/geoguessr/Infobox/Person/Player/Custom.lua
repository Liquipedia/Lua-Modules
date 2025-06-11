---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Widget/Injector')
local MatchTicker = Lua.import('Module:MatchTicker/Custom')
local Player = Lua.import('Module:Infobox/Person')

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.history = TeamHistoryAuto.results{convertrole = true}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	return widgets
end

---@return string[]
function CustomPlayer:_getStatusContents()
	return {Page.makeInternalLink({onlyIfExists = true}, self.args.status) or self.args.status}
end

---@return Html?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) then
		return MatchTicker.participant{player = self.pagename}
	end
end

return CustomPlayer
