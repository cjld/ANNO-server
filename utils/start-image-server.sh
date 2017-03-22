cd ..
server_port=$(lsc -e 'require(\./config).image-server-port' -p)
server_path=$(lsc -e 'require(\./config).image-server-dir' -p)

cd $server_path
http-server -p $server_port
