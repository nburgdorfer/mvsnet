#!/bin/bash

# usage statement
function usage {
        echo "Usage: ./$(basename $0) [OPTION]...

OPTIONS:
  -d,           Path to the MVSNet DTU data directory.
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
        echo "Data path for MVSNet DTU set to '${MVSNET_DIR}'..."
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
    MVSNET_DIR=~/Data/MVSNet/dtu/testing/
    echo "Data path for MVSNet DTU set to default value '${MVSNET_DIR}'..."
fi

CODE_DIR=../MVSNet/mvsnet/

for SCAN in 1 4 9 10 11 12 13 15 23 24 29 32 33 34 48 49 62 75 77 110 114 118
do
    cd ${CODE_DIR}

    printf -v PADDED_SCAN_NUM "%03d" $SCAN
    echo "Working on scan${PADDED_SCAN_NUM}..."
    
    python test.py --dense_folder ${MVSNET_DIR}scan${PADDED_SCAN_NUM}_test/ --regularization '3DCNNs' --pretrained_model_ckpt_path $MODEL  --ckpt_step 150000 --max_w 1600 --max_h 1184 --max_d 256 --interval_scale 0.8 > /dev/null
    echo "Done!"
done
