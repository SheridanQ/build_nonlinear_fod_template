#!/usr/bin/env python3

import os
import numpy as np
import nibabel as nib
import sys

###
#Usage:: ./def2disp.py disp_mrtrix dummy_disp out_disp
#disp_mrtrix: computed by warpconvert warpfull2displacement
#dummy_disp:  computed by make_dummy_header.sh using one step registration
#out_disp:    the output_disp full path
###

## Parse inputs
disp_mrtrix = sys.argv[1]
dummy_disp = sys.argv[2]
out_disp = sys.argv[3]

disp4D = nib.load(disp_mrtrix)
dummy_disp = nib.load(dummy_disp)
dummy_header = dummy_disp.header.copy()

x_dim,y_dim,z_dim,t_dim=disp4D.get_data().shape
disp5D=np.zeros((x_dim,y_dim,z_dim,1,t_dim)).astype(np.float64)
disp5D[:,:,:,0,0]=-disp4D.get_data()[:,:,:,0]
disp5D[:,:,:,0,1]=-disp4D.get_data()[:,:,:,1]
disp5D[:,:,:,0,2]=disp4D.get_data()[:,:,:,2]
IMG=nib.Nifti1Image(disp5D,disp4D.affine,header=dummy_header)
nib.save(IMG,out_disp)
