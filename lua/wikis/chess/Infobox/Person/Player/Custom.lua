---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class ChessInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

local TITLES = {
	{code = 'gm', name = 'Grandmaster'},
	{code = 'im', name = 'International Master'},
	{code = 'wgm', name = 'Woman Grandmaster'},
	{code = 'fm', name = 'FIDE Master'},
	{code = 'wim', name = 'Woman International Master'},
	{code = 'cm', name = 'Candidate Master'},
	{code = 'wfm', name = 'Woman FIDE Master'},
	{code = 'wcm', name = 'Woman Candidate Master'},
}

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.id = player.args.id or player.args.romanized_name or player.args.name

	return player:createInfobox()
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	local highestTitleName
	for _, title in ipairs(TITLES) do
		if Logic.isNotEmpty(args['title_' .. title.code]) then
			highestTitleName = title.name
			break
		end
	end

	if highestTitleName then
		lpdbData.extradata.chesstitle = highestTitleName
	end

	return lpdbData
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		local titles = Array.filter(TITLES,
			function (title)
				return Logic.isNotEmpty(args['title_' .. title.code])
			end
		)
		if #titles > 0 then
			Array.extendWith(widgets,
				{Title{children = 'Titles'}},
				Array.map(
					titles,
					function (title)
						return Cell{name = title.name, content = {args['title_' .. title.code]}}
					end
				)
			)
		end

	elseif id == 'region' then
		return {}
	end

	return widgets
end

return CustomPlayer
