---
-- @Liquipedia
-- wiki=smash
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

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local GAME_ORDER = {'64', 'melee', 'brawl', 'pm', 'wiiu', 'ultimate'}

local _args

local NON_BREAKING_SPACE = '&nbsp;'

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args

	_args.residence, _args.location = _args.location, nil

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.getWikiCategories = CustomPlayer.getWikiCategories
	player.nameDisplay = CustomPlayer.nameDisplay

	return player:createInfobox(frame)
end

function CustomPlayer.inputToCharacterIconList(input, game, fn)
	if type(input) ~= 'string' then
		return nil
	end
	return Array.map(mw.text.split(input, ','), function(character)
		return Characters[fn]{mw.text.trim(character), game}
	end)
end

function CustomInjector:addCustomCells(widgets)
	for _, game in ipairs(GAME_ORDER) do
		local gameData = Info.games[game]
		local main = CustomPlayer.inputToCharacterIconList(_args['main-' .. game], game, 'InfoboxCharacter')
		local former = CustomPlayer.inputToCharacterIconList(_args['former-main-' .. game], game, 'InfoboxCharacter')
		local alt = CustomPlayer.inputToCharacterIconList(_args['alt-' .. game], game, 'InfoboxCharacter')

		if main or former or alt then
			table.insert(widgets, Title{name = gameData.name})
			table.insert(widgets, Cell{name = 'Current Mains', content = main or {}})
			table.insert(widgets, Cell{name = 'Former Mains', content = former or {}})
			table.insert(widgets, Cell{name = 'Secondaries', content = alt or {}})
		end
	end

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		table.insert(widgets,
			Cell{name = 'Years Active', content = {YearsActive.get{player = mw.title.getCurrentTitle().baseText}}}
		)
	elseif id == 'team' then
		table.insert(widgets,
			Cell{name = 'Crew', content = {_args.crew}}
		)
	elseif id == 'nationality' then
		table.insert(widgets,
			Cell{name = 'Location', content = {_args.residence}}
		)
	elseif id == 'achievements' then
		widgets = {}
		local achievements = {}
		for _, game in ipairs(GAME_ORDER) do
			local gameData = Info.games[game]
			local icons = AchievementIcons.drawRow(game, true)
			if String.isNotEmpty(icons) then
				table.insert(achievements, {gameName = gameData.abbreviation, icons = icons})
			end
		end
		if #achievements > 0 then
			table.insert(widgets, Title{name = 'Achievements'})
			for _, achievement in ipairs(achievements) do
				table.insert(widgets,
					Cell{name = achievement.gameName, content = {achievement.icons}, options = {columns = 3}}
				)
			end
		end
	end

	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.localid = _args.localid
	lpdbData.extradata.maingame = _args.game or Info.defaultGame
	for game in pairs(Info.games) do
		lpdbData.extradata['main' .. game] = _args['main-' .. game]
	end

	lpdbData.region = Template.expandTemplate(mw.getCurrentFrame(), 'Player region', {_args.country})

	return lpdbData
end

function CustomPlayer:getWikiCategories(args)
	local categories = {}
	for game, gameData in pairs(Info.games) do
		if _args['main-' .. game] then
			table.insert(categories, gameData.name .. ' Players')
		end
	end

	if not _args.game then
		table.insert(categories, 'Player without game parameter')
	else
		table.insert(categories, Game.name{game = _args.game} .. ' Players')
	end
	return categories
end

function CustomPlayer:nameDisplay(args)
	local name = args.id or mw.title.getCurrentTitle().text
	local display = name
	if _args.game then
		local icons = CustomPlayer.inputToCharacterIconList(_args['main-'.. _args.game], _args.game, 'GetIconAndName')
		display = table.concat(icons or {}, NON_BREAKING_SPACE) .. NON_BREAKING_SPACE .. name
	end
	return display
end

return CustomPlayer
