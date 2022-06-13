#!/bin/bash

# basic params
TNT_DIR=/media/Data/nate/MVSNet/tanks_and_temples/training/
MODEL=/media/Data/nate/MVSNet/models/3DCNNs/model.ckpt
EVAL_CODE_DIR=/media/Data/nate/Evaluation/tnt/TanksAndTemples/python_toolbox/evaluation/
SRC_DIR=../MVSNet/mvsnet/
SCALE=0.8
DEPTH_PLANES=256
PROB_TH=0.8

# display parameters
echo "Data path for Tanks and Temples set to '${TNT_DIR}'..."
echo "Network model file set to '${MODEL}'..."
echo "Tanks and Temples evaluation code path set to '${EVAL_CODE_DIR}'..."
echo "Source code path set to '${SRC_DIR}'..."
echo "Scale set to '${SCALE}'..."
echo "Number of depth planes set to '${DEPTH_PLANES}'..."
echo "Fusion confidence threshold set to '${PROB_TH}'..."
echo -e "\n"

inference() {
	cd ${SRC_DIR}

    echo -e "\e[1;33mRunning MVSNet on scene ${1}\e[0;37m"
	## convert mvsnet cameras into .log format (w/ alignment)
	python ../../tools/conversion/convert_to_log.py -d ${TNT_DIR}${1}/cams/ -f mvsnet -o ${TNT_DIR}${1}/cams/camera_pose.log
    
    python test.py --dense_folder ${TNT_DIR}${1}/ --regularization '3DCNNs' --pretrained_model_ckpt_path $MODEL --ckpt_step 150000 --max_w 1920 --max_h 1056 --max_d ${DEPTH_PLANES} --interval_scale ${SCALE} > /dev/null

	python depthfusion.py --dense_folder ${TNT_DIR}${1}/ --fusibile_exe_path $FUSE_EXE --prob_threshold ${PROB_TH}

    # move merged point cloud to evaluation path
    cp ${MVSNET_DIR}${SCENE}/points_mvsnet/consistencyCheck/final3d_model.ply

}

evaluate() {
    cd ${EVAL_CODE_DIR}
	echo -e "\e[1;33mRunning Tanks and Temples evaluation...\e[0;37m"
    python -u run.py --dataset-dir ${EVAL_CODE_DIR}../../../eval_data/${1}/ --traj-path ${TNT_DIR}${SCENE}/cams/camera_pose.log --ply-path ${1}
}


##### Run Tanks and Temples evaluation #####

for SCENE in Barn Ignatius Truck
do
	# run inference
	inference $SCENE &
	wait

	## evaluate point cloud
    evaluate "${MVSNET_DIR}${SCENE}/points_mvsnet/consistencyCheck/final3d_model.ply" &
    wait
done

echo -e "\e[1;32mDone!\e[0;37m"
