
import emerald.all;
import core.sys.windows.windows;
import core.runtime : Runtime;

pragma(lib, "gdi32.lib");
pragma(lib, "user32.lib");

extern(Windows)
int WinMain(HINSTANCE theHInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
	test();
	int result = 0;
	Emerald app;
	try{
		Runtime.initialize();

		setEagerFlushing(true);

		version(REALTIME) {
			pragma(msg, "REALTIME");
			app = new EmeraldGPU();
		} else {
			pragma(msg, "STATIC");
			app = new EmeraldVK();
		}

		app.initialise();
		app.run();
	}catch(Throwable e) {
		log("exception: %s", e.msg);
		MessageBoxA(null, e.toString().toStringz, "Error", MB_OK | MB_ICONEXCLAMATION);
		result = -1;
	}finally{
		app.destroy();
		Runtime.terminate();
		flushLog();
	}
	return result;
}

void test() {
	static if(true) {

	}
}
