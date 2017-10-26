import haxe.*;
import sys.FileSystem.*;
import sys.io.File.*;
import haxe.io.Path;
import Sys.*;
import promhx.*;
import Utils.*;
import Config.*;
using Lambda;

typedef Version = {
    name:String,
    tag_name:String,
    prerelease:Bool,
}

class Gen {
    inline static var htmlDir = "html";
    inline static var xmlDir = "xml";
    inline static var themeDir = "theme";

    static function requestUrl(url:String):Promise<String> {
        var d = new Deferred();
        var http = new Http(url);
        http.addHeader("User-Agent", "api.haxe.org generator");
        switch (getEnv("GH_TOKEN")) {
            case null:
                //pass
            case token:
                http.addHeader("Authorization", 'Basic ${token}');
        }
        http.onData = d.resolve;
        http.onError = function(err){
            d.throwError(err + "\n" + http.responseData);
        }
        http.request(false);
        return d.promise();
    }

    static function getVersionInfo():Promise<Array<Version>> {
        return requestUrl("https://api.github.com/repos/HaxeFoundation/haxe/releases")
            .then(Json.parse);
    }

    static function getLatestVersion():Promise<String> {
        return requestUrl("https://api.github.com/repos/HaxeFoundation/haxe/releases/latest")
            .then(function(r) return Json.parse(r).name);
    }

    static function versionedPath(version:String):String {
        return Path.join(["v", version]);
    }

    static function generateHTML(
        versionInfo:Array<Version>,
        latestVersion:String
    ):Void {
        deleteRecursive(htmlDir);
        createDirectory(htmlDir);
        for (item in readDirectory(xmlDir)) {
            var path = Path.join([xmlDir, item]);
            if (!isDirectory(path))
                continue;

            var version = item;
            var version_long = version;
            var outDir, gitRef;
            switch(versionInfo.find(function(v) return v.name == version)) {
                case null: // it is not a release, but a branch
                    gitRef = version;
                    outDir = Path.join([htmlDir, versionedPath(gitRef)]);
                    try {
                        var info:DocInfo = Json.parse(getContent(Path.join([path, "info.json"])));
                        version_long = '${version} @ ${info.commit.substr(0, 7)}';
                    } catch (e:Dynamic) {}
                case v:
                    gitRef = v.tag_name;
                    outDir = Path.join([htmlDir, versionedPath(version)]);
            };
            createDirectory(outDir);
            runCommand("haxe", [
                "--cwd", "libs/dox",
                "-lib", "hxtemplo",
                "-lib", "hxparse",
                "-lib", "hxargs",
                "-lib", "markdown",
                "-cp", "src",
                "-dce", "no",
                "--run", "dox.Dox",
                "-theme", absolutePath(themeDir),
                "--title", 'Haxe $version API',
                "-D", "website", "https://haxe.org/",
                "-D", "version", version_long,
                "-D", "source-path", 'https://github.com/HaxeFoundation/haxe/blob/${gitRef}/std/',
                "-i", absolutePath(path),
                "-o", absolutePath(outDir),
                "-ex", "microsoft",
                "-ex", "javax",
                "-ex", "cs.internal",
            ]);

            if (version == latestVersion) {
                copyRecursive(outDir, htmlDir);
            }
        }

        if (cname != null)
            saveContent(Path.join([htmlDir, "CNAME"]), cname);
    }

    static function main():Void {
        var versionInfo, latestVersion;
        Promise.whenAll([
            getVersionInfo().then(function(v) {versionInfo = v; return null;}),
            getLatestVersion().then(function(v) {latestVersion = v; return null;})
        ]).then(function(_){
            generateHTML(versionInfo, latestVersion);
        });
    }
}