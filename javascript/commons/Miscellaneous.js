/*******************************************************************************
 * Template(s): Timeline
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.timeline = {
	init: function() {
		const timeline = document.querySelector( '.scrollTimeline' );
		if ( timeline !== null ) {
			timeline.scrollLeft = timeline.scrollWidth;
		}
	}
};
liquipedia.core.modules.push( 'timeline' );

/*******************************************************************************
 * Template(s): TeamCard
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.teamcard = {
	init: function() {
		let teamcardsopened = false;
		document.querySelectorAll( '.teamcard-toggle-button' ).forEach( ( wrap ) => {
			let showplayers;
			if ( wrap.dataset.showAllText !== undefined ) {
				showplayers = wrap.dataset.showAllText;
			} else {
				showplayers = 'Show Players';
			}
			let hideplayers;
			if ( wrap.dataset.hideAllText !== undefined ) {
				hideplayers = wrap.dataset.hideAllText;
			} else {
				hideplayers = 'Hide Players';
			}
			const button = document.createElement( 'button' );
			button.classList.add( 'btn' );
			button.classList.add( 'btn-secondary' );
			button.classList.add( 'btn-small' );
			button.innerHTML = showplayers;
			button.addEventListener( 'click', () => {
				if ( teamcardsopened ) {
					teamcardsopened = false;
					document.querySelectorAll( '.teamcard-toggle-button button' ).forEach( ( btn ) => {
						btn.innerHTML = showplayers;
					} );
					document.querySelectorAll( '.teamcard' ).forEach( ( teamcard ) => {
						teamcard.classList.remove( 'teamcard-opened' );
					} );
				} else {
					teamcardsopened = true;
					document.querySelectorAll( '.teamcard-toggle-button button' ).forEach( ( btn ) => {
						btn.innerHTML = hideplayers;
					} );
					document.querySelectorAll( '.teamcard' ).forEach( ( teamcard ) => {
						teamcard.classList.add( 'teamcard-opened' );
					} );
				}
			} );
			wrap.appendChild( button );
		} );
		const showformer = 'Show Former';
		const hideformer = 'Hide Former';
		const showformerShort = 'Former';
		const showsubs = 'Show Substitutes';
		const hidesubs = 'Hide Substitutes';
		const showsubsShort = 'Subs';
		document.querySelectorAll( '.teamcard-former-toggle-button' ).forEach( ( wrap ) => {
			const teamcard = wrap.closest( '.teamcard' );
			const button = document.createElement( 'button' );
			button.classList.add( 'btn', 'btn-secondary', 'btn-small' );
			let width = 156;
			if ( typeof wrap.dataset.width !== 'undefined' ) {
				width = parseInt( wrap.dataset.width );
				if ( width < 156 ) {
					button.innerHTML = showformerShort;
				} else {
					button.innerHTML = showformer;
				}
			} else {
				button.innerHTML = showformer;
			}
			button.style.width = width + 'px';
			button.dataset.width = width;
			button.addEventListener( 'click', () => {
				if ( teamcard.classList.contains( 'teamcard-former-opened' ) ) {
					teamcard.querySelectorAll( '.teamcard-former-toggle-button button' ).forEach( ( btn ) => {
						if ( typeof btn.dataset.width !== 'undefined' ) {
							const btnWidth = parseInt( btn.dataset.width );
							if ( btnWidth < 156 ) {
								btn.innerHTML = showformerShort;
							} else {
								btn.innerHTML = showformer;
							}
						}
					} );
					teamcard.classList.remove( 'teamcard-former-opened' );
				} else {
					teamcard.querySelectorAll( '.teamcard-former-toggle-button button' ).forEach( ( btn ) => {
						btn.innerHTML = hideformer;
					} );
					teamcard.querySelectorAll( '.teamcard-subs-toggle-button button' ).forEach( ( btn ) => {
						if ( typeof btn.dataset.width !== 'undefined' ) {
							const btnWidth = parseInt( btn.dataset.width );
							if ( btnWidth < 156 ) {
								btn.innerHTML = showsubsShort;
							} else {
								btn.innerHTML = showsubs;
							}
						}
					} );
					teamcard.classList.remove( 'teamcard-subs-opened' );
					teamcard.classList.add( 'teamcard-former-opened' );
				}
			} );
			wrap.appendChild( button );
		} );

		document.querySelectorAll( '.teamcard-subs-toggle-button' ).forEach( ( wrap ) => {
			const teamcard = wrap.closest( '.teamcard' );
			const button = document.createElement( 'button' );
			button.classList.add( 'btn', 'btn-secondary', 'btn-small' );
			let width = 156;
			if ( typeof wrap.dataset.width !== 'undefined' ) {
				width = parseInt( wrap.dataset.width );
				if ( width < 156 ) {
					button.innerHTML = showsubsShort;
				} else {
					button.innerHTML = showsubs;
				}
			} else {
				button.innerHTML = showsubs;
			}
			button.style.width = width + 'px';
			button.dataset.width = width;
			button.addEventListener( 'click', () => {
				if ( teamcard.classList.contains( 'teamcard-subs-opened' ) ) {
					teamcard.querySelectorAll( '.teamcard-subs-toggle-button button' ).forEach( ( btn ) => {
						if ( typeof btn.dataset.width !== 'undefined' ) {
							const btnWidth = parseInt( btn.dataset.width );
							if ( btnWidth < 156 ) {
								btn.innerHTML = showsubsShort;
							} else {
								btn.innerHTML = showsubs;
							}
						}
					} );
					teamcard.classList.remove( 'teamcard-subs-opened' );
				} else {
					teamcard.querySelectorAll( '.teamcard-subs-toggle-button button' ).forEach( ( btn ) => {
						btn.innerHTML = hidesubs;
					} );
					teamcard.querySelectorAll( '.teamcard-former-toggle-button button' ).forEach( ( btn ) => {
						if ( typeof btn.dataset.width !== 'undefined' ) {
							const btnWidth = parseInt( btn.dataset.width );
							if ( btnWidth < 156 ) {
								btn.innerHTML = showformerShort;
							} else {
								btn.innerHTML = showformer;
							}
						}
					} );
					teamcard.classList.add( 'teamcard-subs-opened' );
					teamcard.classList.remove( 'teamcard-former-opened' );
				}
			} );
			wrap.appendChild( button );
		} );
		const showactive = 'Show Active';
		const showactiveShort = 'Active';
		document.querySelectorAll( '.teamcard-active-toggle-button' ).forEach( ( wrap ) => {
			const teamcard = wrap.closest( '.teamcard' );
			const button = document.createElement( 'button' );
			button.classList.add( 'btn', 'btn-secondary', 'btn-small' );
			let width = 156;
			if ( typeof wrap.dataset.width !== 'undefined' ) {
				width = parseInt( wrap.dataset.width );
				if ( width < 156 ) {
					button.innerHTML = showactiveShort;
				} else {
					button.innerHTML = showactive;
				}
			} else {
				button.innerHTML = showactive;
			}
			button.style.width = width + 'px';
			button.dataset.width = width;
			button.addEventListener( 'click', () => {
				if ( teamcard.classList.contains( 'teamcard-former-opened' ) || teamcard.classList.contains( 'teamcard-subs-opened' ) ) {
					teamcard.classList.remove( 'teamcard-former-opened' );
					teamcard.classList.remove( 'teamcard-subs-opened' );
					teamcard.querySelectorAll( '.teamcard-former-toggle-button button' ).forEach( ( btn ) => {
						if ( typeof btn.dataset.width !== 'undefined' ) {
							const btnWidth = parseInt( btn.dataset.width );
							if ( btnWidth < 156 ) {
								btn.innerHTML = showformerShort;
							} else {
								btn.innerHTML = showformer;
							}
						}
					} );
					teamcard.querySelectorAll( '.teamcard-subs-toggle-button button' ).forEach( ( btn ) => {
						if ( typeof btn.dataset.width !== 'undefined' ) {
							const btnWidth = parseInt( btn.dataset.width );
							if ( btnWidth < 156 ) {
								btn.innerHTML = showsubsShort;
							} else {
								btn.innerHTML = showsubs;
							}
						}
					} );
				}
			} );
			wrap.appendChild( button );
		} );
	}
};
liquipedia.core.modules.push( 'teamcard' );

/*******************************************************************************
 * Template(s): Tournaments table
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.tournamentstable = {
	init: function() {
		if ( document.querySelector( '.tournamentstable' ) !== null ) {
			mw.loader.using( 'jquery.tablesorter' ).then( () => {
				if ( $.fn.tablesorter ) {
					$( '.tournamentstable' ).tablesorter( { sortList: [ { 1: 'desc' }, { 0: 'desc' } ] } );
				} else {
					// eslint-disable-next-line no-console
					console.error( 'Table sorter timed out :(' );
				}
			} );
		}
	}
};
liquipedia.core.modules.push( 'tournamentstable' );

/*******************************************************************************
 * Template(s): Participants Tables
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.participantstable = {
	init: function() {
		if ( document.querySelector( '.participants-table-scroller' ) !== null ) {
			document.querySelectorAll( '.participants-table-button-left' ).forEach( ( buttonLeft ) => {
				buttonLeft.classList.add( 'inactive' );
				buttonLeft.addEventListener( 'click', function() {
					if ( window.innerWidth < 600 ) {
						const scroller = this.closest( '.participants-table-wrapper' ).querySelector( '.participants-table-scroller' );
						scroller.scrollLeft = scroller.scrollLeft - 0.83 * window.innerWidth;
					}
				} );
			} );
			document.querySelectorAll( '.participants-table-button-right' ).forEach( ( buttonRight ) => {
				buttonRight.addEventListener( 'click', function() {
					if ( window.innerWidth < 600 ) {
						const scroller = this.closest( '.participants-table-wrapper' ).querySelector( '.participants-table-scroller' );
						scroller.scrollLeft = scroller.scrollLeft + 0.83 * window.innerWidth;
					}
				} );
			} );
			document.querySelectorAll( '.participants-table-scroller' ).forEach( ( scroller ) => {
				scroller.addEventListener( 'scroll', function() {
					const buttonLeft = this.closest( '.participants-table-wrapper' ).querySelector( '.participants-table-button-left' );
					buttonLeft.classList.remove( 'inactive' );
					const buttonRight = this.closest( '.participants-table-wrapper' ).querySelector( '.participants-table-button-right' );
					buttonRight.classList.remove( 'inactive' );
					if ( this.scrollLeft === 0 ) {
						buttonLeft.classList.add( 'inactive' );
					}
					if ( this.scrollLeft === this.scrollWidth - this.clientWidth ) {
						buttonRight.classList.add( 'inactive' );
					}
				} );
			} );
		}
	}
};
liquipedia.core.modules.push( 'participantstable' );

/*******************************************************************************
 * Template(s): Heroes portal on the Heroes of the Storm wiki
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.heroesportal = {
	init: function() {
		document.querySelectorAll( '.hexagon-button' ).forEach( ( button ) => {
			button.addEventListener( 'click', function() {
				const hexagon = this.closest( '.hexagon' );
				if ( hexagon.classList.contains( 'show-' + this.dataset.show ) ) {
					hexagon.classList.remove( 'show-' + this.dataset.show );
				} else {
					hexagon.classList.add( 'show-' + this.dataset.show );
				}
			} );
		} );
	}
};
liquipedia.core.modules.push( 'heroesportal' );

/*******************************************************************************
 * Template(s): Deck tables
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.decktables = {
	init: function() {
		if ( document.querySelector( '.decktable' ) !== null ) {
			mw.loader.using( 'jquery.tablesorter' ).then( () => {
				if ( $.fn.tablesorter ) {
					$( '.decktable' ).tablesorter( { sortList: [ { 3: 'asc' }, { 2: 'asc' } ] } );
				} else {
					// eslint-disable-next-line no-console
					console.error( 'Table sorter timed out :(' );
				}
			} );
		}
	}
};
liquipedia.core.modules.push( 'decktables' );

/*******************************************************************************
 * Template(s): Talent template
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.talenttemplate = {
	init: function() {
		let talent = document.getElementById( 'talent-1' );
		if ( talent !== null ) {
			let talentContent = document.getElementById( 'talent-1-content' );
			document.querySelectorAll( '.talent' ).forEach( ( element ) => {
				element.addEventListener( 'mouseover', function() {
					this.style.cursor = 'pointer';
					this.style.border = '4px solid #e5c83e';
				} );
				element.addEventListener( 'mouseleave', function() {
					if ( this.id !== talent.id ) {
						this.style.border = '4px solid #f9f9f9';
					}
				} );
				element.addEventListener( 'click', function() {
					talent.style.border = '4px solid #f9f9f9';
					this.style.border = '4px solid #e5c83e';
					if ( talentContent !== null ) {
						talentContent.style.display = 'none';
					}
					talentContent = document.getElementById( this.id + '-content' );
					if ( talentContent !== null ) {
						talentContent.style.display = '';
					}
					talent = this;
				} );
			} );
		}
	}
};
liquipedia.core.modules.push( 'talenttemplate' );

/*******************************************************************************
 * Template(s): WC3 Creep Spots
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.creepspot = {
	init: function() {
		if ( document.querySelector( '.creep-spot' ) !== null ) {
			mw.loader.using( 'skins.' + mw.config.get( 'skin' ) + '.scripts' ).then( () => {
				document.querySelectorAll( '.creep-spot' ).forEach( ( cs ) => {
					const $this = $( cs );
					const options = {
						content: $this.find( '.creep-spot-popup-body' ).html(),
						html: true,
						placement: 'bottom',
						template: '<div class="popover" role="tooltip" style="max-width:400px;"><div class="arrow"></div><h3 class="popover-header"></h3><div class="popover-body"></div></div>',
						title: $this.find( '.creep-spot-popup-header' ).html(),
						trigger: 'focus',
						sanitize: false
					};
					$this
						.attr( 'tabindex', '0' )
						.popover( options );
				} );
			} );
		}
	}
};
liquipedia.core.modules.push( 'creepspot' );

/*******************************************************************************
 * Template(s): Toggle area
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.togglearea = {
	init: function() {
		document.querySelectorAll( '.toggle-area' ).forEach( ( area ) => {
			area.querySelectorAll( '.toggle-area-button' ).forEach( ( btn ) => {
				btn.addEventListener( 'click', () => {
					area.classList.remove( 'toggle-area-' + area.dataset.toggleArea );
					area.dataset.toggleArea = btn.dataset.toggleAreaBtn;
					area.classList.add( 'toggle-area-' + btn.dataset.toggleAreaBtn );
				} );
			} );
		} );
	}
};
liquipedia.core.modules.push( 'togglearea' );

/*******************************************************************************
 * Template(s): Console helper
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.console = {
	init: function() {
		window.c = liquipedia.console;
		liquipedia.console.selfXSSWarning();
	},
	selfXSSWarning: function() {
		const heading = 'Self-XSS';
		const message = '\nDo not paste any code into this window unless you know what you are doing!\nPasting code into this window can lead to other people gaining access to your account and other private data!\nSee https://en.wikipedia.org/wiki/Self-XSS for more information.';
		liquipedia.console.info( message, heading );
	},
	getStyles: function( main, sub ) {
		return {
			display: 'block',
			padding: '10px',
			margin: '0 10px 0 0',
			'background-color': sub,
			color: main,
			'border-left': '5px solid ' + main
		};
	},
	getParsedStyleString: function( styles ) {
		let style = '';
		for ( const key in styles ) {
			style += key + ':' + styles[ key ] + ';';
		}
		return style;
	},
	error: function( text, heading ) {
		if ( heading === null ) {
			heading = 'Liquipedia Error';
		}
		const styles = liquipedia.console.getStyles( '#ff0000', '#ffcccc' );
		const style = liquipedia.console.getParsedStyleString( styles );
		// eslint-disable-next-line no-console
		console.error( '%c' + heading + ':%c' + text, style + 'font-weight:bold;font-size:200%;', style + 'padding-top:0;font-size:150%;' );
	},
	info: function( text, heading ) {
		if ( heading === null ) {
			heading = 'Liquipedia Info';
		}
		const styles = liquipedia.console.getStyles( '#0000ff', '#ccccff' );
		const style = liquipedia.console.getParsedStyleString( styles );
		// eslint-disable-next-line no-console
		console.info( '%c' + heading + ':%c' + text, style + 'font-weight:bold;font-size:200%;', style + 'padding-top:0;font-size:150%;' );
	},
	log: function( text, heading ) {
		if ( heading === null ) {
			heading = 'Liquipedia Log';
		}
		const styles = liquipedia.console.getStyles( '#042b4c', '#ffffff' );
		const style = liquipedia.console.getParsedStyleString( styles );
		// eslint-disable-next-line no-console
		console.log( '%c' + heading + ':%c' + text, style + 'font-weight:bold;font-size:200%;', style + 'padding-top:0;font-size:150%;' );
	},
	warn: function( text, heading ) {
		if ( heading === null ) {
			heading = 'Liquipedia Warning';
		}
		const styles = liquipedia.console.getStyles( '#666600', '#ffffcc' );
		const style = liquipedia.console.getParsedStyleString( styles );
		// eslint-disable-next-line no-console
		console.warn( '%c' + heading + ':%c' + text, style + 'font-weight:bold;font-size:200%;', style + 'padding-top:0;font-size:150%;' );
	}
};
liquipedia.core.modules.push( 'console' );

/*******************************************************************************
 * Template(s): Eventtracker
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.tracker = {
	init: function() {
		// Only send a tracking hit on every 100th page load on average to not overload our GA limits
		liquipedia.tracker.isTracking = true; // ( Math.random() < 0.01 );
		liquipedia.tracker.setup();
	},
	isTracking: false,
	track: function( subject, nonInteraction ) {
		if ( liquipedia.tracker.isTracking ) {
			if ( typeof nonInteraction === 'undefined' ) {
				nonInteraction = false;
			}
			let eventType = 'user event ';
			if ( nonInteraction ) {
				eventType += 'passive';
			} else {
				eventType += 'active';
			}
			_paq.push( [
				'trackEvent',
				eventType,
				'click',
				subject,
				1
			] );
			gtag( 'event', 'click', {
				// eslint-disable-next-line camelcase
				event_category: subject,
				// eslint-disable-next-line camelcase
				non_interaction: nonInteraction,
				// eslint-disable-next-line camelcase
				send_to: 'UA-576564-4'
			} );
		}
	},
	setup: function() {
		document.querySelectorAll( '#sidebar-toc a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Sidebar TOC item clicked', true );
			} );
		} );
		document.querySelectorAll( '#scroll-wrapper-toc a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Mobile TOC item clicked', true );
			} );
		} );
		document.querySelectorAll( '#toc a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'In Content TOC item clicked', true );
			} );
		} );
		document.querySelectorAll( '.lakesideview-menu-share' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Share link clicked', true );
			} );
		} );
		document.querySelectorAll( '.lakesideview-menu-share a[data-type=twitter]' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Share link clicked (twitter)' );
			} );
		} );
		document.querySelectorAll( '.lakesideview-menu-share a[data-type=facebook]' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Share link clicked (facebook)' );
			} );
		} );
		document.querySelectorAll( '.lakesideview-menu-share a[data-type=reddit]' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Share link clicked (reddit)' );
			} );
		} );
		document.querySelectorAll( '.lakesideview-menu-share a[data-type=qq]' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Share link clicked (qq)' );
			} );
		} );
		document.querySelectorAll( '.lakesideview-menu-share a[data-type=vk]' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Share link clicked (vk)' );
			} );
		} );
		document.querySelectorAll( '.lakesideview-menu-share a[data-type=weibo]' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Share link clicked (weibo)' );
			} );
		} );
		document.querySelectorAll( '.lakesideview-menu-share a[data-type=whatsapp]' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Share link clicked (whatsapp)' );
			} );
		} );
		document.querySelectorAll( '#mw-fr-submit-accept' ).forEach( ( node ) => {
			if ( !node.disabled ) {
				node.addEventListener( 'click', () => {
					liquipedia.tracker.track( 'Revision accepted' );
				} );
			}
		} );
		document.querySelectorAll( '#ca-purge a, #ca-purge-mobile a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Page manually purged' );
			} );
		} );
		document.querySelectorAll( 'input[name=wpUpload]' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'File Upload initiated' );
			} );
		} );
		document.querySelectorAll( '.editButtons #wpPreview' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Preview button clicked' );
			} );
		} );
		document.querySelectorAll( '.editButtons #wpSave' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Save button clicked' );
			} );
		} );
		document.querySelectorAll( '.nav a.dropdown-toggle' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Navbar toggle clicked' );
			} );
		} );
		document.querySelectorAll( '#todo-list a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'TODO list item clicked' );
			} );
		} );
		document.addEventListener( 'keypress', ( event ) => {
			if ( event.keyCode === 116 ) {
				liquipedia.tracker.track( 'F5 Button pressed', true );
			}
		} );
		document.querySelectorAll( '#brand-logo' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Liquipedia logo clicked' );
			} );
		} );
		document.querySelectorAll( '#pt-createaccount a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Create account link clicked' );
			} );
		} );
		document.querySelectorAll( '#pt-createaccount-mobile a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Create account link clicked (mobile)' );
			} );
		} );
		document.querySelectorAll( '#pt-login a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Login link clicked' );
			} );
		} );
		document.querySelectorAll( '#pt-login-mobile a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Login link clicked (mobile)' );
			} );
		} );
		document.querySelectorAll( '#searchInput' ).forEach( ( node ) => {
			node.addEventListener( 'keypress', () => {
				liquipedia.tracker.track( 'Search term entered' );
			} );
		} );
		document.querySelectorAll( '#searchInput-mobile' ).forEach( ( node ) => {
			node.addEventListener( 'keypress', () => {
				liquipedia.tracker.track( 'Search term entered (mobile)' );
			} );
		} );
		document.querySelectorAll( '#brand-menu-toggle' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Brand menu toggled' );
			} );
		} );
		document.querySelectorAll( '#brand-menu a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Brand menu link clicked' );
			} );
		} );
		document.querySelectorAll( '#trending-pages-menu-toggle' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Trending pages menu toggled' );
			} );
		} );
		document.querySelectorAll( '#trending-pages-menu a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Trending pages menu link clicked' );
			} );
		} );
		document.querySelectorAll( '#tournaments-menu-toggle' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Tournaments menu toggled' );
			} );
		} );
		document.querySelectorAll( '#tournaments-menu-upcoming a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Tournaments menu link clicked (upcoming)' );
			} );
		} );
		document.querySelectorAll( '#tournaments-menu-ongoing a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Tournaments menu link clicked (ongoing)' );
			} );
		} );
		document.querySelectorAll( '#tournaments-menu-completed a' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Tournaments menu link clicked (completed)' );
			} );
		} );
		document.querySelectorAll( '#contribute-menu-toggle' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Contribute menu toggled' );
			} );
		} );
		document.querySelectorAll( '#contribute-menu-edit-an-article' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Contribute menu link clicked (edit an article)' );
			} );
		} );
		document.querySelectorAll( '#contribute-menu-create-an-article' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Contribute menu link clicked (create an article)' );
			} );
		} );
		document.querySelectorAll( '#contribute-menu-help-portal' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Contribute menu link clicked (help portal)' );
			} );
		} );
		document.querySelectorAll( '#contribute-menu-chat-with-us' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Contribute menu link clicked (chat with us)' );
			} );
		} );
		document.querySelectorAll( '#contribute-menu-feedback-thread' ).forEach( ( node ) => {
			node.addEventListener( 'click', () => {
				liquipedia.tracker.track( 'Contribute menu link clicked (feedback thread)' );
			} );
		} );
		if ( mw.config.get( 'wgNamespaceNumber' ) === -1 && mw.config.get( 'wgCanonicalSpecialPageName' ) === 'StreamPage' ) {
			document.querySelectorAll( '#refresh' ).forEach( ( node ) => {
				node.addEventListener( 'click', () => {
					liquipedia.tracker.track( 'Refresh button clicked (Special:StreamPage)' );
				} );
			} );
		}

		if ( window.localStorage.getItem( 'LiquipediaTheme' ) === 'dark' ) {
			liquipedia.tracker.track( 'Page view with dark theme enabled' );
		} else if ( window.localStorage.getItem( 'LiquipediaTheme' ) === 'light' ) {
			liquipedia.tracker.track( 'Page view with light theme enabled' );
		} else if ( window.localStorage.getItem( 'LiquipediaTheme' ) === 'system' ) {
			liquipedia.tracker.track( 'Page view with auto theme enabled' );
		}
	}
};
liquipedia.core.modules.push( 'tracker' );

/*******************************************************************************
 * Template(s): Custom Lua Errors
 * Author(s): iMarbot
 ******************************************************************************/
