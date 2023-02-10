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
local YearsActive = require('Module:YearsActive') -- TODO Convert to use the commons YearsActive

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.getWikiCategories = CustomPlayer.getWikiCategories

	return player:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
	local function inputToCharacterIconList(input, game)
		if type(input) ~= 'string' then
			return nil
		end
		return Array.map(mw.text.split(input, ','), function(character)
			return Characters.InfoboxCharacter{mw.text.trim(character), game}
		end)
	end

	for game, gameData in pairs(Info.games) do
		local main = inputToCharacterIconList(_args['main-' .. game], game)
		local former = inputToCharacterIconList(_args['former-main-' .. game], game)
		local alt = inputToCharacterIconList(_args['alt-' .. game], game)

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
	elseif id == 'achievements' then
		widgets = {}
		local achievements = {}
		for game, gameData in pairs(Info.games) do
			local icons = AchievementIcons.drawRow(game, true)
			if String.isNotEmpty(icons) then
				table.insert(achievements, {gameName = gameData.name, icons = icons})
			end
		end
		if #achievements > 0 then
			table.insert(widgets, Title{name = 'Achievements'})
			for _, achievement in ipairs(achievements) do
				table.insert(widgets, Cell{name = achievement.gameName, content = {achievement.icons}})
			end
		end
	end

	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.maingame = _args.maingame
	for game in pairs(Info.games) do
		lpdbData.extradata['main' .. game] = _args['main-' .. game]
	end

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

return CustomPlayer
