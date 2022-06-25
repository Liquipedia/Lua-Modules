---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Player = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Role = require('Module:Role')
local Region = require('Module:Region')
local HeroIcon = require('Module:HeroIcon')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')
local Builder = require('Module:Infobox/Widget/Builder')

local _pagename = mw.title.getCurrentTitle().prefixedText
local _role
local _role2
local _EMPTY_AUTO_HISTORY = '<table style="width:100%;text-align:left"></table>'
local _SIZE_HERO = '25x25px'

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'history' then
		local manualHistory = _args.history
		local automatedHistory = TeamHistoryAuto._results({
			convertrole = 'true',
			player = _pagename
		}) or ''
		automatedHistory = tostring(automatedHistory)
		if automatedHistory == _EMPTY_AUTO_HISTORY then
			automatedHistory = nil
		end

		if not (String.isEmpty(manualHistory) and String.isEmpty(automatedHistory)) then
			return {
				Title{name = 'History'},
				Center{content = {manualHistory}},
				Center{content = {automatedHistory}},
			}
		end
	elseif id == 'region' then return {}
	elseif id == 'role' then
		_role = Role.run({role = _args.role})
		_role2 = Role.run({role = _args.role2})
		return {
			Cell{name = 'Role(s)', content = {_role.display, _role2.display}}
		}
	end
	return widgets
end


function CustomInjector:addCustomCells(widgets)
	-- Signature Heroes
	table.insert(widgets,
		Builder{
			builder = function()
				local heroIcons = Array.map(Player:getAllArgsForBase(_args, 'hero'),
					function(hero, _)
						return HeroIcon.getImage{hero, size = _SIZE_HERO}
					end
				)
				return {
					Cell{
						name = #heroIcons > 1 and 'Signature Heroes' or 'Signature Hero',
						content = {
							table.concat(heroIcons, '&nbsp;')
						}
					}
				}
			end
		})
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.isplayer = _role.isPlayer or 'true'
	lpdbData.extradata.role = _role.role
	lpdbData.extradata.role2 = _role2.role
	lpdbData.extradata.signatureHero1 = _args.hero1 or _args.hero
	lpdbData.extradata.signatureHero2 = _args.hero2
	lpdbData.extradata.signatureHero3 = _args.hero3
	lpdbData.extradata.signatureHero4 = _args.hero4
	lpdbData.extradata.signatureHero5 = _args.hero5

	local region = Region.run({region = _args.region, country = _args.country})
	if type(region) == 'table' then
		lpdbData.region = region.region
	end

	return lpdbData
end

return CustomPlayer
