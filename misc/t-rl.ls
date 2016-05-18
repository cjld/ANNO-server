require! \readline

rl = readline.create-interface input:process.stdin

rl.on \line, -> console.log it
rl.on \close, -> console.log \close
