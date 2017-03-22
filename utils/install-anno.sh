#./install_ipython.sh
#./install_opencv.sh
#sudo apt-get install qt5-default
#./../package/install-nodejs.sh
#./../package/web/install-mongodb.sh

cd ~/anno
mkdir build-worker
cd build-worker
qmake ../worker
make
cd ../server
npm instsll
bower install
cd utils
./start-image-server.sh &
cd ..
gulp
npm run watch
