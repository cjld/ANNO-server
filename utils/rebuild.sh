cd ..
server_path=$(lsc -e 'require(\./config).image-server-dir' -p)
[ -z $dont_drop ] && mongo < ./utils/drop-database.js
lsc ./utils/add.ls $server_path
