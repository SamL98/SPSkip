var playbackHandler = undefined;

ObjC.choose(ObjC.classes.SPTNowPlayingPlaybackActionsHandlerImplementation, {
			onMatch: function(handler) {
				playbackHandler = handler;
				console.log(playbackHandler);
				return "stop";
			},
			onComplete: function() {
				console.log('Finished search');
			}
});
