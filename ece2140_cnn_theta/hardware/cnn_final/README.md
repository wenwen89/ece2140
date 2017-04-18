# Directory Intro

* The source files are in ./src_parallel

* The testbench files are in ./sim

* The whole project is under ./cnn_parallel

* The input/output files for testing are ./input_file and ./output_file

# How to run the project?

1. Try to open the vivado project file in ./cnn_parallel/cnn_parallel.xpr,
  and the project is automatically loaded.

2. The paths to input/output files may need to be modified according to 
  local settings.

* Change the following output files paths in line 30, 31 in ./sim/test_top.vhd to: $PROJECT_ROOT_DIR/ece2140/ece2140_cnn_theta/hardware/cnn_final/output_file

* Change the following input files paths in line 198, 211, 224 in ./sim/test_top.vhd to: $PROJECT_ROOT_DIR/ece2140/ece2140_cnn_theta/hardware/cnn_final/input_file

3. Run simulation in vivado, and type "restart" then "run all" (required to run very long time) in Tcl cmd line window.

4. The output files should be written to ./output_file/out_pool.txt after running the simulation in vivado.


