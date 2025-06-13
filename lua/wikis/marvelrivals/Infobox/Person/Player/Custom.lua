---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Region = require('Module:Region')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')
local Template = require('Module:Template')

local CharacterIcon = Lua.import('Module:CharacterIcon')
local CharacterNames = Lua.import('Module:HeroNames')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')
local MatchTicker = Lua.import('Module:MatchTicker/Custom')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local SIZE_HERO = '25x25px'
local MAX_NUMBER_OF_SIGNATURE_HEROES = 3

---@class MarvelRivalsInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
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
		local heroes = Array.sub(caller:getAllArgsForBase(args, 'hero'), 1, MAX_NUMBER_OF_SIGNATURE_HEROES)
		local heroIcons = Array.map(heroes, function(hero)
			return CharacterIcon.Icon{character = CharacterNames[hero:lower()], size = SIZE_HERO}
		end)

		Array.appendWith(widgets,
			Cell{
				name = #heroIcons > 1 and 'Signature Heroes' or 'Signature Hero',
				content = {table.concat(heroIcons, '&nbsp;')},
			}
		)
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	-- store signature heroes with standardized name
	Table.mergeInto(lpdbData.extradata, Table.map(
		Array.sub(self:getAllArgsForBase(args, 'hero'), 1, MAX_NUMBER_OF_SIGNATURE_HEROES),
		function(index, hero) return 'signatureHero' .. index, CharacterNames[hero:lower()]
	end))

	lpdbData.region = Region.name{region = args.region, country = args.country}

	lpdbData.extradata.team2 = String.nilIfEmpty(args.team2)

	return lpdbData
end

---@return string?
function CustomPlayer:createBottomContent()
	if String.isEmpty(self.args.team) or not self:shouldStoreData(self.args) then return end
	local teamPage = Team.page(mw.getCurrentFrame(), self.args.team)
	return tostring(MatchTicker.player{recentLimit = 3}) ..
		Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage})
end

return CustomPlayer
