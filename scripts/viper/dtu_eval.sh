#!/bin/bash

# basic params
DTU_DIR=/media/Data/nate/MVSNet/dtu/testing_highres/
MODEL=/media/Data/nate/MVSNet/models/3DCNNs/model.ckpt
EVAL=/media/Data/nate/Evaluation/dtu/
SRC_DIR=../MVSNet/mvsnet/
FUSE_EXE=~/dev/research/fusibile/fusibile
EVAL_CODE_DIR=${EVAL}matlab_code/
EVAL_PC_DIR=${EVAL}mvs_data/Points/dmfnet/
EVAL_RESULTS_DIR=${EVAL}mvs_data/Results/
SCALE=0.8
DEPTH_PLANES=256
PROB_TH=0.8

# display parameters
echo "Data path for DTU set to '${DTU_DIR}'..."
echo "Network model file set to '${MODEL}'..."
echo "Source code path set to '${SRC_DIR}'..."
echo "Fusion executable set to '${FUSE_EXE}'..."
echo "DTU MVS Matlab evaluation code path set to '${EVAL_CODE_DIR}'..."
echo "DTU MVS Points path set to '${EVAL_PC_DIR}'..."
echo "DTU MVS Results path set to '${EVAL_RESULTS_DIR}'..."
echo "Scale set to '${SCALE}'..."
echo "Number of depth planes set to '${DEPTH_PLANES}'..."
echo "Fusion confidence threshold set to '${PROB_TH}'..."
echo -e "\n"

inference () {
	cd ${SRC_DIR}
    echo -e "\e[1;33mRunning MVSNet on scan ${1}\e[0;37m"
    
    python test.py --dense_folder ${DTU_DIR}scan${1}_test/ --regularization '3DCNNs' --pretrained_model_ckpt_path $MODEL  --ckpt_step 150000 --max_w 1600 --max_h 1184 --max_d ${DEPTH_PLANES} --interval_scale ${SCALE} > /dev/null

	python depthfusion.py --dense_folder ${DTU_DIR}scan${1}_test/ --fusibile_exe_path $FUSE_EXE --prob_threshold ${PROB_TH} 

    # move merged point cloud to evaluation path
    cp ${DTU_DIR}scan${1}_test/points_mvsnet/consistencyCheck/final3d_model.ply ${EVAL_PC_DIR}mvsnet/mvsnet${1}_l3.ply
}

evaluate () {
	echo -e "\e[1;33mEvaluating Output...\e[0;37m"

	## Evaluate the output point clouds
	# delete previous results if 'Results' directory is not empty
	if [ "$(ls -A $EVAL_RESULTS_DIR)" ]; then
		rm -r $EVAL_RESULTS_DIR*
	fi

	USED_SETS="[${SCANS[@]}]"

	# run matlab evaluation on merged output point cloud
	matlab -nodisplay -nosplash -nodesktop -r "clear all; close all; format compact; arg_method='mvsnet'; UsedSets=${USED_SETS}; run('${EVAL_CODE_DIR}BaseEvalMain_web.m'); clear all; close all; format compact; arg_method='mvsnet'; UsedSets=${USED_SETS}; run('${EVAL_CODE_DIR}ComputeStat_web.m'); exit;" | tail -n +10
}

##### Run DTU evaluation #####
SCANS=(1 4 9 10 11 12 13 15 23 24 29 32 33 34 48 49 62 75 77 110 114 118)

for SCAN in ${SCANS[@]}
do
	# pad scan number with zeros
    printf -v PADDED_SCAN_NUM "%03d" $SCAN

	# run inference
	inference $PADDED_SCAN_NUM &
	wait
done

# evaluate MVSNet output
evaluate &
wait

echo -e "\e[1;32mDone!\e[0;37m"
