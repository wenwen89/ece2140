	
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.cnn_pkg.all;

entity cnn_top is
generic (PARALELISM: integer := PARALELISM);
port (
	clk			: in STD_LOGIC;	
	rst 			: in STD_LOGIC;
	
	-- FROM CPU
	cpuTask			: in STD_LOGIC;
	kernelSize		: in STD_LOGIC_VECTOR(15 DOWNTO 0);
	sizeInput		: in STD_LOGIC_VECTOR(15 DOWNTO 0);
	sizeOutput		: in STD_LOGIC_VECTOR(15 DOWNTO 0);
	featuresIn		: in STD_LOGIC_VECTOR(15 DOWNTO 0);
	featuresOut		: in STD_LOGIC_VECTOR(15 DOWNTO 0);

	--bias and weight in
	writeWeight			: in std_logic;
	weightIn			: in STD_LOGIC_VECTOR(15 downto 0);
	writeBias			: in std_logic;
	biasIn				: in STD_LOGIC_VECTOR(15 downto 0);

	--FIXME
	--data from the FIFO at the end of the PE
	validIn				: in STD_LOGIC;
	dataIn				: in STD_LOGIC_VECTOR(15 DOWNTO 0);

	data_out_convolution_debug	: out dataflow;
	valid_out_convolution_debug	: out STD_LOGIC_VECTOR(1 downto 0);
	data_out_pooling		: out STD_LOGIC_VECTOR (15 downto 0);
	valid_out_pooling		: out STD_LOGIC
);
end entity;


architecture behavioral of cnn_top is

	

	signal data_Out: dataflow;
	signal weight_Out: dataflow;
	signal bias_Out: dataflow;
	signal data_valid: STD_LOGIC_VECTOR(PARALELISM - 1 downto 0);
	signal ready_router: STD_LOGIC_VECTOR(PARALELISM - 1 downto 0);
	signal readyRouter: STD_LOGIC;
	signal enable: STD_LOGIC;
	signal next_line: STD_LOGIC;
	signal next_feature: STD_LOGIC;
	signal end_layer: STD_LOGIC;
	signal next_Output_Pixel: STD_LOGIC;
	signal next_Layer: STD_LOGIC;
	signal valid_out_convolution: STD_LOGIC_VECTOR(1 downto 0);
	signal data_out_convolution: dataflow;

	begin
	
	data_out_convolution_debug <= data_out_convolution;
	valid_out_convolution_debug <= valid_out_convolution;

	process(ready_router)
	begin
		readyRouter <= '1';
		for I in 0 to PARALELISM - 1 loop
			if ready_router(I) = '0' then 
				readyRouter <= '0';
			end if;
		end loop;
	end process;




	controller: entity work.controller (behavior)
	Port map (
	clk				=> clk,	
	rst 				=> rst,
	
	--SIGNAL FROM THE DIFFERENT BLOC IF WE HAVE TO STOP THE PIPE
	--FIXME change when others block are added 
	readyFifo			=> '1',
	valid				=> data_valid(0),
	--end FIXME
	readyRouter			=> readyRouter,
	
	--
	numberValidPE 			=> std_logic_vector(to_unsigned(1,16)),
	
	--SIGNAL FROM THE CPU
	--
	cpuTask	 			=> cpuTask,
	kernelSize			=> kernelSize,
	sizeOutput			=> sizeOutput,
	featuresIn			=> featuresIn,
	featuresOut			=> featuresOut,
	
	--stop the pipe
	enable				=> enable,
	--new layer
	nextLayer			=> next_Layer, 
	--new calculation for one output pixel 
	nextOutputPixel 		=> next_Output_Pixel,
	--new line
	nextLine			=> next_line,
	--new features
	nextFeature			=> next_feature,
	--end layer
	endLayer			=> end_layer
	); 
			
	datapath: for I in 0 to PARALELISM - 1 generate
		router: entity work.router (behavioral)
		generic map (MOD_LINE => PARALELISM)
		port map(
			clk				=> clk,	
			rst 				=> rst,
	
			initialValue			=> I,

			writeWeight			=> writeWeight,
			weightIn			=> weightIn,
			writeBias			=> writeBias,
			biasIn				=> biasIn,

			--data from the FIFO at the end of the PE
			valid				=> validIn,
			dataIn				=> dataIn,
	
			--controller signal
			NextOutputPixel			=> next_Output_Pixel,
			nextLayer			=> next_Layer,
			nextLine			=> next_line,
			nextFeature			=> next_feature,
			end_layer			=> end_layer,
			enable 				=> enable,
	
			-- PE perspective (so In means out for the router and Out means in for the router)
			size_dataIn			=> sizeInput,
			size_dataOut			=> sizeOutput,
			size_features			=> kernelSize,
	
			--overflow
			ready_router			=> ready_router(I),
	
			-- DATA to the PE
			dataValid			=> data_valid(I),
			dataOut				=> data_out(I),
			weightOut			=> weight_Out(I),
			biasOut				=> bias_Out(I)
		);

		convolution: entity work.convo
		port map(
    		weight			=> weight_Out(I),
    		input			=> data_out(I),
    		bias			=> bias_Out(I),
    		output			=> data_out_convolution(I),
    		clk			=> clk,	
    		rst 			=> rst,
    		next_output		=> next_Output_Pixel,
    		enable 			=> enable,
    		valid_in		=> data_valid(I),
    		valid_out		=> valid_out_convolution(I)
    		);
	end generate datapath;

	pooling: entity work.fifo
    port map(
        clk 			=> clk,	
        rst  			=> rst,
        wr_en1			=> valid_out_convolution(0),
        --rd_en1 : in STD_LOGIC;
        wr_en2			=> valid_out_convolution(1),
        --rd_en2 : in STD_LOGIC;
        data_in1		=> data_out_convolution(0),
        --data_out1 : out STD_LOGIC_VECTOR (15 downto 0);
        data_in2		=> data_out_convolution(1),
        --data_out2 : out STD_LOGIC_VECTOR (15 downto 0);
        data_label 		=> data_out_pooling,
        --empty1 : out STD_LOGIC;
        --full1 : out STD_LOGIC;
        --empty2 : out STD_LOGIC;
        --full2 : out STD_LOGIC;
        --empty : out STD_LOGIC;
        full 			=> valid_out_pooling   
        );

end architecture;