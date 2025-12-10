import haxe.*;
import sys.FileSystem.*;
import sys.io.File.*;
import haxe.io.Path;
import Sys.*;
import promhx.*;
import Utils.*;
import thx.semver.*;
using Lambda;

typedef GhVersion = {
    name:String,
    tag_name:String,
    prerelease:Bool,
}

class Gen {
    inline static var htmlDir = "html";
    inline static var xmlDir = "xml";
    inline static var xmlTagsDir = "xml/refs/tags";
    inline static var developmentBranch = "development";
    inline static var themeDir = "theme";
    inline static var origin = "https://api.haxe.org";

    static function requestUrl(url:String):Promise<String> {
        var d = new Deferred();
        var http = new Http(url);
        http.addHeader("User-Agent", "api.haxe.org generator");
        switch (getEnv("GH_BASICAUTH")) { // GH_BASICAUTH should be in the form of "username:token"
            case null:
                //pass
            case token:
                var encoded = haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(token),true);
                http.addHeader("Authorization", 'Basic ${encoded}');
        }
        http.onData = d.resolve;
        http.onError = function(err){
            d.throwError(err + "\n" + http.responseData);
        }
        http.request(false);
        return d.promise();
    }

    static function getVersionInfo():Promise<Array<GhVersion>> {
        return requestUrl("https://api.github.com/repos/HaxeFoundation/haxe/releases?per_page=200")
            .then(Json.parse);
    }

    static function getLatestVersion(ghVerions:Array<GhVersion>):String {
        var v = [for (v in ghVerions) if (!v.prerelease) v.name];
        v.sort(function(v0, v1) {
            var v0:Version = v0;
            var v1:Version = v1;
            return if (v0 == v1)
                0;
            else if (v0 < v1)
                1;
            else
                -1;
        });
        return v[0];
    }

    static function versionedPath(version:String):String {
        return Path.join(["v", version]);
    }

    static function getDox():Array<String>->Void {
        final doxDir = sys.FileSystem.absolutePath("libs/dox");
        final doxBin = Path.join([doxDir, "cpp/Dox"]);
        if (!exists(doxBin)) {
            runCommand("haxe", ["dox.hxml"]);
        }
        return function(args:Array<String>):Void {
            var cwd = Sys.getCwd();
            Sys.setCwd(doxDir);
            runCommand(doxBin, args);
            Sys.setCwd(cwd);
        }
    }

    static function generateHTML(
        versionInfo:Array<GhVersion>
    ):Void {
        var dox = getDox();
        var latestVersion = getLatestVersion(versionInfo);
        if (!exists('$xmlDir/$latestVersion') && !exists('$xmlTagsDir/$latestVersion')) {
            throw 'Missing xmls for $latestVersion"';
        }
        deleteRecursive(htmlDir);
        createDirectory(htmlDir);
        function generate(dir:String) {
            for (item in readDirectory(dir)) {
                var path = Path.join([dir, item]);
                if (!isDirectory(path))
                    continue;
                var version = item;
                var version_long = version;
                var versionDir, gitRef;
                switch(versionInfo.find(function(v) return v.name == version)) {
                    case null: // it is not a release, but a branch
                        gitRef = version;
                        versionDir = versionedPath(gitRef);
                        if(version != developmentBranch) 
                            continue;
                        try {
                            var info:DocInfo = Json.parse(getContent(Path.join([path, "info.json"])));
                            version_long = '${version} @ ${info.commit.substr(0, 7)}';
                        } catch (e:Dynamic) {}
                    case v:
                        gitRef = v.tag_name;
                        versionDir = versionedPath(version);
                };
                var outDir = Path.join([htmlDir, versionDir]);
                createDirectory(outDir);
                var args = [
                    "-theme", absolutePath(themeDir),
                    "--title", 'Haxe $version API',
                    "-D", "website", "https://haxe.org/",
                    "-D", "version", version_long,
                    "-D", "googleAnalytics", "UA-30943311-8",
                    "-D", "source-path", 'https://github.com/HaxeFoundation/haxe/blob/${gitRef}/std/',
                    "-i", absolutePath(path),
                    "-o", absolutePath(outDir),
                    "-ex", "microsoft",
                    "-ex", "javax",
                    "-ex", "cs.internal",
                ];
                if (origin != null) {
                    args = args.concat([
                        "-D", "origin", Path.join([origin, versionDir]),
                    ]);
                }
                dox(args);
                if (version == latestVersion) {
                    var args = args.concat([
                        "-o", absolutePath(htmlDir),
                    ]);
                    if (origin != null) {
                        args = args.concat([
                            "-D", "origin", origin,
                        ]);
                    }
                    dox(args);
                }
            }
        }
        generate(xmlTagsDir);
        generate(xmlDir);
    }

    static function main():Void {
        getVersionInfo().then(function(versionInfo){
            generateHTML(versionInfo);
        });
    }
}
