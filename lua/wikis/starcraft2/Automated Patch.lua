local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')

local PatchAuto = {}

---@type {patch: string, date: string}[]
local PATCH_DATA = {
	{patch = '3.0.0', date = '2015-10-06'},
	{patch = '3.0.1', date = '2015-10-15'},
	{patch = '3.0.2', date = '2015-10-19'},
	{patch = '3.0.3', date = '2015-10-27'},
	{patch = '3.0.4', date = '2015-11-10'},
	{patch = '3.0.5', date = '2015-11-12'},
	{patch = '3.1.0', date = '2015-12-15'},
	{patch = '3.1.1', date = '2016-01-12'},
	{patch = '3.1.2', date = '2016-02-02'},
	{patch = '3.1.3', date = '2016-02-23'},
	{patch = '3.1.4', date = '2016-03-03'},
	{patch = '3.2.0', date = '2016-03-29'},
	{patch = '3.2.1', date = '2016-04-05'},
	{patch = '3.2.2', date = '2016-04-05'},
	{patch = '3.3.0', date = '2016-05-17'},
	{patch = '3.3.1', date = '2016-05-26'},
	{patch = '3.3.2', date = '2016-06-14'},
	{patch = '3.4.0', date = '2016-07-12'},
	{patch = '3.5.0', date = '2016-08-02'},
	{patch = '3.5.1', date = '2016-08-04'},
	{patch = '3.5.2', date = '2016-08-11'},
	{patch = '3.5.3', date = '2016-08-25'},
	{patch = '3.6.0', date = '2016-09-13'},
	{patch = '3.7.0', date = '2016-10-18'},
	{patch = '3.7.1', date = '2016-10-25'},
	{patch = '3.8.0', date = '2016-11-22'},
	{patch = '3.9.0', date = '2016-12-13'},
	{patch = '3.9.1', date = '2016-12-21'},
	{patch = '3.10.0', date = '2017-01-24'},
	{patch = '3.10.1', date = '2017-01-31'},
	{patch = '3.11.0', date = '2017-03-07'},
	{patch = '3.12.0', date = '2017-03-28'},
	{patch = '3.13.0', date = '2017-05-02'},
	{patch = '3.14.0', date = '2017-05-23'},
	{patch = '3.15.0', date = '2017-06-20'},
	{patch = '3.15.1', date = '2017-06-22'},
	{patch = '3.16.0', date = '2017-07-18'},
	{patch = '3.16.1', date = '2017-08-07'},
	{patch = '3.17.0', date = '2017-08-30'},
	{patch = '3.17.1', date = '2017-09-07'},
	{patch = '3.18.0', date = '2017-09-19'},
	{patch = '3.19.0', date = '2017-10-10'},
	{patch = '3.19.1', date = '2017-10-12'},
	{patch = '4.0.0', date = '2017-11-14'},
	{patch = '4.0.1', date = '2017-11-15'},
	{patch = '4.0.2', date = '2017-11-21'},
	{patch = '4.1.0', date = '2017-12-05'},
	{patch = '4.1.1', date = '2017-12-07'},
	{patch = '4.1.2', date = '2017-12-19'},
	{patch = '4.1.3', date = '2018-01-09'},
	{patch = '4.1.4', date = '2018-01-23'},
	{patch = '4.2.0', date = '2018-02-20'},
	{patch = '4.2.1', date = '2018-03-06'},
	{patch = '4.2.2', date = '2018-03-27'},
	{patch = '4.2.3', date = '2018-04-05'},
	{patch = '4.2.4', date = '2018-04-17'},
	{patch = '4.3.0', date = '2018-04-24'},
	{patch = '4.3.1', date = '2018-05-17'},
	{patch = '4.3.2', date = '2018-05-30'},
	{patch = '4.4.0', date = '2018-06-20'},
	{patch = '4.4.1', date = '2018-07-17'},
	{patch = '4.5.0', date = '2018-08-07'},
	{patch = '4.5.1', date = '2018-08-14'},
	{patch = '4.6.0', date = '2018-09-04'},
	{patch = '4.6.1', date = '2018-09-11'},
	{patch = '4.6.2', date = '2018-10-16'},
	{patch = '4.7.0', date = '2018-11-13'},
	{patch = '4.7.1', date = '2018-11-20'},
	{patch = '4.8.0', date = '2018-12-18'},
	{patch = '4.8.1', date = '2019-01-10'},
	{patch = '4.8.2', date = '2019-01-22'},
	{patch = '4.8.3', date = '2019-02-19'},
	{patch = '4.8.4', date = '2019-04-09'},
	{patch = '4.8.5', date = '2019-04-23'},
	{patch = '4.8.6', date = '2019-04-24'},
	{patch = '4.9.0', date = '2019-05-21'},
	{patch = '4.9.1', date = '2019-06-04'},
	{patch = '4.9.2', date = '2019-06-18'},
	{patch = '4.9.3', date = '2019-07-10'},
	{patch = '4.10.0', date = '2019-08-13'},
	{patch = '4.10.1', date = '2019-08-21'},
	{patch = '4.10.2', date = '2019-09-03'},
	{patch = '4.10.3', date = '2019-09-10'},
	{patch = '4.10.4', date = '2019-09-22'},
	{patch = '4.11.0', date = '2019-11-26'},
	{patch = '4.11.1', date = '2019-11-27'},
	{patch = '4.11.2', date = '2019-12-06'},
	{patch = '4.11.3', date = '2019-12-17'},
	{patch = '4.11.4', date = '2020-02-18'},
	{patch = '4.12.0', date = '2020-06-09'},
	{patch = '4.12.1', date = '2020-06-16'},
	{patch = '5.0.0', date = '2020-07-27'},
	{patch = '5.0.1', date = '2020-07-29'},
	{patch = '5.0.2', date = '2020-08-06'},
	{patch = '5.0.3', date = '2020-08-25'},
	{patch = '5.0.4', date = '2020-11-04'},
	{patch = '5.0.5', date = '2020-12-02'},
	{patch = '5.0.6', date = '2021-02-02'},
	{patch = '5.0.7', date = '2021-04-07'},
	{patch = '5.0.8', date = '2021-10-19'},
	{patch = '5.0.9', date = '2022-03-15'},
	{patch = '5.0.10', date = '2022-07-21'},
	{patch = '5.0.11', date = '2023-01-24'},
	{patch = '5.0.12', date = '2023-09-29'},
	{patch = '5.0.13', date = '2024-03-26'},
	{patch = '5.0.14', date = '2024-11-26'},
	{patch = '5.0.15', date = '2025-10-01'},

	{patch = '', date = '3999-01-01'}, -- keep this as last!
}

---@param frame Frame
---@return string?
function PatchAuto.get(frame)
	return PatchAuto._main(Arguments.getArgs(frame))
end

---@param args table
---@return string?
function PatchAuto._main(args)
	local numberOfPatches = #PATCH_DATA

	-- Get the date for which the patch is to be determined
	local date = args[1]:gsub('-XX', '99'):gsub('-??', '99')

	for index = 0, (numberOfPatches - 2) do
		if (PATCH_DATA[numberOfPatches - index].date > date) and (PATCH_DATA[numberOfPatches - 1 - index].date <= date) then
			return PATCH_DATA[numberOfPatches - 1 - index].patch
		end
	end
end

return PatchAuto
