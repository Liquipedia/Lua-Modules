---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local Class = Lua.import('Module:Class')
local HeroNames = Lua.import('Module:HeroNames', {loadData = true})
local Region = Lua.import('Module:Region')
local String = Lua.import('Module:StringUtils')
local TeamHistoryAuto = Lua.import('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local SIZE_HERO = '25x25px'

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.autoTeam = true

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		-- Signature Heroes
		local heroIcons = Array.map(caller:getAllArgsForBase(args, 'hero'), function(hero)
			local standardizedHero = HeroNames[hero:lower()]
			if not standardizedHero then
				-- we have an invalid hero entry
				-- add warning (including tracking category)
				table.insert(
					caller.warnings,
					'Invalid hero input "' .. hero .. '"[[Category:Pages with invalid hero input]]'
				)
			end
			return CharacterIcon.Icon{character = standardizedHero or hero, size = SIZE_HERO}
		end)

		table.insert(widgets, Cell{
			name = #heroIcons > 1 and 'Signature Heroes' or 'Signature Hero',
			content = {table.concat(heroIcons, '&nbsp;')},
		})
	elseif id == 'history' then
		local manualHistory = args.history
		local automatedHistory = TeamHistoryAuto.results{
			convertrole = true,
			iconModule = 'Module:PositionIcon/data',
			player = caller.pagename
		}

		if String.isNotEmpty(manualHistory) or automatedHistory then
			return {
				Title{children = 'History'},
				Center{children = {manualHistory}},
				Center{children = {automatedHistory}},
			}
		end
	elseif id == 'region' then return {}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args)
	-- store signature heroes with standardized name
	for heroIndex, hero in ipairs(self:getAllArgsForBase(args, 'hero')) do
		lpdbData.extradata['signatureHero' .. heroIndex] = HeroNames[hero:lower()]
	end

	lpdbData.region = String.nilIfEmpty(Region.name{region = args.region, country = args.country})

	return lpdbData
end

return CustomPlayer
