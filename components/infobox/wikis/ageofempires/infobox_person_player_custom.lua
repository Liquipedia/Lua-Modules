---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Achievements = require('Module:Achievements in infoboxes')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PlayerIntroduction = require('Module:PlayerIntroduction')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local RATINGS = {
	{text = 'RM Elo ([[Age of Empires II/Definitive Edition|AoE II DE]])', id = 'aoe2net_id', game = 'aoe2de'},
	{text = 'QM Elo ([[Age of Empires IV|AoE IV]])', id = 'aoe4net_id', game = 'aoe4'},
	{text = 'Supremacy Elo ([[Age of Empires III|AoE III]])', id = 'aoe3net_id', game = 'aoe3de'},
	{text = 'RM Elo ([[Voobly]] [[Age of Empires II|AoE II]])', id = 'voobly_elo'},
	{text = 'Elo ([[Voobly]] [[Age of Mythology|AoM]])', id = 'aom_voobly_elo'},
	{text = 'Elo ([[Age of Mythology/Extended Edition|AoM EE]])', id = 'aom_ee_elo'},
	{text = '1v1 Supremacy Elo ([[Age of Empires III|AoE 3]])', id = 'aoe3_elo'},
	{text = 'Tournament Elo ([[Age of Empires II|AoE II]])', id = 'aoe-elo.com_id', game = 'aoe-elo.com'},
}

local _player
local _args

function CustomPlayer.run(frame)
	_player = Player(frame)
	_args = _player.args

	-- Automatic achievements
	_args.achievements = Achievements._player{player = _player.pagename}

	-- Uppercase first letter in status
	if _args.status then
		_args.status = mw.getContentLanguage():ucfirst(_args.status)
	end

	_player.adjustLPDB = CustomPlayer.adjustLPDB
	_player.createWidgetInjector = CustomPlayer.createWidgetInjector

	local builtInfobox = _player:createInfobox()

	local autoPlayerIntro = ''
	if Logic.readBool((_args.autoPI or ''):lower()) then
		autoPlayerIntro = PlayerIntroduction._main{
			playerInfo = 'direct',
			transferquery = 'datapoint',
			defaultGame = 'Age of Empires II',
			team = _args.team,
			name = _args.romanized_name or _args.name,
			first_name = _args.first_name,
			last_name = _args.last_name,
			status = _args.status,
			game = false,
			type = false,
			role = false,
			role2 = false,
			id = _args.id,
			idIPA = _args.idIPA,
			idAudio = _args.idAudio,
			birthdate = Variables.varDefault('player_birthdate'),
			deathdate = Variables.varDefault('player_deathdate'),
			nationality = _args.country,
			nationality2 = _args.country2,
			nationality3 = _args.country3,
			subtext = _args.subtext,
			freetext = _args.freetext,
		}
	end

	return builtInfobox .. autoPlayerIntro
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		table.insert(widgets, Cell{name = 'Years Active', content = {_args.years_active}})
	elseif id == 'role' then
		return Cell{name = 'Roles', content =
			Array.map(mw.text.split(_args.roles, ','), function(role)
				return mw:getContentLanguage():ucfirst(mw.text.trim(role))
			end)
		}
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	--Elo ratings
	for _, rating in ipairs(RATINGS) do
		local currentRating, bestRating
		if rating.game then
			currentRating, bestRating = CustomPlayer.getRating(rating.id, rating.game)
		else
			bestRating = _args[rating.id]
		end
		table.insert(widgets, Cell{name = rating.text, content = {
			bestRating, currentRating
		}})
	end
	-- TODO: Games & Inactive Games

	return widgets
end

function CustomPlayer.getRating(id, game)
	if _args[id] then
		return mw.ext.aoedb.currentrating(_args[id], game), mw.ext.aoedb.highestrating(_args[id], game)
	end
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	-- TODO

	return lpdbData
end

return CustomPlayer
