const sendAction = ObjC.classes.UIApplication["- sendAction:to:from:forEvent:"];
Interceptor.attach(sendAction.implementation, {
	onEnter: function(args) {
		var obj = new ObjC.Object(ptr(args[1]));
		console.log(obj.toString());
		console.log('\n******\n');
	}
});
