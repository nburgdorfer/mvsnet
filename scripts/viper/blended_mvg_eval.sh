#!/bin/bash

# basic params
MVG_DIR=/media/Data/nate/MVSNet/blended_mvg/
MODEL=/media/Data/nate/MVSNet/models/3DCNNs/model.ckpt
SRC_DIR=../MVSNet/mvsnet/
FUSE_EXE=~/dev/research/fusibile/fusibile
INTERVAL_SCALE=1.0
SAMPLE_SCALE=0.25
DEPTH_PLANES=256
PROB_TH=0.8

# display parameters
echo "Data path for BlendedMVG set to '${MVG_DIR}'..."
echo "Network model file set to '${MODEL}'..."
echo "Source code path set to '${SRC_DIR}'..."
echo "Fusible executable path set to '${FUSE_EXE}'..."
echo "Interval scale set to '${INTERVAL_SCALE}'..."
echo "Sample scale set to '${SAMPLE_SCALE}'..."
echo "Number of depth planes set to '${DEPTH_PLANES}'..."
echo "Fusion confidence threshold set to '${PROB_TH}'..."
echo -e "\n"

inference() {
	cd ${SRC_DIR}

    echo -e "\e[1;33mRunning MVSNet on scene ${1}\e[0;37m"
    python test.py --dense_folder ${MVG_DIR}${1}/ --regularization '3DCNNs' --pretrained_model_ckpt_path $MODEL --ckpt_step 150000 --max_w 768 --max_h 576 --max_d ${DEPTH_PLANES} --interval_scale ${INTERVAL_SCALE} --sample_scale ${SAMPLE_SCALE} --adaptive_scaling #> /dev/null

	python depthfusion.py --dense_folder ${MVG_DIR}${1}/ --fusibile_exe_path $FUSE_EXE --prob_threshold ${PROB_TH}
}

##### Run Tanks and Temples evaluation #####
SCENES=(16 17 18 19 20 21)

for SCENE in ${SCENES[@]}
do
	# pad scan number with zeros
    printf -v PADDED_SCENE_NUM "PID%03d" $SCENE

	# run inference
	inference $PADDED_SCENE_NUM &
	wait
done

echo -e "\e[1;32mDone!\e[0;37m"
