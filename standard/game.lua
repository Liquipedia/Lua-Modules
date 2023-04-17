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
local DEFAULT_SPAN_CLASS = 'icon-16px'
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
---@param options? {game: string?, useDefault: boolean?}
---@return string?
function Game.toIdentifier(options)
	options = options or {}
	local gameInput = options.game

	if String.isEmpty(gameInput) and Logic.nilOr(Logic.readBoolOrNil(options.useDefault), true) then
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
---@param options? {game: string?, useDefault: boolean?}
---@return table
function Game.raw(options)
	local identifier = Game.toIdentifier(options)
	if not identifier then
		return {}
	end

	return GamesData[identifier] or {}
end

---Fetches all valid game identifiers, potentially ordered
---@param options? {ordered: boolean?}
---@return table
function Game.listGames(options)
	options = options or {}

	local gamesList = Array.extractKeys(GamesData or {})
	if Logic.readBool(options.ordered) and Array.all(gamesList, function(gameIdentifier)
				return tonumber(GamesData[gameIdentifier].order)
			end) then
		return Array.sortBy(gamesList, function(gameIdentifier)
				return tonumber(GamesData[gameIdentifier].order)
			end)
	end

	return gamesList
end

---Fetches the abbreviation for a given game
---@param options? {game: string?, useDefault: boolean?}
---@return string?
function Game.abbreviation(options)
	return Game.raw(options).abbreviation
end

---Fetches the name for a given game
---@param options? {game: string?, useDefault: boolean?}
---@return string?
function Game.name(options)
	return Game.raw(options).name
end

---Fetches the link for a given game
---@param options? {game: string?, useDefault: boolean?}
---@return string?
function Game.link(options)
	return Game.raw(options).link
end

---Fetches the category prefix for a given game
---@param options? {game: string?, useDefault: boolean?}
---@return string?
function Game.categoryPrefix(options)
	return Game.raw(options).categoryPrefix
end

---Fetches the defaultTeamLogos (light & dark) for a given game
---@param options? {game: string?, useDefault: boolean?}
---@return table?
function Game.defaultTeamLogoData(options)
	return Game.raw(options).defaultTeamLogo
end

---Builds the icon for a given game
---@param options? {game: string?, useDefault: boolean?, size: string?, noLink: boolean?, link: string?, noSpan: boolean?, spanClass: string?}
---@return string
function Game.icon(options)
	options = options or {}

	local gameData = Game.raw(options)
	if Table.isEmpty(gameData) then
		return Game._createIcon{icon = ICON_PLACEHOLDER, size = options.size}
	end

	local link = Logic.readBool(options.noLink) and '' or options.link or gameData.link
	local spanClass = (Logic.readBool(options.noSpan) and '') or
		(String.isNotEmpty(options.spanClass) and options.spanClass) or
			DEFAULT_SPAN_CLASS

	if gameData.logo.lightMode == gameData.logo.darkMode then
		return Game._createIcon{icon = gameData.logo.lightMode, size = options.size, link = link, spanClass = spanClass}
	end

	return Game._createIcon{size = options.size, link = link, mode = 'light',
		icon = gameData.logo.lightMode, spanClass = spanClass}
	.. Game._createIcon{size = options.size, link = link, mode = 'dark',
		icon = gameData.logo.darkMode, spanClass = spanClass}
end

---@param options {mode: string?, icon: string?, size: string?, link: string?, spanClass: string?}
---@return string
function Game._createIcon(options)
	local iconString = String.interpolate(
		ICON_STRING,
		{
			icon = options.icon,
			size = options.size or DEFAULT_SIZE,
			class = options.mode and ('show-when-' .. options.mode .. '-mode') or '',
			link = options.link or '',
		}
	)
	if String.isNotEmpty(options.spanClass) then
		return mw.html.create('span'):addClass(options.spanClass):node(iconString)
	else
		return iconString
	end
end

---Fetches a text display for a given game
---@param options? {
---		game: string?,
---		useDefault: boolean?,?,
---		noLink: boolean?,?,
---		link: string?,?,
---		useAbbreviation:?,
---		string?
---}
---@return string?
function Game.text(options)
	options = options or {}

	local useAbbreviation = Logic.readBool(options.useAbbreviation)
	local gameData = Game.raw(options)
	if Table.isEmpty(gameData) then
		return Abbreviation.make(useAbbreviation and 'Unkwn.' or 'Unknown Game', 'The specified game input is not recognized')
	end

	if Logic.readBool(options.noLink) then
		return useAbbreviation and gameData.abbreviation or gameData.name
	else
		return Page.makeInternalLink({},
			useAbbreviation and gameData.abbreviation or gameData.name,
			options.link or gameData.link
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

---@param options {logo: string?, game: string?, useDefault: boolean?}
---@return boolean
function Game.isDefaultTeamLogo(options)
	local logo = options.logo
	if String.isEmpty(logo) then
		return false
	end

	logo = logo:gsub('_', ' ')

	if String.isEmpty(options.game) then
		return Game.defaultTeamLogos()[logo] ~= nil
	end

	local defaultLogos = Game.raw(options).defaultTeamLogo
	if not defaultLogos then
		error('Invalid game input "' .. options.game .. '"')
	end

	return Table.includes(defaultLogos, logo)
end

return Class.export(Game)
