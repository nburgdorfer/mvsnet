#!/bin/bash

# usage statement
function usage {
        echo "Usage: ./$(basename $0) [OPTION]...

OPTIONS:
  -c,           Path to the DTU MVS Matlab evaluation code.
  -d,           Path to the MVSNet DTU data directory.
  -f,			Path to the fusibile depth fusion executable.
  -m,           Path to the saved network model.
  -p,           Path to the DTU DMFNet Points directory for evaluation.
  -r,           Path to the DTU MVS Results directory for evalutaion.
  -s,           Path to the MVSNet source code directory.
  "
}

# list of arguments expected in the input
optstring="c:d:f:m:p:r:s:h"

# collect all passed argument values
while getopts ${optstring} arg; do
  case ${arg} in
    h)
        usage
        exit 0
        ;;
    c)
        EVAL_CODE_DIR=$OPTARG
        echo "DTU MVS Matlab evaluation code path set to '${EVAL_CODE_DIR}'..."
        ;;
    d)
        MVSNET_DIR=$OPTARG
        echo "Data path for MVSNet DTU set to '${MVSNET_DIR}'..."
        ;;
    f)
        FUSE_EXE=$OPTARG
        echo "Path to fusibile executable set to '${FUSE_EXE}'..."
        ;;
    m)
        MODEL=$OPTARG
        echo "Network model file set to '${MODEL}'..."
        ;;
    p)
        EVAL_PC_DIR=$OPTARG
        echo "DTU MVS Points path set to '${EVAL_PC_DIR}'..."
        ;;
    r)
        EVAL_RESULTS_DIR=$OPTARG
        echo "DTU MVS Results path set to '${EVAL_RESULTS_DIR}'..."
        ;;
    s)
        SRC_DIR=$OPTARG
        echo "Path to the MVSNet source code set to '${SRC_DIR}'..."
        ;;
    ?)
        echo "Invalid option: ${OPTARG}."
        ;;
  esac
done

##### Set default values #####
# set default for option -c
if [ -z $EVAL_CODE_DIR ]; then
    EVAL_CODE_DIR=~/Data/Evaluation/dtu/matlab_code/
    echo "DTU MVS Matlab evaluation code path set to default value '${EVAL_CODE_DIR}'..."
fi

# default value for option d)
if [ -z $MVSNET_DIR ]; then
    MVSNET_DIR=~/Data/MVSNet/dtu/testing/
    echo "Data path for MVSNet DTU set to default value '${MVSNET_DIR}'..."
fi

# default value for option f)
if [ -z $FUSE_EXE ]; then
    FUSE_EXE=~/dev/research/fusibile/fusibile
    echo "Path to fusibile executable set to default value '${FUSE_EXE}'..."
fi

# default value for option m)
if [ -z $MODEL ]; then
    MODEL=~/Data/MVSNet/models/3DCNNs/model.ckpt
    echo "Model set to default value '${MODEL}'..."
fi

# set default for option -p
if [ -z $EVAL_PC_DIR ]; then
    EVAL_PC_DIR=~/Data/Evaluation/dtu/mvs_data/Points/dmfnet/
    echo "DTU MVS Points path set to default value '${EVAL_PC_DIR}'..."
fi

# set default for option -r
if [ -z $EVAL_RESULTS_DIR ]; then
    EVAL_RESULTS_DIR=~/Data/Evaluation/dtu/mvs_data/Results/
    echo "DTU MVS Results path set to default value '${EVAL_RESULTS_DIR}'..."
fi

# default value for option s)
if [ -z $SRC_DIR ]; then
	SRC_DIR=../MVSNet/mvsnet/
    echo "MVSNet source code directory set to default value '${SRC_DIR}'..."
fi

echo -e "\n"


##### Run DTU evaluation #####
cd ${SRC_DIR}

SCANS=(1 4 9 10 11 12 13 15 23 24 29 32 33 34 48 49 62 75 77 110 114 118)

for SCAN in ${SCANS[@]}
do
    printf -v PADDED_SCAN_NUM "%03d" $SCAN
    echo "Working on scan${PADDED_SCAN_NUM}..."
    
    python test.py --dense_folder ${MVSNET_DIR}scan${PADDED_SCAN_NUM}_test/ --regularization '3DCNNs' --pretrained_model_ckpt_path $MODEL  --ckpt_step 150000 --max_w 1152 --max_h 864 --max_d 256 --interval_scale 0.8 > /dev/null

	python depthfusion.py --dense_folder ${MVSNET_DIR}scan${PADDED_SCAN_NUM}_test/ --fusibile_exe_path $FUSE_EXE --prob_threshold 0.8 

    # move merged point cloud to evaluation path
    cp ${MVSNET_DIR}scan${PADDED_SCAN_NUM}_test/points_mvsnet/consistencyCheck/final3d_model.ply ${EVAL_PC_DIR}mvsnet/mvsnet${PADDED_SCAN_NUM}_l3.ply
done

## Evaluate the output point clouds
# delete previous results if 'Results' directory is not empty
if [ "$(ls -A $EVAL_RESULTS_DIR)" ]; then
    rm -r $EVAL_RESULTS_DIR*
fi

USED_SETS="[${SCANS}]"

# run matlab evaluation on merged output point cloud
matlab -nodisplay -nosplash -nodesktop -r "clear all; close all; format compact; arg_method='mvsnet'; UsedSets=${USED_SETS}; run('${EVAL_CODE_DIR}BaseEvalMain_web.m'); clear all; close all; format compact; arg_method='mvsnet'; UsedSets=${USED_SETS}; run('${EVAL_CODE_DIR}ComputeStat_web.m'); exit;" | tail -n +10
    echo "Done!"
