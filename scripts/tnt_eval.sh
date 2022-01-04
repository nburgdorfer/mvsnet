#!/bin/bash

# usage statement
function usage {
        echo "Usage: ./$(basename $0) [OPTION]...

OPTIONS:
  -d,           Path to the MVSNet TNT data directory.
  -m,           Path to the saved network model."
}

# list of arguments expected in the input
optstring="d:m:h"

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
    m)
        MODEL=$OPTARG
        echo "Network model file set to '${MODEL}'..."
        ;;
    ?)
        echo "Invalid option: ${OPTARG}."
        ;;
  esac
done


# set default values if arguments not passed
if [ -z $MODEL ]; then
    MODEL=../model_dtu/3DCNNs/model.ckpt
    echo "Model set to default value '${MODEL}'..."
fi
if [ -z $MVSNET_DIR ]; then
    MVSNET_DIR=~/Data/MVSNet/tanks_and_temples/training/
    echo "Data path for MVSNet TNT set to default value '${MVSNET_DIR}'..."
fi

CODE_DIR=../MVSNet/mvsnet/
cd ${CODE_DIR}

#for SCENE in Barn Caterpillar Church Courthouse Ignatius Meetingroom Truck
for SCENE in Barn Ignatius Truck
#for SCENE in Ignatius
do
    echo "Working on ${SCENE}..."
    
    python test.py --dense_folder ${MVSNET_DIR}${SCENE}/ --regularization '3DCNNs' --pretrained_model_ckpt_path $MODEL  --ckpt_step 150000 --max_w 1152 --max_h 864 --max_d 256 --interval_scale 1.06 > /dev/null
    echo "Done!"
done
