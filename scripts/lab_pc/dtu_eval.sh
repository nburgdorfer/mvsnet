#!/bin/bash

MVSNET_DIR=/media/nate/Data/MVSNet/dtu/testing/
MODEL=/media/nate/Data/MVSNet/models/3DCNNs/model.ckpt
SRC_DIR=../MVSNet/mvsnet/
EVAL_DIR=/media/nate/Data/Evaluation/dtu/

./dtu_eval.sh -c ${EVAL_DIR}matlab_code/ -d $MVSNET_DIR -m $MODEL -p ${EVAL_DIR}mvs_data/Points/ -r ${EVAL_DIR}mvs_data/Results/ -s $SRC_DIR 
