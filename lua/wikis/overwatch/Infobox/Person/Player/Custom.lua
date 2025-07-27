---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local CharacterNames = Lua.import('Module:CharacterNames', {loadData = true})
local GameAppearances = Lua.import('Module:GetGameAppearances')
local MatchTicker = Lua.import('Module:MatchTicker/Custom')
local String = Lua.import('Module:StringUtils')
local Team = Lua.import('Module:Team')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center

local SIZE_HERO = '25x25px'
local MAX_NUMBER_OF_SIGNATURE_HEROES = 3

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local heroes = Array.sub(caller:getAllArgsForBase(args, 'hero'), 1, MAX_NUMBER_OF_SIGNATURE_HEROES)
		local heroIcons = Array.map(heroes, function(hero)
			return CharacterIcon.Icon{character = CharacterNames[hero:lower()], size = SIZE_HERO}
		end)

		Array.appendWith(widgets,
			Cell{
				name = #heroIcons > 1 and 'Signature Heroes' or 'Signature Hero',
				content = {table.concat(heroIcons, '&nbsp;')},
			},
			Cell{
				name = 'Game Appearances',
				content = GameAppearances.player({player = caller.pagename})
			}
		)
	elseif id == 'history' then
		if args.nationalteams then
			table.insert(widgets, 1, Center{children = {args.nationalteams}})
		end
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args)
	-- store signature heroes with standardized name
	for heroIndex, hero in ipairs(self:getAllArgsForBase(args, 'hero')) do
		lpdbData.extradata['signatureHero' .. heroIndex] = CharacterNames[hero:lower()]
		if heroIndex == MAX_NUMBER_OF_SIGNATURE_HEROES then
			break
		end
	end

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(args.team2).page
	end

	return lpdbData
end

---@return string?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(), self.args.team)
		local team2Page = String.isNotEmpty(self.args.team2) and Team.page(mw.getCurrentFrame(), self.args.team2) or nil
		return
			tostring(MatchTicker.player{recentLimit = 3}) ..
			Template.safeExpand(
				mw.getCurrentFrame(),
				'Upcoming and ongoing tournaments of',
				{team = teamPage}, {team2 = team2Page}
			)
	end
end

return CustomPlayer
