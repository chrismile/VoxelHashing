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

# Use MSYS2 on Windows to run this script. unzip and imagemagick needs to be
# installed using the following command:
# pacman -S unzip mingw-w64-x86_64-imagemagick

# Adapt these paths for your system.
dataset_folder="D:/neuhauser/datasets/ScanNet"
depth_sensing_cuda_folder="C:/Users/neuhauser/Programming/C++/VoxelHashing/DepthSensingCUDA"
#dataset_folder="C:/Users/chris/Programming/DL/relight_aug/datasets/ScanNet"
#depth_sensing_cuda_folder="C:/Users/chris/Programming/C++/VoxelHashing/DepthSensingCUDA"
#dataset_folder="/home/christoph/Programming/DL/relight_aug/datasets/ScanNet"
#depth_sensing_cuda_folder="/home/christoph/Programming/C++/VoxelHashing/DepthSensingCUDA"
export PATH=$PATH:"/c/Users/neuhauser/Programming/C++/VoxelHashing/DepthSensingCUDA/x64/Release/"
export PATH=$PATH:"/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v7.5/bin/"

template_conf="${dataset_folder}/zParametersSens_template.txt"
config_file="${dataset_folder}/zParametersSens.txt"
tracking_conf="${dataset_folder}/zParametersTrackingDefault.txt"
scans_folder="${dataset_folder}/raw/scans"
scenes_list_filename_train="${dataset_folder}/scannetv2_train.txt"
scenes_list_filename_val="${dataset_folder}/scannetv2_val.txt"
subset_folder="${dataset_folder}/scans_subset_VoxelHashing"
subset_list_folder_train="${subset_folder}/scans_subset_list_train"
subset_list_folder_val="${subset_folder}/scans_subset_list_val"
output_folder_tmp="${subset_folder}/scans_VoxelHashing_tmp"
output_folder_train="${subset_folder}/scene_train"
output_folder_val="${subset_folder}/scene_val"

cd "$depth_sensing_cuda_folder"

scenes=`ls $scans_folder`
readarray -t scenes_train < $scenes_list_filename_train
readarray -t scenes_val < $scenes_list_filename_val

if [ ! -d "$output_folder_tmp" ]; then
    mkdir $output_folder_tmp
fi
if [ ! -d "$output_folder_train" ]; then
    mkdir $output_folder_train
fi
if [ ! -d "$output_folder_val" ]; then
    mkdir $output_folder_val
fi

i=1
for scene_name in $scenes
do
    subset_list_file_train="${subset_list_folder_train}/${scene_name}.txt"
    subset_list_file_val="${subset_list_folder_val}/${scene_name}.txt"
    if [ ! -f "${subset_list_file_train}" ] && [ ! -f "${subset_list_file_val}" ]; then
        continue
    fi
    if [ -f "${subset_list_file_train}" ]; then
        subset_list_file="$subset_list_file_train"
    fi
    if [ -f "${subset_list_file_val}" ]; then
        subset_list_file="$subset_list_file_val"
    fi

    echo "Processing ${scene_name}..."

    # Create a new config file.
    if [ -f "$config_file" ]; then
        rm $config_file
    fi
    cp $template_conf $config_file

    # Add used files in scene to config file.
    orig_id_list=()
    cat $subset_list_file | tr -d "\r" | while read line
    do
        i=0
        for word in $line
        do
            if [ $i -eq 0 ]; then
                orig_id_list+=($word)
            fi
            i=$((i+1))
        done
    done
    orig_id_list_string="${orig_id_list[@]}"
    sed -i "s|shall_process_subset|true|g" "$config_file"
    sed -i "s|orig_id_list|$orig_id_list_string|g" "$config_file"

    # Edit the config file for running the program.
    base_dir="$output_folder_tmp/${scene_name}"
    path_sens="$scans_folder/$scene_name/$scene_name.sens"
    sed -i "s|path_sens|$path_sens|g" "$config_file"
    sed -i "s|output_folder_tmp|$output_folder_tmp|g" "$config_file"

    # Run program, output to output_folder_tmp
    if [ ! -d "$base_dir" ]; then
        mkdir "${base_dir}"
    fi
    ./x64/Release/DepthSensing.exe $config_file $tracking_conf

    # Set up the output folder.
    if [[ " ${scenes_train[@]} " =~ " ${scene_name} " ]]; then
        output_folder="$output_folder_train"
    fi
    if [[ " ${scenes_val[@]} " =~ " ${scene_name} " ]]; then
        output_folder="$output_folder_val"
    fi
    if [ ! -d "$output_folder/color" ]; then
        mkdir "$output_folder/color"
    fi
    if [ ! -d "$output_folder/label-filt" ]; then
        mkdir "$output_folder/label-filt"
    fi
    if [ ! -d "$output_folder/normal" ]; then
        mkdir "$output_folder/normal"
    fi
    if [ ! -d "$output_folder/mask" ]; then
        mkdir "$output_folder/mask"
    fi

    # Copy files to correct directory.
    cat $subset_list_file | tr -d "\r" | while read line
    do
        i=0
        for word in $line
        do
            if [ $i -eq 0 ]; then
                orig_idx=$word
            fi
            if [ $i -eq 1 ]; then
                idx=$word
            fi
            i=$((i+1))
        done

        unzip "${scans_folder}/$scene_name/${scene_name}_2d-label-filt.zip" "label-filt/${orig_idx}.png" -d "${base_dir}"
        
        cp "$output_folder_tmp/$scene_name/color/${orig_idx}.jpg" "$output_folder/color/${idx}.jpg"
        cp "$output_folder_tmp/$scene_name/label-filt/${orig_idx}.png" "$output_folder/label-filt/${idx}.png"
        cp "$output_folder_tmp/$scene_name/normal/${orig_idx}.png" "$output_folder/normal/${idx}.png"
        cp "$output_folder_tmp/$scene_name/mask/${orig_idx}.png" "$output_folder/mask/${idx}.png"
		# Downscale color image to 640x480 pixels (same size as the depth frames).
		mogrify -resize 640x480 "$output_folder/color/${idx}.jpg"
    done
done
