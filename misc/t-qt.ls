require! {
    \readline
    \child_process
}

add-endl = -> (JSON.stringify it) + '\n'

proc = child_process.spawn "/home/cjld/workspace/sumsang-test/build-sumsang-Desktop_Qt_5_6_0_GCC_64bit-Debug/sumsang", ['server']
proc_rl = readline.create-interface input:proc.stdout

proc_rl.on \line, -> console.log "get json:", JSON.parse it

proc.stdin.write add-endl {}
proc.stdin.write add-endl {cmd:'exit'}
