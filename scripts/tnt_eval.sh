#!/bin/bash

# parameters
DATASET=training

DATA_DIR=/media/nate/Data/TNT/${DATASET}
OUTPUT_DIR=/media/nate/Data/Results/MVSNet/tnt/Output_${DATASET}/
FUSE_EXE=~/dev/research/Fusion/fusibile/fusibile
MODEL=/media/nate/Data/Models/MVSNet/dtu/3DCNNs/model.ckpt
METHOD=mvsnet
SRC_DIR=../MVSNet/mvsnet/

W=1152
H=864
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
	SCRIPT_PATH=$(pwd)
	cd ${SRC_DIR}

	for SCENE in ${SCENES[@]}
	do
		echo "Working on scene ${SCENE}..."
		
		python test.py \
			--dense_folder ${DATA_DIR} \
			--scan_dir ${SCENE}/ \
			--output_folder ${OUTPUT_DIR}${SCENE}/ \
			--regularization ${REG} \
			--pretrained_model_ckpt_path $MODEL \
			--ckpt_step ${CKPT_STEP} \
			--max_w ${W} \
			--max_h ${H} \
			--max_d ${DEPTH_PLANES} \
			--interval_scale ${SCALE} \
			#> /dev/null
	done

	cd $SCRIPT_PATH
}

fusion_gipuma() {
	POINTS_DIR=points_mvsnet/consistencyCheck/
	PLY_FILE=${SCENE}.ply

	for SCENE in ${SCENES[@]}
	do
		echo "Fusing scene ${SCENE}..."
		
		# fuse depth maps
		python depthfusion.py --dense_folder ${DATA_DIR}${SCENE}/ --fusibile_exe_path $FUSE_EXE --prob_threshold ${PROB_TH}
	done

}

display_params

if [ ! -d ${OUTPUT_DIR} ]; then
	mkdir -p ${OUTPUT_DIR};
fi

# run inference
SCENES=(Barn Caterpillar Church Courthouse Ignatius Meetingroom Truck)
inference

## fuse depth maps
#fusion_gipuma $SCANS &
#wait
#
## evaluate point clouds
#evaluate_matlab $SCANS &
#wait
