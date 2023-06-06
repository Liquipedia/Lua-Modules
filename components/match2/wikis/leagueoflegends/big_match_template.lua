---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:BigMatch/Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- luacheck: ignore
return {
	header =
		[=[
			<div class="match-bm-lol-match-header">
				<div class="match-bm-lol-match-header-overview">
					<div class="match-bm-lol-match-header-team">{{#opponents.1}}{{&iconDisplay}}<div class="match-bm-lol-match-header-team-long">{{#page}}[[{{page}}|{{name}}]]{{/page}}</div><div class="match-bm-lol-match-header-team-short">[[{{page}}|{{shortname}}]]</div><div>{{generateSeriesDots}}</div>{{/opponents.1}}</div>
					<div class="match-bm-lol-match-header-result">{{#isBestOfOne}}{{#games.1.apiInfo}}{{team1.scoreDisplay}}&ndash;{{team2.scoreDisplay}}{{/games.1.apiInfo}}{{/isBestOfOne}}{{^isBestOfOne}}{{opponents.1.score}}&ndash;{{opponents.2.score}}{{/isBestOfOne}}</div>
					<div class="match-bm-lol-match-header-team">{{#opponents.2}}{{&iconDisplay}}<div class="match-bm-lol-match-header-team-long">{{#page}}[[{{page}}|{{name}}]]{{/page}}</div><div class="match-bm-lol-match-header-team-short">[[{{page}}|{{shortname}}]]</div><div>{{generateSeriesDots}}</div>{{/opponents.2}}</div>
				</div>
				<div class="match-bm-lol-match-header-tournament">[[{{parent}}|{{tournament}}]]</div>
				<div class="match-bm-lol-match-header-date">{{&dateCountdown}}</div>
			</div>
			{{#isBestOfOne}}<div class="match-bm-lol-game-overview"><div class="match-bm-lol-game-summary">
			<div class="match-bm-lol-game-summary-team">{{#games.1.apiInfo.team1}}[[File:Lol faction {{color}}.png|link=|{{color}} side]]{{/games.1.apiInfo.team1}}</div>
			<div class="match-bm-lol-game-summary-center"><div class="match-bm-lol-game-summary-score-holder"><div class="match-bm-lol-game-summary-length">{{games.1.length}}</div></div></div>
			<div class="match-bm-lol-game-summary-team">{{#games.1.apiInfo.team2}}[[File:Lol faction {{color}}.png|link=|{{color}} side]]{{/games.1.apiInfo.team2}}</div>
			</div></div>{{/isBestOfOne}}
			{{#extradata.mvp}}<div class="match-bm-lol-match-mvp"><b>MVP</b> {{#players}}[[{{name}}|{{displayname}}]]{{/players}}</div>{{/extradata.mvp}}
		]=],
	footer =
		[=[
			<h3>Additional Information</h3>
			<div class="match-bm-lol-match-additional">
				{{#vods}}
					<div class="match-bm-lol-match-additional-list">{{#icons}}{{&.}}{{/icons}}</div>
				{{/vods}}
				<div class="match-bm-lol-match-additional-list">{{#links}}[[File:{{icon}}|link={{link}}|15px|{{text}}]]{{/links}}</div>
				{{#patch}}
					<div class="match-bm-lol-match-additional-list">[[Patch {{patch}}]]</div>
				{{/patch}}
			</div>
		]=],
	game =
		[=[
			{{^isBestOfOne}}<div class="match-bm-lol-game-overview">
				<div class="match-bm-lol-game-summary">
					<div class="match-bm-lol-game-summary-team">{{&opponents.1.iconDisplay}}</div>
					<div class="match-bm-lol-game-summary-center">
						<div class="match-bm-lol-game-summary-faction">{{#apiInfo.team1}}[[File:Lol faction {{color}}.png|link=|{{color}} side]]{{/apiInfo.team1}}</div>
						<div class="match-bm-lol-game-summary-score-holder">{{#finished}}<div class="match-bm-lol-game-summary-score">{{apiInfo.team1.scoreDisplay}}&ndash;{{apiInfo.team2.scoreDisplay}}</div><div class="match-bm-lol-game-summary-length">{{length}}</div>{{/finished}}</div>
						<div class="match-bm-lol-game-summary-faction">{{#apiInfo.team2}}[[File:Lol faction {{color}}.png|link=|{{color}} side]]{{/apiInfo.team2}}</div>
					</div>
					<div class="match-bm-lol-game-summary-team">{{&opponents.2.iconDisplay}}</div>
				</div>
			</div>{{/isBestOfOne}}
			<h3>Picks and Bans</h3>
			<div class="match-bm-lol-game-veto collapsed general-collapsible">
				<div class="match-bm-lol-game-veto-overview">
					<div class="match-bm-lol-game-veto-overview-team"><div class="match-bm-lol-game-veto-overview-team-header">{{&opponents.1.iconDisplay}}</div>
						<div class="match-bm-lol-game-veto-overview-team-veto">
							<ul class="match-bm-lol-game-veto-overview-pick" aria-labelledby="picks">{{#apiInfo.team1.pick}}<li class="match-bm-lol-game-veto-overview-item">{{&heroIcon}}<div class="match-bm-lol-game-veto-pick-bar-{{apiInfo.team1side}}"></div></li>{{/apiInfo.team1.pick}}</ul>
							<ul class="match-bm-lol-game-veto-overview-ban" aria-labelledby="bans">{{#apiInfo.team1.ban}}<li class="match-bm-lol-game-veto-overview-item">{{&heroIcon}}</li>{{/apiInfo.team1.ban}}</ul>
						</div>
					</div>
					<div class="match-bm-lol-game-veto-overview-team"><div class="match-bm-lol-game-veto-overview-team-header">{{&opponents.2.iconDisplay}}</div>
						<div class="match-bm-lol-game-veto-overview-team-veto">
							<ul class="match-bm-lol-game-veto-overview-pick" aria-labelledby="picks">{{#apiInfo.team2.pick}}<li class="match-bm-lol-game-veto-overview-item">{{&heroIcon}}<div class="match-bm-lol-game-veto-pick-bar-{{apiInfo.team2side}}"></div></li>{{/apiInfo.team2.pick}}</ul>
							<ul class="match-bm-lol-game-veto-overview-ban" aria-labelledby="bans">{{#apiInfo.team2.ban}}<li class="match-bm-lol-game-veto-overview-item">{{&heroIcon}}</li>{{/apiInfo.team2.ban}}</ul>
						</div>
					</div>
				</div>
				<div class="match-bm-lol-game-veto-order-toggle ppt-toggle-expand">
					<div class="general-collapsible-expand-button"><div>Show Order &nbsp;<i class="fa fa-chevron-down"></i></div></div>
					<div class="general-collapsible-collapse-button"><div>Hide Order &nbsp;<i class="fa fa-chevron-up"></i></div></div>
				</div>
				<div class="match-bm-lol-game-veto-order-list ppt-hide-on-collapse">
					<div class="match-bm-lol-game-veto-order-team">
						<div class="match-bm-lol-game-veto-order-team-header">{{&opponents.1.iconDisplay}}</div>
						<div class="match-bm-lol-game-veto-order-team-choices"><div class="match-bm-lol-game-veto-order-team-choice-group">
							{{#apiInfo.championVetoByTeam.1}}{{#isNewGroup}}</div><div class="match-bm-lol-game-veto-order-team-choice-group">{{/isNewGroup}}<div class="match-bm-lol-game-veto-order-team-choice {{#isBan}}match-bm-lol-game-veto-order-ban{{/isBan}}"><div class="match-bm-lol-game-veto-order-step {{^isBan}}match-bm-lol-game-veto-order-step-{{apiInfo.team1side}}{{/isBan}}">{{vetoNumber}}</div>{{&heroIcon}}</div>{{/apiInfo.championVetoByTeam.1}}
						</div></div>
					</div>
					<div class="match-bm-lol-game-veto-order-team">
						<div class="match-bm-lol-game-veto-order-team-header">{{&opponents.2.iconDisplay}}</div>
						<div class="match-bm-lol-game-veto-order-team-choices"><div class="match-bm-lol-game-veto-order-team-choice-group">
							{{#apiInfo.championVetoByTeam.2}}{{#isNewGroup}}</div><div class="match-bm-lol-game-veto-order-team-choice-group">{{/isNewGroup}}<div class="match-bm-lol-game-veto-order-team-choice {{#isBan}}match-bm-lol-game-veto-order-ban{{/isBan}}" aria-labelledby="round {{vetoNumber}} {{#isBan}}ban{{/isBan}}{{^isBan}}pick{{/isBan}}"><div class="match-bm-lol-game-veto-order-step {{^isBan}}match-bm-lol-game-veto-order-step-{{apiInfo.team2side}}{{/isBan}}">{{vetoNumber}}</div>{{&heroIcon}}</div>{{/apiInfo.championVetoByTeam.2}}
						</div></div>
					</div>
				</div>
			</div>
			<h3>Head-to-Head</h3>
			<div class="match-bm-lol-h2h">
				<div class="match-bm-lol-h2h-header">
					<div class="match-bm-lol-h2h-header-team">{{&opponents.1.iconDisplay}}</div>
					<div class="match-bm-lol-h2h-stat-title"></div>
					<div class="match-bm-lol-h2h-header-team">{{&opponents.2.iconDisplay}}</div>
				</div>
				<div class="match-bm-lol-h2h-section">
					<div class="match-bm-lol-h2h-stat">
						<div>{{#apiInfo.team1}}{{kills}}/{{deaths}}/{{assists}}{{/apiInfo.team1}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon kda.png|link=]]<br>KDA</div>
						<div>{{#apiInfo.team2}}{{kills}}/{{deaths}}/{{assists}}{{/apiInfo.team2}}</div>
					</div>
					<div class="match-bm-lol-h2h-stat">
						<div>{{apiInfo.team1.gold}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon gold.png|link=]]<br>Gold</div>
						<div>{{apiInfo.team2.gold}}</div>
					</div>
				</div>
				<div class="match-bm-lol-h2h-section">
				<div class="match-bm-lol-h2h-stat">
						<div>{{apiInfo.team1.towerKills}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon tower.png|link=]]<br>Towers</div>
						<div>{{apiInfo.team2.towerKills}}</div>
					</div>
					<div class="match-bm-lol-h2h-stat">
						<div>{{apiInfo.team1.inhibitorKills}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon inhibitor.png|link=]]<br>Inhibitors</div>
						<div>{{apiInfo.team2.inhibitorKills}}</div>
					</div>
					<div class="match-bm-lol-h2h-stat">
						<div>{{apiInfo.team1.baronKills}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon baron.png|link=]]<br>Barons</div>
						<div>{{apiInfo.team2.baronKills}}</div>
					</div>
					<div class="match-bm-lol-h2h-stat">
						<div>{{apiInfo.team1.dragonKills}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon dragon.png|link=]]<br>Drakes</div>
						<div>{{apiInfo.team2.dragonKills}}</div>
					</div>
					<!--<div class="match-bm-lol-h2h-stat">
						<div>{{apiInfo.team1.heraldKills}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon herald.png|link=]]<br>Heralds</div>
						<div>{{apiInfo.team2.heraldKills}}</div>
					</div>-->
				</div>
			</div>
			<h3>Player Performance</h3>
			<div class="match-bm-lol-players-wrapper">
				<div class="match-bm-lol-players-team"><div class="match-bm-lol-players-team-header">{{&opponents.1.iconDisplay}}</div>
					{{#apiInfo.team1.players}}
						<div class="match-bm-lol-players-player">
							<div class="match-bm-lol-players-player-details">
								<div class="match-bm-lol-players-player-character">
									<div class="match-bm-lol-players-player-avatar"><div class="match-bm-lol-players-player-icon">{{&heroIcon}}</div><div class="match-bm-lol-players-player-role">[[File:Lol role {{roleIcon}}.png|link=|{{role}}]]</div></div>
									<div class="match-bm-lol-players-player-name">[[{{id}}]]<i>{{champion}}</i></div>
								</div>
								<div class="match-bm-lol-players-player-loadout">
									<!-- Loadout -->
									<div class="match-bm-lol-players-player-loadout-rs-wrap">
										<!-- Runes/Spells -->
										<div class="match-bm-lol-players-player-loadout-rs">[[File:Rune {{runeKeystone}}.png|24px]][[File:Rune {{runeSecondaryTree}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-rs">[[File:Summoner spell {{spells.1}}.png|24px]][[File:Summoner spell {{spells.2}}.png|24px]]</div>
									</div>
									<div class="match-bm-lol-players-player-loadout-items">
										<!-- Items -->
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.1}}.png|24px]][[File:Lol item {{items.2}}.png|24px]][[File:Lol item {{items.3}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.4}}.png|24px]][[File:Lol item {{items.5}}.png|24px]][[File:Lol item {{items.6}}.png|24px]]</div>
									</div>
								</div>
							</div>
							<div class="match-bm-lol-players-player-stats">
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon kda.png|link=|KDA]] {{kills}}/{{deaths}}/{{assists}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=|CS]] {{creepScore}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon dmg.png|link=|Damage]] {{damageDone}}</div>
							</div>
						</div>
					{{/apiInfo.team1.players}}
				</div>
				<div class="match-bm-lol-players-team"><div class="match-bm-lol-players-team-header">{{&opponents.2.iconDisplay}}</div>
					{{#apiInfo.team2.players}}
						<div class="match-bm-lol-players-player">
							<div class="match-bm-lol-players-player-details">
								<div class="match-bm-lol-players-player-character">
									<div class="match-bm-lol-players-player-avatar"><div class="match-bm-lol-players-player-icon">{{&heroIcon}}</div><div class="match-bm-lol-players-player-role">[[File:Lol role {{roleIcon}}.png|link=|{{role}}]]</div></div>
									<div class="match-bm-lol-players-player-name">[[{{id}}]]<i>{{champion}}</i></div>
								</div>
								<div class="match-bm-lol-players-player-loadout">
									<!-- Loadout -->
									<div class="match-bm-lol-players-player-loadout-rs-wrap">
										<!-- Runes/Spells -->
										<div class="match-bm-lol-players-player-loadout-rs">[[File:Rune {{runeKeystone}}.png|24px]][[File:Rune {{runeSecondaryTree}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-rs">[[File:Summoner spell {{spells.1}}.png|24px]][[File:Summoner spell {{spells.2}}.png|24px]]</div>
									</div>
									<div class="match-bm-lol-players-player-loadout-items">
										<!-- Items -->
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.1}}.png|24px]][[File:Lol item {{items.2}}.png|24px]][[File:Lol item {{items.3}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.4}}.png|24px]][[File:Lol item {{items.5}}.png|24px]][[File:Lol item {{items.6}}.png|24px]]</div>
									</div>
								</div>
							</div>
							<div class="match-bm-lol-players-player-stats">
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon kda.png|link=|KDA]] {{kills}}/{{deaths}}/{{assists}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=|CS]] {{creepScore}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon dmg.png|link=|Damage]] {{damageDone}}</div>
							</div>
						</div>
					{{/apiInfo.team2.players}}
				</div>
			</div>
		]=]
}
