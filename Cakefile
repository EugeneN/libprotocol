{print} = require 'util'
{spawn} = require 'child_process'
fs = require 'fs'


build = (callback) ->
    child = spawn 'coffee', ['-c', '-o', 'out/', 'src/']

    child.stderr.on 'data', (data) ->
        console.error data.toString()

    child.stdout.on 'data', (data) ->
        console.info data.toString()

    child.on 'exit', (rc) ->
        console.log "Build done with rc =", rc
        callback?() if rc is 0

task 'build', '', -> build()
