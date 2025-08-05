---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local AchievementIcons = require('Module:AchievementIcons')
local Array = require('Module:Array')
local Characters = require('Module:Characters')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Info = require('Module:Info')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local YearsActive = require('Module:YearsActive') -- TODO Convert to use the commons YearsActive

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class SmashInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

local GAME_ORDER = {'64', 'melee', 'brawl', 'pm', 'wiiu', 'ultimate'}

local NON_BREAKING_SPACE = '&nbsp;'

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.residence, player.args.location = player.args.location, nil

	return player:createInfobox(frame)
end

---@param input string?
---@param game string
---@param fn string
---@return string[]?
function CustomPlayer.inputToCharacterIconList(input, game, fn)
	if type(input) ~= 'string' then
		return nil
	end
	return Array.map(mw.text.split(input, ','), function(character)
		return Characters[fn]{mw.text.trim(character), game}
	end)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		Array.forEach(GAME_ORDER, function(game)
			local gameData = Info.games[game]
			local main = CustomPlayer.inputToCharacterIconList(args['main-' .. game], game, 'InfoboxCharacter')
			local former = CustomPlayer.inputToCharacterIconList(args['former-main-' .. game], game, 'InfoboxCharacter')
			local alt = CustomPlayer.inputToCharacterIconList(args['alt-' .. game], game, 'InfoboxCharacter')

			Array.appendWith(widgets,
				(main or former or alt) and Title{children = gameData.name} or nil,
				Cell{name = 'Current Mains', content = main or {}},
				Cell{name = 'Former Mains', content = former or {}},
				Cell{name = 'Secondaries', content = alt or {}}
			)
		end)
	elseif id == 'status' then
		table.insert(widgets,
			Cell{name = 'Years Active', content = {YearsActive.get{player = mw.title.getCurrentTitle().baseText}}}
		)
	elseif id == 'team' then
		table.insert(widgets, Cell{name = 'Crew', content = {args.crew}})
	elseif id == 'nationality' then
		table.insert(widgets, Cell{name = 'Location', content = {args.residence}})
	elseif id == 'achievements' then
		local achievements = {}
		Array.forEach(GAME_ORDER, function(game)
			local gameData = Info.games[game]
			local icons = AchievementIcons.drawRow(game, true)
			if String.isEmpty(icons) then return end
			table.insert(achievements, {gameName = gameData.abbreviation, icons = icons})
		end)
		if #achievements == 0 then return {} end
		return Array.extend({Title{children = 'Achievements'}}, Array.map(achievements, function(achievement)
			return Cell{name = achievement.gameName, content = {achievement.icons}, options = {columns = 3}}
		end))
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.localid = args.localid
	lpdbData.extradata.maingame = args.game or Info.defaultGame
	for game in pairs(Info.games) do
		lpdbData.extradata['main' .. game] = args['main-' .. game]
	end

	lpdbData.region = Template.expandTemplate(mw.getCurrentFrame(), 'Player region', {args.country})

	return lpdbData
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	local args = self.args
	for game, gameData in pairs(Info.games) do
		if args['main-' .. game] then
			table.insert(categories, gameData.name .. ' Players')
		end
	end

	if not args.game then
		table.insert(categories, 'Player without game parameter')
	else
		table.insert(categories, Game.name{game = args.game} .. ' Players')
	end
	return categories
end

---@param args table
---@return string
function CustomPlayer:nameDisplay(args)
	local name = args.id or mw.title.getCurrentTitle().text
	local display = name
	if args.game then
		local icons = CustomPlayer.inputToCharacterIconList(args['main-'.. args.game], args.game, 'GetIconAndName')
		display = table.concat(icons or {}, NON_BREAKING_SPACE) .. NON_BREAKING_SPACE .. name
	end
	return display
end

return CustomPlayer
