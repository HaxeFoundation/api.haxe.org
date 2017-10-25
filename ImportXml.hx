import Utils.*;
import Config.*;
import haxe.*;
import haxe.io.*;
import Sys.*;
import sys.FileSystem.*;
import sys.io.File.*;

class ImportXml {
    static function main():Void {
        var xmlPath = switch(Sys.args()) {
            case null, []:
                throw "expect path to api xml folder";
            case [xmlPath]:
                xmlPath;
            case _:
                throw "expect path to api xml folder";
        }

        var docInfo:DocInfo = Json.parse(getContent(Path.join([xmlPath, "info.json"])));

        // replace the "xml/$branch" folder
        var targetDir = Path.join(["xml", docInfo.branch]);
        deleteRecursive(targetDir);
        createDirectory(targetDir);
        for (item in readDirectory(xmlPath)) {
            copy(Path.join([xmlPath, item]), Path.join([targetDir, item]));
        }

        // commit
        if (username != null)
            runCommand("git", ["config", "--local", "user.name", username]);
        if (email != null)
            runCommand("git", ["config", "--local", "user.email", email]);
        runCommand("git", ["add", "--all", targetDir]);
        runCommand("git", ["commit", "--allow-empty", "--quiet", "-m", 'import xml doc of ${docInfo.branch} (${docInfo.commit})']);

        // push
        if (remote == null) {
            println('GHP_REMOTE is not set, skip deploy.');
            return;
        }
        runCommand("git", ["push", remote]);
    }
}