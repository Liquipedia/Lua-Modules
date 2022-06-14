---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Points
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local TableCell = require('Module:Widget/Table/Cell')
local Template = require('Module:Template')

local PointsCell = Class.new(
	TableCell,
	function(self, input)
		self._base:init{input.classes}
		self.points = input.points or '-'
		self.name = input.name
		self.link = input.link
		self.icon = input.icon
		self.iconDark = input.iconDark
	end
)

function PointsCell:make()
	if self.icon then
		local templateArgs = {self.icon, link = self.link, darkmode = self.iconDark, name = self.name}
		self._base:addContent(Template.safeExpand(mw.getCurrentFrame(), 'LeagueIconSmall/custom', templateArgs))
	end
	self._base:addContent(self.points)

	return self._base:make()
end

return PointsCell
