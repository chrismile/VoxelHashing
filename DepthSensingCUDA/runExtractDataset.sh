#!/bin/bash

# BSD 2-Clause License
#
# Copyright (c) 2021, Christoph Neuhauser
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

template_conf="D:/neuhauser/datasets/ScanNet/zParametersSens_template.txt"
config_file="D:/neuhauser/datasets/ScanNet/zParametersSens.txt"
tracking_conf="D:/neuhauser/datasets/ScanNet/zParametersTrackingDefault.txt"
dataset_folder="D:/neuhauser/datasets/ScanNet/raw/scans"
output_folder="D:/neuhauser/datasets/ScanNet/scans_VoxelHashing"

export PATH=$PATH:"/c/Users/ga42wis/Programming/C++/VoxelHashing/DepthSensingCUDA/x64/Release/"
export PATH=$PATH:"/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v7.5/bin/"
cd C:/Users/ga42wis/Programming/C++/VoxelHashing/DepthSensingCUDA

scenes=`ls $dataset_folder`

i=1
for scene_name in $scenes
do
    if [ -f "$config_file" ] && [ ! -d "tmp/scans_test/${scene_name}" ]; then
        rm $config_file
    fi
    
    echo "Processing ${scene_name}..."
    base_dir="$output_folder/${scene_name}"
    path_sens="$dataset_folder/$scene_name/$scene_name.sens"
    
    if [ ! -d "$base_dir" ]; then
        mkdir "${base_dir}"
    fi
	
    cp $template_conf $config_file
    sed -i "s|path_sens|$path_sens|g" "$config_file"
    
    unzip "${dataset_folder}/$scene_name/${scene_name}_2d-label-filt.zip" -d "${base_dir}"
    
    ./x64/Release/DepthSensing.exe $config_file $tracking_conf
done
