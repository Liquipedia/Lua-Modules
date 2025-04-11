---
-- @Liquipedia
-- wiki=marvelrivals
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')

local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')

local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MarvelRivalsHeroInfobox: CharacterInfobox
local CustomHero = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param roleType 'duelist'|'strategist'|'vanguard'
---@param displayName 'Duelist'|'Strategist'|'Vanguard'
---@return Widget
local function createRoleDisplayWidget(roleType, displayName)
	return HtmlWidgets.Fragment{
		children = {
			IconImageWidget{
				imageLight = 'Marvel Rivals gameasset icon ' .. roleType .. ' lightmode.png',
				imageDark = 'Marvel Rivals gameasset icon ' .. roleType .. ' darkmode.png',
				link = '',
				size = '14px'
			},
			' ',
			displayName
		}
	}
end

local DUELIST = createRoleDisplayWidget('Duelist','Duelist')
local STRATEGIST = createRoleDisplayWidget('Strategist', 'Strategist')
local VANGUARD = createRoleDisplayWidget('Vanguard','Vanguard')

local ROLE_LOOKUP = {
	duelist = { DUELIST },
	strategist = { STRATEGIST },
	vanguard = { VANGUARD },
}

---@param frame Frame
---@return Html
function CustomHero.run(frame)
	local character = CustomHero(frame)
	character:setWidgetInjector(CustomInjector(character))
	assert(character.args.gameid, 'missing "|gameid=" input')
	character.args.informationType = 'Hero'

	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'role' then
		return WidgetUtil.collect(
			Cell{
				name = 'Role',
				children = self.caller:_getRole(args)
			}
		)
	elseif id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Revealed Date', content = {args.revealdate}},
			Cell{name = 'Game ID', content = {'[[Hero ID|'.. args.gameid .. ']]'}},
			Cell{name = 'Health', content = {args.health}},
			Cell{name = 'Movespeed', content = {args.movespeed}},
			Cell{name = 'Difficulty', content = {args.difficulty}},
			Cell{name = 'Affiliation', content = {args.affiliation}},
			Cell{name = 'Voice Actor(s)', content = {args.voiceactor}}
		)
		return widgets
	end

	return widgets
end

---@return Widget[]
function CustomHero:_getRole(args)
    local role = (args.role or ''):lower()
    local roleLookup = ROLE_LOOKUP[role]

	if roleLookup then
		return roleLookup
	else
		return { 'NPC' }
	end
end

---@param lpdbData table
---@param args table
function CustomHero:addToLpdb(lpdbData, args)
	lpdbData.extradata = {
		role = args.role,
		revealdate = args.revealdate,
		gameid = args.gameid,
		health = args.health,
		movespeed = args.movespeed,
		dificulty = args.difficulty,
	}

	return lpdbData
end

return CustomHero
