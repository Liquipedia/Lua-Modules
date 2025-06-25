---
-- @Liquipedia
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

---@class MarvelRivalsHeroInfobox: CharacterInfobox
local CustomHero = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param roleType 'Duelist'|'Strategist'|'Vanguard'
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

local DUELIST = createRoleDisplayWidget('Duelist', 'Duelist')
local STRATEGIST = createRoleDisplayWidget('Strategist', 'Strategist')
local VANGUARD = createRoleDisplayWidget('Vanguard', 'Vanguard')
local DEFAULT_ROLE = 'NPC'

local ROLE_LOOKUP = {
	duelist = DUELIST,
	strategist = STRATEGIST,
	vanguard = VANGUARD,
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
		return {
			Cell{
				name = 'Role',
				children = {self.caller:_getRole(args) or DEFAULT_ROLE}
			}
		}
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

---@param roleInput string?
---@return Widget?
function CustomHero:_getRole(roleInput)
	if type(roleInput) ~= 'string' then
		return nil
	end
	return ROLE_LOOKUP[roleInput:lower()]
end

---@param args table
---@return string[]
function CustomHero:getRoles(args)
	return {
		self:_getRole(args.role),
	}
end

---@param lpdbData table
---@param args table
function CustomHero:addToLpdb(lpdbData, args)
	lpdbData.extradata.health = args.health
	lpdbData.extradata.movespeed = args.movespeed
	lpdbData.extradata.dificulty = args.difficulty
	lpdbData.extradata.role = args.role
	lpdbData.extradata.revealdate = args.revealdate
	lpdbData.extradata.gameid = args.gameid

	return lpdbData
end

return CustomHero
