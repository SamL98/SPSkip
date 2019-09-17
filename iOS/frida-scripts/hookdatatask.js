const urlConnClass = ObjC.classes.NSURLSession;

Interceptor.attach(urlConnClass['- dataTaskWithRequest:completionHandler:'].implementation, {
	onEnter: function(args) {
		var req = new ObjC.Object(args[2]);
		console.log(req);
	}
});
