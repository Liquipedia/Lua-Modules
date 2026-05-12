---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class PubgmobileInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)

---@class PubgmobileInfoboxPlayerWidgetInjector: WidgetInjector
---@field caller PubgmobileInfoboxPlayer
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'status' then
		return {
			Cell{name = 'Status', children = CustomPlayer._getStatusContents(args)},
			Cell{name = 'Years Active (Player)', children = {args.years_active}},
			Cell{name = 'Years Active (Org)', children = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', children = {args.years_active_coach}},
			Cell{name = 'Years Active (Talent)', children = {args.years_active_talent}},
		}
	elseif id == 'region' then return {}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = TeamTemplate.getPageName(args.team2)
	end

	return lpdbData
end

---@param args table
---@return string[]
function CustomPlayer._getStatusContents(args)
	if String.isEmpty(args.status) then
		return {}
	end
	return {Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status}
end

---@return string?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) then
		UpcomingTournaments.player{name = self.pagename}
	end
end

return CustomPlayer
