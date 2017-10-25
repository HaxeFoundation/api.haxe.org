import Sys.*;
import sys.io.*;

class Utils {
    static public function env(name:String, def:String):String {
        return switch(getEnv(name)) {
            case null:
                def;
            case v:
                v;
        }
    }
    static public function runCommand(cmd:String, args:Array<String>):Void {
        println('run: $cmd $args');
        switch(command(cmd, args)) {
            case 0:
                //pass
            case exitCode:
                exit(exitCode);
        }
    }
    static public function commandOutput(cmd:String, args:Array<String>):String {
        var p = new Process(cmd, args);
        var exitCode = p.exitCode();
        var output = p.stdout.readAll().toString();
        p.close();
        if (exitCode != 0)
            exit(exitCode);
        return output;
    }
}