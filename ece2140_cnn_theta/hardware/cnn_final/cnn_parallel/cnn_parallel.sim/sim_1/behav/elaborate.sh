#!/bin/bash -f
xv_path="/home/wen/Xilinx/Vivado/2016.4"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $xv_path/bin/xelab -wto 4777fc83450a44a581cb15fcc119cff4 -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L xbip_utils_v3_0_7 -L c_reg_fd_v12_0_3 -L xbip_dsp48_wrapper_v3_0_4 -L xbip_pipe_v3_0_3 -L xbip_dsp48_addsub_v3_0_3 -L xbip_addsub_v3_0_3 -L c_addsub_v12_0_10 -L xbip_bram18k_v3_0_3 -L mult_gen_v12_0_12 -L secureip -L xpm --snapshot test_top_behav xil_defaultlib.test_top -log elaborate.log