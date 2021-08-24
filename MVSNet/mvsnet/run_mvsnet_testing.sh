#!/bin/bash

scan_path=~/Data/MVSNet/testing/scan

for i in 1 4 9 10 11 12 13 15 23 24 29 32 33 34 48 49 62 75 77 110 114 118
do
    printf -v padded_scan_num "%03d" $i
    echo "Working on scan${padded_scan_num}..."
    
    python2 test.py --dense_folder ${scan_path}${padded_scan_num}_test/ --regularization '3DCNNs' --pretrained_model_ckpt_path ../model_dtu/3DCNNs/model.ckpt  --ckpt_step 150000 --max_w 1152 --max_h 864 --max_d 256 --interval_scale 1.06 > /dev/null
    echo "Done!"
done
