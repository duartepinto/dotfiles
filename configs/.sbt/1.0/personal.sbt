addCommandAlias("cd", "project")
addCommandAlias("restartconf", s"reStart --- -Dconfig.file=${System.getProperty("user.home")}/.sbt/application.conf")
