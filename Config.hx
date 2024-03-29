import Utils.*;

class Config {
    static public var htmlDir  = env("GHP_HTMLDIR",  "html");
    static public var remote   = env("GHP_REMOTE",   null); // should be in the form of https://token@github.com/account/repo.git
    static public var username = env("GHP_USERNAME", null);
    static public var email    = env("GHP_EMAIL",    null);
}