import Sys.*;
import sys.io.*;
using StringTools;

class DeployGhPages {
    static function env(name:String, def:String):String {
        return switch(getEnv(name)) {
            case null:
                def;
            case v:
                v;
        }
    }
    static function runCommand(cmd:String, args:Array<String>):Void {
        println('run: $cmd $args');
        switch(command(cmd, args)) {
            case 0:
                //pass
            case exitCode:
                exit(exitCode);
        }
    }
    static function commandOutput(cmd:String, args:Array<String>):String {
        var p = new Process(cmd, args);
        var exitCode = p.exitCode();
        var output = p.stdout.readAll().toString();
        p.close();
        if (exitCode != 0)
            exit(exitCode);
        return output;
    }
    static function main():Void {
        var root = getCwd();
        var sha = commandOutput("git", ["rev-parse", "HEAD"]).trim();
        var folder = env("GHP_FOLDER", "html");
        var remote = env("GHP_REMOTE", null); // should be in the form of https://token@github.com/account/repo.git
        var branch = env("GHP_BRANCH", "gh-pages");
        var username = env("GHP_USERNAME", "bot");
        var email = env("GHP_EMAIL", "no-reply@bot.net");
        setCwd(folder);
        runCommand("git", ["init"]);
        runCommand("git", ["config", "--local", "user.name", username]);
        runCommand("git", ["config", "--local", "user.email", email]);
        runCommand("git", ["remote", "add", "local", root]);
        runCommand("git", ["remote", "add", "remote", remote]);
        runCommand("git", ["fetch", "--all"]);
        runCommand("git", ["checkout", "--orphan", branch]);
        if (commandOutput("git", ["ls-remote", "--heads", "local", branch]).trim() != "") {
            runCommand("git", ["reset", "--soft", 'local/${branch}']);
        }
        if (commandOutput("git", ["ls-remote", "--heads", "remote", branch]).trim() != "") {
            runCommand("git", ["reset", "--soft", 'remote/${branch}']);
        }
        runCommand("git", ["add", "--all"]);
        runCommand("git", ["commit", "--allow-empty", "--quiet", "-m", 'deploy for ${sha}']);
        runCommand("git", ["push", "local", branch]);

        if (remote == null) {
            println('GHP_REMOTE is not set, skip deploy.');
            return;
        }
        setCwd(root);
        runCommand("git", ["push", remote, branch]);
    }
}