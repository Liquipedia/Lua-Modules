---
-- @Liquipedia
-- page=Module:Game
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Info = Lua.import('Module:Info')

---@class GameData
---@field abbreviation string
---@field name string
---@field link string
---@field logo {darkMode: string, lightMode: string}
---@field defaultTeamLogo {darkMode: string, lightMode: string}
---@field order number?
---@field unlisted boolean?

local GamesData = Info.games --[[@as table<string, GameData>]]

local ICON_STRING = '[[File:${icon}|${alt}|link=${link}|class=${class}|${size}]]'
local DEFAULT_SIZE = '32x32px'
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
	---@cast gameInput -nil

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
---@return string[]
function Game.listGames(options)
	options = options or {}

	local function getGameOrder(gameIdentifier)
		return tonumber(GamesData[gameIdentifier].order)
	end

	local gamesList = Array.extractKeys(GamesData)

	gamesList = Array.filter(gamesList, function(gameIdentifier)
		return not GamesData[gameIdentifier].unlisted
	end)

	if Logic.readBool(options.ordered) and Array.all(gamesList, getGameOrder) then
		return Array.sortBy(gamesList, getGameOrder)
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

---Fetches the defaultTeamLogos (light & dark) for a given game
---@param options? {game: string?, useDefault: boolean?}
---@return table?
function Game.defaultTeamLogoData(options)
	return Game.raw(options).defaultTeamLogo
end

---@class gameIconOptions
---@field game string?
---@field size string?
---@field noLink boolean?
---@field link string?
---@field noSpan boolean?
---@field spanClass string?

---Builds the icon for a given game
---@param options gameIconOptions?
---@return string
function Game.icon(options)
	options = options or {}

	local gameData = Game.raw(options)

	local gameIcons
	local link = Logic.readBool(options.noLink) and '' or options.link or gameData.link
	local spanClass = (Logic.readBool(options.noSpan) and '') or
		(String.isNotEmpty(options.spanClass) and options.spanClass) or
		(String.isEmpty(options.size) and DEFAULT_SPAN_CLASS or '')

	if Table.isEmpty(gameData) then
		gameIcons = Game._createIcon{icon = ICON_PLACEHOLDER, size = options.size}
	elseif gameData.logo.lightMode == gameData.logo.darkMode then
		gameIcons = Game._createIcon{icon = gameData.logo.lightMode, size = options.size, link = link, alt = gameData.name}
	else
		gameIcons = Game._createIcon{icon = gameData.logo.lightMode, size = options.size,
				link = link, alt = gameData.name, mode = 'light'} ..
			Game._createIcon{icon = gameData.logo.darkMode, size = options.size,
				link = link, alt = gameData.name, mode = 'dark'}
	end

	if String.isNotEmpty(spanClass) then
		return tostring(mw.html.create('span'):addClass(spanClass):node(gameIcons))
	else
		return gameIcons
	end
end

---@param options {mode: string?, icon: string?, size: string?, link: string?, alt: string?}
---@return string
function Game._createIcon(options)
	return String.interpolate(
		ICON_STRING,
		{
			icon = options.icon,
			size = options.size or DEFAULT_SIZE,
			class = options.mode and ('show-when-' .. options.mode .. '-mode') or '',
			link = options.link or '',
			alt = options.alt or options.link or '',
		}
	)
end

---Fetches a text display for a given game
---@param options? {game: string?, useDefault: boolean?, noLink: boolean?, link: string?, useAbbreviation: boolean?}
---@return string?
function Game.text(options)
	options = options or {}

	local useAbbreviation = Logic.readBool(options.useAbbreviation)
	local gameData = Game.raw(options)
	if Table.isEmpty(gameData) then
		return Abbreviation.make{text = useAbbreviation and 'Unkwn.' or 'Unknown Game',
			title = 'The specified game input is not recognized'}
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
	---@cast logo -nil

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

return Class.export(Game, {exports = {
	'toIdentifier',
	'abbreviation',
	'name',
	'link',
	'icon',
	'text',
	'isDefaultTeamLogo',
}})
