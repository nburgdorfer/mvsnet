#!/bin/bash

# parameters
DATA_DIR=/media/Data/nate/BlendedMVS/
OUTPUT_DIR=/media/Data/nate/Results/MVSNet/blended_mvs/Output/
MODEL=/media/Data/nate/MVS/MVSNet/blended_mvs/models/3DCNNs/model.ckpt
METHOD=mvsnet
SRC_DIR=../MVSNet/mvsnet/

W=2048
H=1536
REG=3DCNNs
DEPTH_PLANES=256
SCALE=0.8
PROB_TH=0.8
CKPT_STEP=150000

display_params() {
    echo "Data path for MVSNet DTU set to '${DATA_DIR}'..."
    echo "Data path for MVSNet DTU Output set to '${OUTPUT_DIR}'..."
    echo "Model set to '${MODEL}'..."
    echo "Method set to '${METHOD}'..."
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

	SCENES=$1
	for SCENE in ${SCENES[@]}
	do
		printf -v PADDED_SCENE_NUM "%03d" $SCENE
		echo "Working on scene${PADDED_SCENE_NUM}..."
		
		python test.py \
			--dense_folder ${DATA_DIR} \
			--scan_dir scene${PADDED_SCENE_NUM}/ \
			--output_folder ${OUTPUT_DIR}scene${PADDED_SCENE_NUM}/ \
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

display_params

# run inference
SCENES=({0..112})
inference $SCENES &
wait

