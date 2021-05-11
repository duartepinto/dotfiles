# Setting default JDK to version 1.8. Reason: Because of Scala
export JAVA_HOME=`/usr/libexec/java_home -v 1.8`

export PATH="$HOME/.rbenv/shims:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
