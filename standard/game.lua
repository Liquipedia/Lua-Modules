---
-- @Liquipedia
-- wiki=commons
-- page=Module:Game
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
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

---@param args {game: string?, useDefault boolean?}
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
		or gameInput
end

function Game.raw(args)
	local identifier = Game.toIdentifier(args)
	if not identifier then
		return {}
	end

	return GamesData[identifier] or {}
end

function Game.abbreviation(args)
	return Game.raw(args).abbreviation
end

function Game.name(args)
	return Game.raw(args).name
end

function Game.link(args)
	return Game.raw(args).link
end

function Game.defaultTeamLogoData(args)
	return Game.raw(args).defaultTeamLogo
end

function Game.icon(args)
	args = args or {}

	local gameData = Game.raw(args)
	if Table.isEmpty(gameData) then
		return String.interpolate(
			ICON_STRING,
			{
				icon = ICON_PLACEHOLDER,
				size = args.size or DEFAULT_SIZE,
				class = '',
				link = ''
			}
		)
	end

	local link = Logic.readBool(args.noLink) and '' or args.link or gameData.link

	return String.interpolate(
		ICON_STRING,
		{
			icon = gameData.logo.lightMode,
			size = args.size or DEFAULT_SIZE,
			class = 'show-when-light-mode',
			link = link,
		}
	) .. String.interpolate(
		ICON_STRING,
		{
			icon = gameData.logo.darkMode,
			size = args.size or DEFAULT_SIZE,
			class = 'show-when-dark-mode',
			link = link,
		}
	)
end

Game.defaultTeamLogos = FnUtil.memoize(function()
	local defaultTeamLogos = {}
	for _, gameData in pairs(GamesData) do
		local teamLogos = gameData.defaultTeamLogo
		defaultTeamLogos[teamLogos.darkMode] = true
		defaultTeamLogos[teamLogos.lightMode] = true
	end

	return Array.extractKeys(defaultTeamLogos)
end)

function Game.isDefaultTeamLogo(args)
	local logo = args.logo
	if String.isEmpty(logo) then
		return false
	end

	logo = logo:gsub('_', ' ')

	if String.isEmpty(args.game) then
		return Table.includes(Game.defaultTeamLogos(), logo)
	end

	local defaultLogos = Game.raw(args).defaultTeamLogo
	if not defaultLogos then
		error('Invalid game input "' .. args.game .. '"')
	end

	return Table.includes(defaultLogos, logo)
end

return Class.export(Game)
