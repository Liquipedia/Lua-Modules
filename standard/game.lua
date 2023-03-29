---
-- @Liquipedia
-- wiki=commons
-- page=Module:Game
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Info = Lua.import('Module:Info', {requireDevIfEnabled = true})

local GamesData = Info.games

local ICON_STRING = '[[File:${icon}|link=${link}|class=${class}|${size}]]'
local DEFAULT_SIZE = '25x25px'
local ICON_PLACEHOLDER = 'LeaguesPlaceholder.png'

local Game = {}

Game.getIdentifierByAbbreviation = FnUtil.memoize(function()
	return Table.map(GamesData, function(gameIdentifier, gameData)
		return gameData.abbreviation:lower(), gameIdentifier end)
end)

Game.getIdentifierByName = FnUtil.memoize(function()
	return Table.map(GamesData, function(gameIdentifier, gameData) return gameData.name:lower(), gameIdentifier end)
end)

---Get the identifier of a entered game. Checks against identifiers, full names and abbreviations.
---@param args? {game: string?, useDefault: boolean?}
---@return string?
function Game.toIdentifier(args)
	args = args or {}
	local gameInput = args.game

	if String.isEmpty(gameInput) and Logic.nilOr(Logic.readBoolOrNil(args.useDefault), true) then
		return Info.defaultGame
	elseif String.isEmpty(gameInput) then
		return
	end

	gameInput = gameInput:lower()

	return Game.getIdentifierByAbbreviation()[gameInput]
		or Game.getIdentifierByName()[gameInput]
		or GamesData[gameInput] and gameInput
		or nil
end

---Check if a given game is a valid game.
---@param game string?
---@return boolean
function Game.isValid(game)
	return Table.isNotEmpty(Game.raw{game = game})
end

---Fetches the raw data for a given game
---@param args? {game: string?, useDefault: boolean?}
---@return table
function Game.raw(args)
	local identifier = Game.toIdentifier(args)
	if not identifier then
		return {}
	end

	return GamesData[identifier] or {}
end

---Fetches all valid game identifiers, potentially ordered
---@param args? {ordered: boolean?}
---@return table
function Game.listGames(args)
	args = args or {}

	local gamesList = Array.extractKeys(GamesData or {})
	if Logic.readBool(args.ordered) then
		return Array.sortBy(gamesList, function(gameIdentifier) return GamesData[gameIdentifier].order end)
	end

	return gamesList
end

---Fetches the abbreviation for a given game
---@param args? {game: string?, useDefault: boolean?}
---@return string?
function Game.abbreviation(args)
	return Game.raw(args).abbreviation
end

---Fetches the name for a given game
---@param args? {game: string?, useDefault: boolean?}
---@return string?
function Game.name(args)
	return Game.raw(args).name
end

---Fetches the link for a given game
---@param args? {game: string?, useDefault: boolean?}
---@return string?
function Game.link(args)
	return Game.raw(args).link
end

---Fetches the defaultTeamLogos (light & dark) for a given game
---@param args? {game: string?, useDefault: boolean?}
---@return table?
function Game.defaultTeamLogoData(args)
	return Game.raw(args).defaultTeamLogo
end

---Builds the icon for a given game
---@param args? {game: string?, useDefault: boolean?, size: string?, noLink: boolean?, link: string?}
---@return string
function Game.icon(args)
	args = args or {}

	local gameData = Game.raw(args)
	if Table.isEmpty(gameData) then
		return Game._createIcon{icon = ICON_PLACEHOLDER, size = args.size}
	end

	local link = Logic.readBool(args.noLink) and '' or args.link or gameData.link

	if gameData.logo.lightMode == gameData.logo.darkMode then
		return Game._createIcon{icon = gameData.logo.lightMode, size = args.size, link = link}
	end

	return Game._createIcon{size = args.size, link = link, mode = 'light', icon = gameData.logo.lightMode}
		.. Game._createIcon{size = args.size, link = link, mode = 'dark', icon = gameData.logo.darkMode}
end

---@param args {mode: string?, icon: string?, size: string?, link: string?}
---@return string
function Game._createIcon(args)
	return String.interpolate(
		ICON_STRING,
		{
			icon = args.icon,
			size = args.size or DEFAULT_SIZE,
			class = args.mode and ('show-when-' .. args.mode .. '-mode') or '',
			link = args.link or '',
		}
	)
end

---Fetches a text display for a given game
---@param args? {game: string?, useDefault: boolean?, noLink: boolean?, link: string?, useAbbreviation: string?}
---@return string?
function Game.text(args)
	args = args or {}

	local useAbbreviation = Logic.readBool(args.useAbbreviation)
	local gameData = Game.raw(args)
	if Table.isEmpty(gameData) then
		return Abbreviation.make(useAbbreviation and 'Unkwn.' or 'Unknown Game', 'The specified game input is not recognized')
	end

	if Logic.readBool(args.noLink) then
		return useAbbreviation and gameData.abbreviation or gameData.name
	else
		return Page.makeInternalLink(
			{onlyIfExists = false},
			useAbbreviation and gameData.abbreviation or gameData.name,
			args.link or gameData.link
		)
	end
end

Game.defaultTeamLogos = FnUtil.memoize(function()
	local defaultTeamLogos = {}
	for _, gameData in pairs(GamesData) do
		local teamLogos = gameData.defaultTeamLogo
		defaultTeamLogos[teamLogos.darkMode] = true
		defaultTeamLogos[teamLogos.lightMode] = true
	end

	return defaultTeamLogos
end)

---@param args {logo: string?, game: string?, useDefault: boolean?}
---@return boolean
function Game.isDefaultTeamLogo(args)
	local logo = args.logo
	if String.isEmpty(logo) then
		return false
	end

	logo = logo:gsub('_', ' ')

	if String.isEmpty(args.game) then
		return Game.defaultTeamLogos()[logo] ~= nil
	end

	local defaultLogos = Game.raw(args).defaultTeamLogo
	if not defaultLogos then
		error('Invalid game input "' .. args.game .. '"')
	end

	return Table.includes(defaultLogos, logo)
end

return Class.export(Game)
