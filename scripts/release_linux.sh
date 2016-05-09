## ======================================================================== ##
## Copyright 2014-2016 Intel Corporation                                    ##
##                                                                          ##
## Licensed under the Apache License, Version 2.0 (the "License");          ##
## you may not use this file except in compliance with the License.         ##
## You may obtain a copy of the License at                                  ##
##                                                                          ##
##     http://www.apache.org/licenses/LICENSE-2.0                           ##
##                                                                          ##
## Unless required by applicable law or agreed to in writing, software      ##
## distributed under the License is distributed on an "AS IS" BASIS,        ##
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. ##
## See the License for the specific language governing permissions and      ##
## limitations under the License.                                           ##
## ======================================================================== ##

#!/bin/bash

#### Helper functions ####

# check version of symbols
function check_symbols
{
  for sym in `nm $1 | grep $2_`
  do
    version=(`echo $sym | sed 's/.*@@\(.*\)$/\1/p' | grep -E -o "[0-9]+"`)
    if [ ${#version[@]} -ne 0 ]; then
      #echo "version0 = " ${version[0]}
      #echo "version1 = " ${version[1]}
      if [ ${version[0]} -gt $3 ]; then
        echo "Error: problematic $2 symbol " $sym
        exit 1
      fi
      if [ ${version[1]} -gt $4 ]; then
        echo "Error: problematic $2 symbol " $sym
        exit 1
      fi
    fi
  done
}

#### Set variables for script ####

export ROOT_DIR=$PWD

DEP_LOCATION=http://sdvis.org/~jdamstut/deps
TBB_TARBALL=embree-2.9.0.x86_64.linux.tar.gz
EMBREE_TARBALL=tbb44_20160413oss_lin.tgz

# set compiler
export CC=gcc
export CXX=g++

# to make sure we do not include nor link against wrong TBB
unset CPATH
unset LIBRARY_PATH
unset LD_LIBRARY_PATH

#### Fetch dependencies (TBB+Embree) ####

mkdir deps
rm -rf deps/*
cd deps

# TBB
wget $DEP_LOCATION/$TBB_TARBALL
tar -xaf $TBB_TARBALL
rm $TBB_TARBALL

# Embree
wget $DEP_LOCATION/$EMBREE_TARBALL
tar -xaf $EMBREE_TARBALL
rm $EMBREE_TARBALL

cd $ROOT_DIR
ln -snf deps/tbb* tbb
ln -snf deps/embree* embree

TBB_PATH_LOCAL=$ROOT_DIR/tbb
export embree_DIR=$ROOT_DIR/embree

#### Build OSPRay ####

mkdir -p build_release
cd build_release
# make sure to use default settings
rm -f CMakeCache.txt
rm -f ospray/version.h

# set release and RPM settings
cmake \
-D OSPRAY_BUILD_ISA=ALL \
-D OSPRAY_BUILD_MIC_SUPPORT=OFF \
-D OSPRAY_BUILD_COI_DEVICE=OFF \
-D OSPRAY_BUILD_MPI_DEVICE=OFF \
-D OSPRAY_USE_EXTERNAL_EMBREE=ON \
-D USE_IMAGE_MAGICK=OFF \
-D OSPRAY_ZIP_MODE=OFF \
-D CMAKE_INSTALL_PREFIX=$ROOT_DIR/install \
-D TBB_ROOT=$TBB_PATH_LOCAL \
..

# create RPM files
make -j `nproc` preinstall

check_symbols libospray.so GLIBC   2 4
check_symbols libospray.so GLIBCXX 3 4
check_symbols libospray.so CXXABI  1 3
make -j `nproc` package

# read OSPRay version
OSPRAY_VERSION=`sed -n 's/#define OSPRAY_VERSION "\(.*\)"/\1/p' ospray/version.h`

# rename RPMs to have component name before version
for i in ospray-${OSPRAY_VERSION}-1.*.rpm ; do 
  newname=`echo $i | sed -e "s/ospray-\(.\+\)-\([a-z_]\+\)\.rpm/ospray-\2-\1.rpm/"`
  mv $i $newname
done

tar czf ospray-${OSPRAY_VERSION}.x86_64.rpm.tar.gz ospray-*-${OSPRAY_VERSION}-1.x86_64.rpm

# change settings for zip mode
cmake \
-D OSPRAY_ZIP_MODE=ON \
-D CMAKE_INSTALL_INCLUDEDIR=include \
-D CMAKE_INSTALL_LIBDIR=lib \
-D CMAKE_INSTALL_DOCDIR=doc \
-D CMAKE_INSTALL_BINDIR=bin \
..

# create tar.gz files
make -j `nproc` package