liquipedia.customLuaErrors = {
	init: function() {
		mw.loader.using( 'jquery.ui', () => {
			const $dialog = $( '<div>' ).dialog( {
				title: 'Script error',
				autoOpen: false
			} );
			$( '.scribunto-error' ).each( function() {
				try {
					const parsedError = JSON.parse( this.innerHTML.toString().replace( /Lua error(: | in )/, '' ).slice( 0, -1 ) );
					const $backtraceList = $( '<ol>' ).addClass( 'scribunto-trace' );
					parsedError.stackTrace.forEach( ( stackItem ) => {
						const $backtraceItem = $( '<li>' );
						const $prefix = $( '<b>' );
						const prefixText = $( '<div>' ).html( stackItem.prefix ).text();
						if ( stackItem.link instanceof Object ) {
							$( '<a>' )
								.text( prefixText )
								.attr( 'href', '/' + stackItem.link.wiki + '/index.php?title=' + stackItem.link.title + '&action=edit#mw-ce-l' + stackItem.link.ln )
								.attr( 'target', '_blank' )
								.appendTo( $prefix );
						} else {
							$prefix.text( prefixText );
						}
						$backtraceItem.append( $prefix );
						$backtraceItem.append( document.createTextNode( ': ' + $( '<div>' ).html( stackItem.content ).text() ) );
						$backtraceItem.appendTo( $backtraceList );
					} );
					const $errorDiv = $( '<div>' ).append(
						$( '<p>' ).text( parsedError.errorShort )
					).append(
						$( '<p>' ).text( 'Backtrace:' )
					).append(
						$backtraceList
					);
					const $newError = $( '<span>' ).text( parsedError.errorShort ).addClass( 'scribunto-error' );
					$( this ).replaceWith( $newError );
					$newError.on( 'click', ( e ) => {
						$dialog.dialog( 'close' ).html( $errorDiv ).dialog( 'option', 'position', [ e.clientX + 5, e.clientY + 5 ] ).dialog( 'open' );
					} );
				} catch {}
			} );
		} );
	}
};
liquipedia.core.modules.push( 'customLuaErrors' );
