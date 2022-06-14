---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Points
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local LeagueIcon = require('Module:LeagueIcon')
local TableCell = require('Module:Widget/Table/Cell')

local PointsCell = Class.new(
	TableCell,
	function(self, input)
		self._base:init{input.classes}
		input.points = tonumber(input.point)
		self.points = input.points > 0 and input.points or '-'
		self.name = input.name
		self.link = input.link
		self.icon = input.icon
		self.iconDark = input.iconDark
	end
)

function PointsCell:make()
	if self.icon then
		local iconArgs = {link = self.link, icon = self.icon, iconDark = self.iconDark, name = self.name}
		self._base:addContent(LeagueIcon.display(iconArgs))
		self._base:addContent('&nbsp;')
	end
	self._base:addContent(self.points)

	return self._base:make()
end

return PointsCell
