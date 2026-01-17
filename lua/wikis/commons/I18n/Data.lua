---
-- @Liquipedia
-- page=Module:I18n/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	en = {
		-- Match Stream
		['matchstream-watch-live'] = 'Watch now',
		['matchstream-watch-upcoming'] = 'Watch here',

		-- Match Details
		['matchdetails-view-long'] = 'View match details',
		['matchdetails-add-long'] = 'Add details',
		['matchdetails-short'] = 'Details',

		-- Tournament Filter
		['tournament-ticker-no-tournaments'] = 'No tournaments found for your selected filters!',

		-- Filter Buttons
		['filterbuttons-all'] = 'All',
		['filterbuttons-featured'] = 'Curated',

		-- Dates
		['date-unknown'] = 'TBA',
		['date-range-unknown'] = 'TBA',

		-- Dates: Only startYear known
		['date-range-year'] = '${startYear}',
		['date-range-year--unknown'] = '${startYear} - TBA',
		['date-range-year--year'] = '${startYear} - ${endYear}',

		-- Dates: Only startYear, startMonth known
		['date-range-year-month'] = '${startMonth}, ${startYear}',
		['date-range-year-month--unknown'] = '${startMonth}, ${startYear} - TBA',
		['date-range-year-month--year-unkown_month'] = '${startMonth}, ${startYear} - TBA, ${endYear}',
		['date-range-year-month--month'] = '${startMonth} - ${endYear}, ${startYear}',
		['date-range-year-month--year-month'] = '${startMonth}, ${startYear} - ${endMonth}, ${endYear}',

		['date-range-year-month--unknown_month'] = '${startMonth} - TBA, ${startYear}',

		-- Dates: Full startdate known
		['date-range-year-month-day'] = '${startMonth} ${startDate}, ${startYear}',
		['date-range-year-month-day--unknown'] = '${startMonth} ${startDate}, ${startYear} - TBA',
		['date-range-year-month-day--year-unknown_month'] = '${startMonth} ${startDate}, ${startYear} - TBA, ${endYear}',
		['date-range-year-month-day--year-month-unknown_day'] = '${startMonth} ${startDate}, ${startYear} - ${endMonth} TBA, ${endYear}',
		['date-range-year-month-day--year-month-day'] = '${startMonth} ${startDate}, ${startYear} - ${endMonth} ${endDate}, ${endYear}',

		['date-range-year-month-day--month-day'] = '${startMonth} ${startDate} - ${endMonth} ${endDate}, ${startYear}',
		['date-range-year-month-day--month-unknown_day'] = '${startMonth} ${startDate} - ${endMonth} TBA, ${startYear}',
		['date-range-year-month-day--day'] = '${startMonth} ${startDate} - ${endDate}, ${startYear}',

		-- Dates: ticker variant (hidden years)
		-- startMonth known
		['date-range-month'] = '${startMonth}',
		['date-range-month--unknown_month'] = '${startMonth} - TBA',
		['date-range-month--month'] = '${startMonth} - ${endMonth}',

		-- startMonth and startDay known
		['date-range-month-day'] = '${startMonth} ${startDate}',
		['date-range-month-day--day'] = '${startMonth} ${startDate} - ${endDate}',

		['date-range-month-day--unknown'] = '${startMonth} ${startDate} - TBA',
		['date-range-month-day--month-unknown_day'] = '${startMonth} ${startDate} - ${endMonth} TBA',
		['date-range-month-day--month-day'] = '${startMonth} ${startDate} - ${endMonth} ${endDate}',

		-- Bracket Headers
		['brkts-header-r1'] = 'Grand Final,Final,GF',
		['brkts-header-r2'] = 'Semifinals,Semis,SF',
		['brkts-header-r3'] = 'Quarterfinals,Quarters,QF',
		['brkts-header-r4'] = 'Round ${round},R${round}',
		['brkts-header-rx'] = 'Round ${round},R${round}',

		['brkts-header-u1'] = 'Grand Final,Final,GF',
		['brkts-header-u2'] = 'Upper Bracket Final,UB Final,UBF',
		['brkts-header-u3'] = 'Upper Bracket Semifinals,UB Semifinals,UBSF',
		['brkts-header-u4'] = 'Upper Bracket Quarterfinals,UB Quarterfinals,UBQF',
		['brkts-header-ux'] = 'Upper Bracket Round ${round},UB Round ${round},UBR${round}',

		['brkts-header-m1'] = 'Mid Bracket Final,MB Final,MBF',
		['brkts-header-m2'] = 'Mid Bracket Semifinal,MB Semifinal,MBSF',
		['brkts-header-m3'] = 'Mid Bracket Quarterfinal,MB Quarterfinal,MBQF',
		['brkts-header-m4'] = 'Mid Bracket Round ${round},MB Round ${round},MBR${round}',
		['brkts-header-mx'] = 'Mid Bracket Round ${round},MB Round ${round},MBR${round}',

		['brkts-header-l2'] = 'Lower Bracket Final,LB Final,LBF',
		['brkts-header-l3'] = 'Lower Bracket Semifinal,LB Semifinal,LBSF',
		['brkts-header-l4'] = 'Lower Bracket Quarterfinals,LB Quarterfinals,LBQF',
		['brkts-header-lx'] = 'Lower Bracket Round ${round},LB Round ${round},LBR${round}',

		['brkts-header-q'] = 'Qualified,Qual.,Q',
		['brkts-header-tp'] = 'Third Place Match,3rd Place,3rd',

		-- MatchSummary Map Veto
		['matchsummary-mapveto-start'] = 'Start Map Veto',
	}
}
