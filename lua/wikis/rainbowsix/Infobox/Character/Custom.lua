---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local AgeCalculation = Lua.import('Module:AgeCalculation')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local NameAliases = Lua.requireIfExists('Module:CharacterNames', {loadData = true})

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = Lua.import('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local TEAM_ATTACK = HtmlWidgets.Fragment{
	children = {
		IconImageWidget{
			imageLight = 'R6S Para Bellum atk logo.png',
			link = '',
			size = '14px'
		},
		' Attack'
	}
}
local TEAM_DEFENSE = HtmlWidgets.Fragment{
	children = {
		IconImageWidget{
			imageLight = 'R6S Para Bellum def logo.png',
			link = '',
			size = '14px'
		},
		' Defense'
	}
}

---@class RainbowsixHeroInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Operator'
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'birth' then
		local ageCalculationSuccess, age = pcall(AgeCalculation.run, {
			birthdate = args.birthdate,
			birthlocation = args.birthplace,
		})

		return ageCalculationSuccess and {
			Cell{name = 'Born', content = {age.birth}},
		} or {}
	elseif id == 'role' then
		return WidgetUtil.collect(
			Cell{
				name = 'Team',
				children = self.caller:_getTeam(args)
			},
			Cell{
				name = 'Operator Role',
				content = self.caller:getAllArgsForBase(args, 'function'),
				options = { makeLink = true }
			}
		)
	elseif id == 'class' then
		return {
			Cell{
				name = 'Team Rainbow',
				content = self.caller:_getTeamRainbow(args),
				options = { separator = ' ' }
			},
			Cell{
				name = 'Affiliation',
				content = { args.affiliation }
			}
		}
	elseif id == 'release' then
		if Logic.isEmpty(args.releasedate) then
			return {}
		end
		local patchData = mw.ext.LiquipediaDB.lpdb('datapoint', {
			conditions = '[[type::patch]] AND [[date::'.. args.releasedate ..']]',
		})[1]

		return {
			Cell{
				name = 'Release Date',
				content = WidgetUtil.collect(
					args.releasedate,
					Logic.isNotEmpty(patchData) and Link{
						link = patchData.pagename,
						children = patchData.name
					} or 'Launch'
				)
			}
		}
	elseif id == 'custom' then
		--TODO
	end

	return widgets
end

---@return Widget[]
function CustomCharacter:_getTeam(args)
	local team = (args.team or ''):lower()
	if team == 'attack' or team == 'atk' then
		return { TEAM_ATTACK }
	elseif team == 'defense' or team == 'def' then
		return { TEAM_DEFENSE }
	elseif team == 'both' then
		return { TEAM_ATTACK, TEAM_DEFENSE }
	else
		return {}
	end
end

---@return (Widget|string)[]
function CustomCharacter:_getTeamRainbow(args)
	local teamRainbow = (args['team rainbow'] or ''):lower()
	if teamRainbow == 'wolfguard' then
		return self:_buildTeamRainbowWidgets('Wolfguard', true)
	elseif teamRainbow == 'nighthaven' then
		return self:_buildTeamRainbowWidgets('Nighthaven')
	elseif teamRainbow == 'ghosteyes' then
		return self:_buildTeamRainbowWidgets('Ghosteyes')
	elseif teamRainbow == 'redhammer' then
		return self:_buildTeamRainbowWidgets('Redhammer')
	elseif teamRainbow == 'viperstrike' then
		return self:_buildTeamRainbowWidgets('Viperstrike', true)
	else
		return {}
	end
end

---@param teamName string
---@param allmode boolean?
---@return (Widget|string)[]
function CustomCharacter:_buildTeamRainbowWidgets(teamName, allmode)
	return {
		IconImageWidget{
			imageLight = 'R6S Squad ' .. teamName .. ' ' .. (allmode and 'allmode' or 'lightmode') .. '.png',
			imageDark = 'R6S Squad ' .. teamName .. ' ' .. (allmode and 'allmode' or 'darkmode') .. '.png',
			link = teamName
		},
		teamName
	}
end

---@param args table
---@return string?
function CustomCharacter:nameDisplay(args)
	return CharacterIcon.Icon{
		character = NameAliases[args.name:lower()],
		size = '50px'
	} .. ' ' .. args.name
end

return CustomCharacter
