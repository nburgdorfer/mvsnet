#!/bin/bash

MVSNET_DIR=/media/nate/Data/MVSNet/tanks_and_temples/training/
MODEL=/media/nate/Data/MVSNet/models/3DCNNs/model.ckpt
SRC_DIR=../MVSNet/mvsnet/
EVAL_CODE_DIR=/media/nate/Data/Evaluation/tanks_and_temples/TanksAndTemples/python_toolbox/evaluation/

./tnt_eval.sh -d $MVSNET_DIR -m $MODEL -s $SRC_DIR -z $EVAL_CODE_DIR
