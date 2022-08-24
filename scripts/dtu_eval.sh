#!/bin/bash

# parameters
DATA_DIR=/media/nate/Data/DTU/
OUTPUT_DIR=/media/nate/Data/Results/MVSNet/dtu/Output_testing/
FUSE_EXE=~/dev/research/Fusion/fusibile/fusibile
MODEL=/media/nate/Data/MVS/MVSNet/dtu/models/3DCNNs/model.ckpt
METHOD=mvsnet
EVAL_DIR=/media/nate/Data/Evaluation/dtu/
EVAL_CODE_DIR=${EVAL_DIR}matlab_code/
EVAL_PC_DIR=${EVAL_DIR}mvs_data/Points/${METHOD}/
EVAL_RESULTS_DIR=${EVAL_DIR}mvs_data/Results/
SRC_DIR=../MVSNet/mvsnet/

#W=1152
#H=864
W=1600
H=1184
REG=3DCNNs
DEPTH_PLANES=256
SCALE=0.8
PROB_TH=0.8
CKPT_STEP=150000

display_params() {
    echo "Data path for MVSNet DTU set to '${DATA_DIR}'..."
    echo "Data path for MVSNet DTU Output set to '${OUTPUT_DIR}'..."
    echo "Path to fusibile executable set to '${FUSE_EXE}'..."
    echo "Model set to '${MODEL}'..."
    echo "Method set to '${METHOD}'..."
    echo "DTU MVS Matlab evaluation code path set to '${EVAL_CODE_DIR}'..."
    echo "DTU MVS Points path set to '${EVAL_PC_DIR}'..."
    echo "DTU MVS Results path set to '${EVAL_RESULTS_DIR}'..."
	echo "MVSNet source code directory set to '${SRC_DIR}'..."
	echo "Image width set to '${W}'..."
	echo "Image height set to '${H}'..."
	echo "Regularization method set to '${REG}'..."
	echo "Depth planes set to '${DEPTH_PLANES}'..."
	echo "Scale set to '${SCALE}'..."
	echo "Fusion probability threshold set to '${PROB_TH}'..."
	echo "Checkpoint step set to '${CKPT_STEP}'..."
	echo -e "\n"
}

inference() {
	cd ${SRC_DIR}

	SCANS=$1
	for SCAN in ${SCANS[@]}
	do
		printf -v PADDED_SCAN_NUM "%03d" $SCAN
		echo "Working on scan${PADDED_SCAN_NUM}..."
		
		python test.py \
			--dense_folder ${DATA_DIR} \
			--scan_dir scan${PADDED_SCAN_NUM}/ \
			--output_folder ${OUTPUT_DIR}scan${PADDED_SCAN_NUM}/ \
			--regularization ${REG} \
			--pretrained_model_ckpt_path $MODEL \
			--ckpt_step ${CKPT_STEP} \
			--max_w ${W} \
			--max_h ${H} \
			--max_d ${DEPTH_PLANES} \
			--interval_scale ${SCALE} \
			> /dev/null
	done
}

fusion_gipuma() {
	POINTS_DIR=points_mvsnet/consistencyCheck/
	PLY_FILE=final3d_model.ply
	SCANS=$1

	for SCAN in ${SCANS[@]}
	do
		printf -v PADDED_SCAN_NUM "%03d" $SCAN
		echo "Fusing scan ${SCAN}..."
		
		# fuse depth maps
		python depthfusion.py --dense_folder ${DATA_DIR}scan${PADDED_SCAN_NUM}/ --fusibile_exe_path $FUSE_EXE --prob_threshold ${PROB_TH}

		# move merged point cloud to evaluation path
		cp ${DATA_DIR}scan${PADDED_SCAN_NUM}/${POINTS_DIR}${PLY_FILE} ${EVAL_PC_DIR}mvsnet/mvsnet${PADDED_SCAN_NUM}_l3.ply
	done

}

evaluate_matlab() {
	SCANS=$1

	# delete previous results if 'Results' directory is not empty
	if [ "$(ls -A $EVAL_RESULTS_DIR)" ]; then
		rm -r $EVAL_RESULTS_DIR*
	fi

	USED_SETS="[${SCANS[@]}]"

	# run matlab evaluation on merged output point cloud
	matlab -nodisplay -nosplash -nodesktop -r "clear all; close all; format compact; arg_method='mvsnet'; UsedSets=${USED_SETS}; run('${EVAL_CODE_DIR}BaseEvalMain_web.m'); clear all; close all; format compact; arg_method='mvsnet'; UsedSets=${USED_SETS}; run('${EVAL_CODE_DIR}ComputeStat_web.m'); exit;" | tail -n +10
		echo "Done!"
}

display_params

# run inference
SCANS=({1..24} {28..53} {55..72} {74..77} {82..128})
#SCANS=(1 4 9 10 11 12 13 15 23 24 29 32 33 34 48 49 62 75 77 110 114 118)
inference $SCANS &
wait

## fuse depth maps
#fusion_gipuma $SCANS &
#wait
#
## evaluate point clouds
#evaluate_matlab $SCANS &
#wait
