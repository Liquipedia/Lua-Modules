---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local CharacterNames = Lua.import('Module:CharacterNames', {loadData = true})
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local SIZE_HERO = '25x25px'

---@class NarakaInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
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

	if id == 'custom' then
		local heroIcons = Array.map(caller:getAllArgsForBase(args, 'hero'), function(hero, _)
			return CharacterIcon.Icon{character = CharacterNames[hero:lower()], size = SIZE_HERO}
		end)

		return {
			Cell{
				name = #heroIcons > 1 and 'Signature Heroes' or 'Signature Hero',
				children = {table.concat(heroIcons, '&nbsp;')},
			}
		}
	elseif id == 'region' then
		return {}
	elseif id == 'history' then
		table.insert(widgets, Cell{name = 'Retired', children = {args.retired}})
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	for _, hero, heroIndex in Table.iter.pairsByPrefix(args, 'hero', {requireIndex = false}) do
		lpdbData.extradata['signatureHero' .. heroIndex] = CharacterNames[hero:lower()]
	end

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = TeamTemplate.getPageName(args.team2)
	end

	return lpdbData
end

---@return Widget?
function CustomPlayer:createBottomContent()
	if not self:shouldStoreData(self.args) or String.isEmpty(self.args.team) then
		return
	end

	local teamPage = TeamTemplate.getPageName(self.args.team)
	if not teamPage then
		return
	end

	return UpcomingTournaments.team{name = teamPage}
end

return CustomPlayer
