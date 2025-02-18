public class Tuba.Host {

	// Open a URI in the user's default application
	public static bool open_uri (string _uri) {
		var uri = _uri;
		if (!(":" in uri))
			uri = "file://" + _uri;

		if (settings.strip_tracking)
			uri = Tracking.strip_utm (uri);
		debug (@"Opening URI: $uri");
		try {
			var success = AppInfo.launch_default_for_uri (uri, null);
			if (!success)
				throw new Oopsie.USER ("launch_default_for_uri() failed");
		}
		catch (Error e) {
			var launcher = new Gtk.UriLauncher (uri);
			launcher.launch.begin (app.active_window, null, (obj, res) => {
				try {
					launcher.launch.end (res);
				} catch (Error e) {
					warning (@"Error opening uri \"$uri\": $(e.message)");
				}
			});
		}
		return true;
	}

	public static void copy (string str) {
		Gdk.Display display = Gdk.Display.get_default ();
		if (display == null) return;

		display.get_clipboard ().set_text (str);
	}

	public static string get_uri_host (string uri) {
		var p1 = uri;
		if ("//" in uri)
			p1 = uri.split ("//")[1];

		return p1.split ("/")[0];
	}

	public async static string download (string url) throws Error {
		debug (@"Downloading file: $url…");

		var file_name = Path.get_basename (url);
		var dir_name = Path.get_dirname (url);

		var dir_path = Path.build_path (
			Path.DIR_SEPARATOR_S,
			Environment.get_user_cache_dir (), // Environment.get_user_special_dir (UserDirectory.DOWNLOAD),
			Build.DOMAIN,
			get_uri_host (dir_name));

		var file_path = Path.build_path (
			Path.DIR_SEPARATOR_S,
			dir_path,
			str_hash (dir_name).to_string () + file_name);

		var dir = File.new_for_path (dir_path);
		if (!dir.query_exists ())
			dir.make_directory_with_parents ();

		var file = File.new_for_path (file_path);

		if (!file.query_exists ()) {
			var msg = yield new Request.GET (url)
				.await ();

			var data = msg.response_body;
			FileOutputStream stream = yield file.create_async (FileCreateFlags.PRIVATE);
			yield stream.splice_async (data, OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET);

			debug (@"   OK: File written to: $file_path");
		}
		else
			debug ("   OK: File already exists");

		return file_path;
	}

}
