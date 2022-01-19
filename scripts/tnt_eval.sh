#!/bin/bash

# usage statement
function usage {
        echo "Usage: ./$(basename $0) [OPTION]...

OPTIONS:
  -d,           Path to the MVSNet TNT data directory.
  -f,			Path to the fusibile depth fusion executable.
  -m,           Path to the saved network model.
  -s,           Path to the MVSNet source code directory.
  -z,           Path to the Tanks and Temples evaluation code.
  "
}

# list of arguments expected in the input
optstring="d:f:m:s:z:h"

# collect all passed argument values
while getopts ${optstring} arg; do
  case ${arg} in
    h)
        usage
        exit 0
        ;;
    d)
        MVSNET_DIR=$OPTARG
        echo "Data path for MVSNet TNT set to '${MVSNET_DIR}'..."
        ;;
    f)
        FUSE_EXE=$OPTARG
        echo "Path to fusibile executable set to '${FUSE_EXE}'..."
        ;;
    m)
        MODEL=$OPTARG
        echo "Network model file set to '${MODEL}'..."
        ;;
    s)
        SRC_DIR=$OPTARG
        echo "Path to the MVSNet source code set to '${SRC_DIR}'..."
        ;;
    z)
        EVAL_CODE_DIR=$OPTARG
        echo "Tanks and Temples evaluation code path set to '${EVAL_CODE_DIR}'..."
        ;;
    ?)
        echo "Invalid option: ${OPTARG}."
        ;;
  esac
done


# set default values if arguments not passed
# set default option -d
if [ -z $MVSNET_DIR ]; then
    MVSNET_DIR=~/Data/MVSNet/tanks_and_temples/training/
    echo "Data path for MVSNet TNT set to default value '${MVSNET_DIR}'..."
fi

# default value for option -f
if [ -z $FUSE_EXE ]; then
    FUSE_EXE=~/dev/research/fusibile/fusibile
    echo "Path to fusibile executable set to default value '${FUSE_EXE}'..."
fi

# set default option -m
if [ -z $MODEL ]; then
    MODEL=~/Data/MVSNet/models/3DCNNs/model.ckpt
    echo "Model set to default value '${MODEL}'..."
fi

# default value for option -s
if [ -z $SRC_DIR ]; then
	SRC_DIR=../MVSNet/mvsnet/
    echo "MVSNet source code directory set to default value '${SRC_DIR}'..."
fi

# set default for option -z
if [ -z $EVAL_CODE_DIR ]; then
    EVAL_CODE_DIR=~/Data/Evaluation/tanks_and_temples/TanksAndTemples/python_toolbox/evaluation/
    echo "Tanks and Temples evaluation code path set to default value '${EVAL_CODE_DIR}'..."
fi

echo -e "\n"

evaluate() {
    cd ${EVAL_CODE_DIR}
	echo "\nRunning Tanks and Temples evaluation..."
    python -u run.py --dataset-dir ${EVAL_CODE_DIR}../../../eval_data/${SCENE}/ --traj-path ${MVSNET_DIR}${SCENE}/cams/camera_pose.log --ply-path ${1}
}


##### Run Tanks and Temples evaluation #####
cd ${SRC_DIR}

for SCENE in Barn Ignatius Truck
do
    echo "Working on ${SCENE}..."

	## convert mvsnet cameras into .log format (w/ alignment)
	python ../../tools/conversion/convert_to_log.py -d ${MVSNET_DIR}${SCENE}/cams/ -f mvsnet -o ${MVSNET_DIR}${SCENE}/cams/camera_pose.log
    
    #	python test.py --dense_folder ${MVSNET_DIR}${SCENE}/ --regularization '3DCNNs' --pretrained_model_ckpt_path $MODEL  --ckpt_step 150000 --max_w 1152 --max_h 864 --max_d 256 --interval_scale 0.8 #> /dev/null

	python depthfusion.py --dense_folder ${MVSNET_DIR}${SCENE}/ --fusibile_exe_path $FUSE_EXE --prob_threshold 0.8 

    # move merged point cloud to evaluation path
    cp ${MVSNET_DIR}${SCENE}/points_mvsnet/consistencyCheck/final3d_model.ply

	## evaluate point cloud
    evaluate "${MVSNET_DIR}${SCENE}/points_mvsnet/consistencyCheck/final3d_model.ply" &
    wait

    echo "Done!"
done
