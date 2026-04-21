---
-- @Liquipedia
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Context = Lua.import('Module:Components/Context')
local SquadContexts = Lua.import('Module:Components/Contexts/Squad')
local SquadController = Lua.import('Module:Squad/Controller')

local CustomSquad = {}

---@class SmashSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@return self
function ExtendedSquadRow:mains()
	local characters = {}
	Array.forEach(mw.text.split(self.model.extradata.mains or '', ','), function(main)
		table.insert(characters, Characters.GetIconAndName{main, game = self.model.extradata.game, large = true})
	end)

	table.insert(self.children, Widget.Td{
		css = {['text-align'] = 'center'},
		children = characters,
	})

	return self
end

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	local args = Arguments.getArgs(frame)
	return Context.Provider{
		contextDef = SquadContexts.GameTitle,
		value = args.game,
		children = {SquadController.run(frame)}
	}
end

return CustomSquad
