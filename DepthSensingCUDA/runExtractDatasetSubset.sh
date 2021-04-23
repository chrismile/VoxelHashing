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

#dataset_folder="D:/neuhauser/datasets/ScanNet/raw/scans"
dataset_folder="/home/christoph/Programming/DL/relight_aug/datasets/ScanNet"
template_conf="${dataset_folder}/zParametersSens_template.txt"
config_file="${dataset_folder}/zParametersSens.txt"
tracking_conf="${dataset_folder}/zParametersTrackingDefault.txt"
scans_folder="${dataset_folder}/tmp/scans"
scenes_list_filename_train="${dataset_folder}/scannetv2_train.txt"
scenes_list_filename_val="${dataset_folder}/scannetv2_val.txt"
subset_list_folder_train="${dataset_folder}/scans_subset_list_train"
subset_list_folder_val="${dataset_folder}/scans_subset_list_val"
output_folder_tmp="${dataset_folder}/scans_VoxelHashing_tmp"
output_folder_train="${dataset_folder}/scans_VoxelHashing_train"
output_folder_val="${dataset_folder}/scans_VoxelHashing_val"

export PATH=$PATH:"/c/Users/ga42wis/Programming/C++/VoxelHashing/DepthSensingCUDA/x64/Release/"
export PATH=$PATH:"/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v7.5/bin/"
#cd C:/Users/ga42wis/Programming/C++/VoxelHashing/DepthSensingCUDA

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
    subset_list_file_val="${subset_list_folder_train}/${scene_name}.txt"
    if [ ! -f "${subset_list_file_train}" ] && [ ! -f "${subset_list_file_val}" ]; then
        continue
    fi

    echo "Processing ${scene_name}..."

    # Create a new config file.
    if [ -f "$config_file" ]; then
        rm $config_file
    fi
    cp $template_conf $config_file

    # Add used files in scene to config file.
    orig_id_list=()
    while read line
    do
        i=0
        for word in $line
        do
            if [ $i -eq 0 ]; then
                orig_id_list+=($word)
            fi
            i=$((i+1))
        done
    done < $subset_list_file_train
    orig_id_list_string="${orig_id_list[@]}"
    sed -i "s|orig_id_list|$orig_id_list_string|g" "$config_file"

    # Edit the config file for running the program.
    base_dir="$output_folder_tmp/${scene_name}"
    path_sens="$scans_folder/$scene_name/$scene_name.sens"
    sed -i "s|path_sens|$path_sens|g" "$config_file"

    # Run program, output to output_folder_tmp
    if [ ! -d "$base_dir" ]; then
        mkdir "${base_dir}"
    fi
    unzip "${scans_folder}/$scene_name/${scene_name}_2d-label-filt.zip" -d "${base_dir}"
    ./x64/Release/DepthSensing.exe $config_file $tracking_conf

    # Copy files to correct directory.
    if [[ " ${scenes_train[@]} " =~ " ${scene_name} " ]]; then
        output_folder="$output_folder_train"
    fi
    if [[ " ${scenes_val[@]} " =~ " ${scene_name} " ]]; then
        output_folder="$output_folder_val"
    fi
    while read line
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
        cp "$output_folder_tmp/$scene_name/color/${orig_idx}.jpg" "$output_folder/color/${idx}.jpg"
        cp "$output_folder_tmp/$scene_name/label-filt/${orig_idx}.png" "$output_folder/label-filt/${idx}.png"
        cp "$output_folder_tmp/$scene_name/normal/${orig_idx}.png" "$output_folder/normal/${idx}.png"
        cp "$output_folder_tmp/$scene_name/mask/${orig_idx}.png" "$output_folder/mask/${idx}.png"
    done < $subset_list_file_train
done
