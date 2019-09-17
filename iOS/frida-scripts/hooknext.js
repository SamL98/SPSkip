const playerStateClass = ObjC.classes.SPTPlayerState;
const trackClass = ObjC.classes.SPTPlayerTrack;
const playerClass = ObjC.classes.SPTPlayerImpl;

var trackMeth = playerStateClass["- track"].implementation;
var uriMeth = trackClass["- URI"].implementation;

var trackSel = ObjC.selector("track");
var uriSel = ObjC.selector("URI");

console.log("Scanning for player states");
ObjC.choose(playerStateClass, {
			onMatch: function(playerState) {
					console.log('Found one');
					hookPlaybackFunctions(playerState);
					return "stop";
				},
			onComplete: function() {
					console.log('Done searching');
				}
			});
				
function hookPlaybackFunctions(playerState) {
	console.log('Hooking playback functions');

	const nextTrack = playerClass["- skipToNextTrackWithOptions:"];
	Interceptor.attach(nextTrack.implementation, {
		onEnter: function(options) {
			var track = new ObjC.Object(ptr(trackMeth(playerState, trackSel)));
			var uri = new ObjC.Object(ptr(uriMeth(track, uriSel)));
			console.log('Next, oldURI: ', uri);
		}
	});

	const prevTrack = playerClass["- skipToPreviousTrackWithOptions:"];
	Interceptor.attach(prevTrack.implementation, {
		onEnter: function(options) {
			console.log('Previous');
		}
	});

	console.log('Done hooking');
}
