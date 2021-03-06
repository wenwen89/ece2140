-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controller is
Port (
	clk				: in STD_LOGIC;	
	rst 			: in STD_LOGIC;	
	
	--SIGNAL FROM THE DIFFERENT BLOC IF WE HAVE TO STOP THE PIPE
	readyFifo		: in STD_LOGIC;
	valid			: in STD_LOGIC;
	readyRouter		: in STD_LOGIC;
	
	--
	numberValidPE	: in STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	--SIGNAL FROM THE CPU
	--
	cpuTask			: in STD_LOGIC;
	kernelSize		: in STD_LOGIC_VECTOR(15 DOWNTO 0);
	sizeOutput		: in STD_LOGIC_VECTOR(15 DOWNTO 0);
	featuresIn		: in STD_LOGIC_VECTOR(15 DOWNTO 0);
	featuresOut		: in STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	--stop the pipe
	enable				: out STD_LOGIC;
	--new layer
	nextLayer			: out STD_LOGIC;
	--new calculation for one output pixel 
	nextOutputPixel 		: out STD_LOGIC;
	--new line
	nextLine			: out STD_LOGIC;
	--new features
	nextFeature			: out STD_LOGIC;
	--end layer
	endLayer			: out STD_LOGIC;
	nextfeatureout      : out STD_LOGIC
); 
end controller;

architecture behavior of controller is
	signal counter_kernel: integer;
	signal counter_kernel_row: integer;
	--input features map
	signal counter_kernel_features: integer;
	--output pixel
	signal counter_output: integer;
	--output features map
	signal counter_features: integer;
	type FSM_state is (STALL, START_EXE, RUN, END_EXE);
	signal fsm: FSM_state;
	signal previous_fsm: FSM_state;
	signal stall_pipe: STD_LOGIC;
	
	begin
	
	stall_pipe <= readyFifo and readyRouter;
	
	
	process(rst, clk)
	begin
		if rst = '1' then 
			fsm <= STALL;
			
			counter_kernel_row <= 0;
			counter_kernel <= 0;
			counter_kernel_features <= 0;
			counter_features <= 0;
			counter_output <= 0;
			
			previous_fsm <= START_EXE;
			
			enable <= '0';
			nextLayer <= '0';
			nextOutputPixel <= '0';
			nextLine <= '0';
			nextFeature <= '0';
			endLayer <= '0';
			
		elsif rising_edge(clk) then	
		--default value		
			
			counter_kernel <= counter_kernel;
			counter_kernel_row <= counter_kernel_row;
			counter_kernel_features <= counter_kernel_features;
			counter_features <= counter_features;
			counter_output <= counter_output;
			
			nextLayer <= '0';
			nextLine <= '0';
			nextFeature <= '0';
			nextOutputPixel <= '0';			

			endLayer <= '0';
			enable <= '0';
		--------------------------------
		--FSM
		--In order to maximize the frequency, the FSM is clocked
		--When we have something new, it will happen only one cycle after
			case fsm is
			-- STALL == STOP THE PIPE
				when STALL => 
					enable <= '0';
					if stall_pipe = '0' then
						fsm <= STALL;
					else 
						fsm <= previous_fsm;
					end if;
			-- Wait for CPU order
			-- If we have already executed something, we just stop  
				when START_EXE =>
					if cpuTask = '1' then
						fsm <= RUN;
						nextLayer <= '1'; 
						nextOutputPixel <= '0';
						counter_kernel_row <= 0;
						enable <= '0';
						--FIXME 
						-- find a bette behavior for the begining
						counter_kernel <= 1;
						counter_kernel_features <= 0;
						counter_output <= 0;
					 else
					 	if previous_fsm = START_EXE then
					 		fsm <= START_EXE;
					 		nextLayer <= '0'; 
							nextOutputPixel <= '0';
							counter_kernel_row <= 0;
							counter_kernel <= 0;
							counter_kernel_features <= 0;
							counter_output <= 0;
					 	else 
					 		fsm <= 	END_EXE;
					 		endLayer <= '1';
					 	end if;	
					 end if;	
				when RUN =>
					nextLayer <= '0';
					enable <= '1';
					nextfeatureout <= '0';
					if previous_fsm = START_EXE then 
						nextOutputPixel <= '1';
						enable <= '0';
					end if;
					if stall_pipe = '0' then 
						fsm <= STALL;
					else
						if valid = '1' or previous_fsm = START_EXE then 
							if  counter_kernel < (to_integer(unsigned(kernelSize)) - 1) then 
								fsm <= RUN;
								counter_kernel <= counter_kernel + 1;
							elsif counter_kernel_row < (to_integer(unsigned(kernelSize)) - 1) then 
								fsm <= RUN;
								nextLine <= '1';
								counter_kernel <= 0;
								counter_kernel_row <= counter_kernel_row + 1;
							elsif counter_kernel_features < (to_integer(unsigned(featuresIn)) - 1) then 
								counter_kernel <= 0;
								counter_kernel_row <= 0;
								counter_kernel_features <= counter_kernel_features + 1;
								nextFeature <= '1';	
							elsif counter_output < 99 then 	
							--elsif counter_output < (to_integer(unsigned(sizeOutput))*to_integer(unsigned(sizeOutput)) - 1) then 
								counter_kernel_row <= 0;
								counter_kernel <= 0;
								counter_kernel_features <= 0;
								counter_output <= counter_output + to_integer(unsigned(numberValidPE));
								nextOutputPixel <= '1';	
							elsif counter_features < (to_integer(unsigned(featuresOut)) - 1) then
								counter_features <= counter_features + 1;
								fsm <= run;
								nextfeatureout <= '1';
								--nextFeature <= '1'; 
								nextOutputPixel <= '0';
								counter_kernel_row <= 0;
								counter_kernel <= 0;
								counter_kernel_features <= 0;
								counter_output <= 0;
							else 	
								fsm <= START_EXE;
							end if;
						end if;	
					end if;
				when END_EXE => 
					fsm <= STALL;
					previous_fsm <= START_EXE;
				when others => 
					enable <= '0';
					fsm <= STALL;
			end case;
	-------------------------------------
	--simple register to save what the previous state was
			if fsm = STALL then
				previous_fsm <= previous_fsm;
			else 
				previous_fsm <= fsm;
			end if;
		end if;	
	end process;
	
	end behavior;
