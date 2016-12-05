#!/bin/bash

THREADS=64


# HIP
cd HIP
rm -rf build
mkdir build
cd build
make -j $THREADS
sudo make install
cd ../..


# hcblas
cd hcblas
rm -rf build
./build.sh
sudo apt-get purge hcblas
sudo dpkg -i install build/hcblas*deb
cd ..


# hcrng
cd hcrng
rm -rf build
./build.sh
sudo apt-get purge hcrng
sudo dpkg -i build/hcrng*deb
cd ..


# MLOpen
cd MLOpen
rm -rf build
mkdir build
cd build
cmake -DMLOPEN_BACKEND=HIP ..
make -j $THREADS
sudo make install
cd ../..


#caffe
cd hipcaffe
make clean
make -j  $THREADS
cd ..



