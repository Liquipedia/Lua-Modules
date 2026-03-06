---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = Lua.import('Module:Widget/All')
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
---@return Widget
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
				children = self.caller:_getRole(args.role) or DEFAULT_ROLE
			}
		}
	elseif id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Revealed Date', children = {args.revealdate}},
			Cell{name = 'Game ID', children = {'[[Hero ID|'.. args.gameid .. ']]'}},
			Cell{name = 'Health', children = {args.health}},
			Cell{name = 'Movespeed', children = {args.movespeed}},
			Cell{name = 'Difficulty', children = {args.difficulty}},
			Cell{name = 'Affiliation', children = {args.affiliation}},
			Cell{name = 'Voice Actor(s)', children = {args.voiceactor}}
		)
		return widgets
	end

	return widgets
end

---@param roleInput string?
---@return (string|Widget)[]?
function CustomHero:_getRole(roleInput)
	if type(roleInput) ~= 'string' then
		return nil
	end

	local roles = Array.map(Array.parseCommaSeparatedString(roleInput), function(role)
		return ROLE_LOOKUP[role:lower()]
	end)

	return Logic.nilIfEmpty(roles)
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
---@return table
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
