const playerStateClass = ObjC.classes.SPTPlayerState;

console.log("Scanning for player states");
ObjC.choose(playerStateClass, {
			onMatch: function(playerState) {
					//console.log('Found ', playerState);
					console.log(ptr(playerState));
				},
			onComplete: function() {
					console.log('Done searching');
				}
			});
