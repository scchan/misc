#!/bin/bash

git clone -b developer-preview https://github.com/GPUOpen-ProfessionalCompute-Tools/HIP.git 

git clone https://bitbucket.org/multicoreware/hcblas.git

git clone -b hiprng https://bitbucket.org/multicoreware/hcrng.git

git clone -b hip-hsaco  https://github.com/AMDComputeLibraries/MLOpen

git clone -b hip https://bitbucket.org/multicoreware/hipcaffe.git

echo "Visit and dwnload OpenCL compiler: http://ocltc.amd.com:8111/viewLog.html?buildId=16296209&buildTypeId=bt4&tab=artifacts !!"
