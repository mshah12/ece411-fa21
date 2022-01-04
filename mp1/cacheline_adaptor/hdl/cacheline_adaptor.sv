module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

	logic [3:0] state;
	logic read_i_val;
	logic write_i_val;
	logic curr_reading;
	logic curr_writing;
	
	always_ff @(posedge clk) begin
		
		if(reset_n <= 1'b0) begin
			state <= 3'b000;
			read_i_val <= 1'b0;
			write_i_val <= 1'b0;
			curr_reading <= 1'b0;
			curr_writing <= 1'b0;
			read_o <= 1'b0;
			write_o <= 1'b0;
		end
		else if(read_i == 1'b1 && curr_reading == 1'b0) begin
			read_i_val <= 1'b1;
			read_o <= 1'b1;
			write_o <= 1'b0;
			address_o <= address_i;
			state <= 3'b000;
			curr_reading <= 1'b1;
		end
		else if(write_i == 1'b1 && curr_writing == 1'b0) begin
			write_i_val <= 1'b1;
			read_o <= 1'b0;
			write_o <= 1'b1;
			address_o <= address_i;
			state <= 3'b000;
			curr_writing <= 1'b1;
			burst_o <= line_i[63:0];
		end
		
		if(read_i_val == 1'b1) begin
			case(state)
				3'b000: begin
					if(resp_i == 1'b1) begin
						line_o [63:0] <= burst_i;
						state <= 3'b001;
					end
				end
				3'b001: begin
					if(resp_i == 1'b1) begin
						line_o [127:64] <= burst_i;
						state <= 3'b010;
					end
				end
				3'b010: begin
					if(resp_i == 1'b1) begin
						line_o [191:128] <= burst_i;
						state <= 3'b011;
					end
				end
				3'b011: begin					
					if(resp_i == 1'b1) begin
						line_o [255:192] <= burst_i;
						resp_o <= 1'b1;
						state <= 3'b100;
					end
				end
				3'b100: begin
					resp_o <= 1'b0;
					read_o <= 1'b0;
					read_i_val <= 1'b0;
					state <= 3'b000;
					curr_reading <= 1'b0;
				end
			endcase
		end
		
		if(write_i_val == 1'b1) begin
			case(state)
				3'b000: begin
					if(resp_i == 1'b1) begin
						burst_o <= line_i [127:64];
						state <= 3'b001;
					end
				end
				3'b001: begin
					if(resp_i == 1'b1) begin
						burst_o <= line_i [191:128];
						state <= 3'b010;
					end
				end
				3'b010: begin
					if(resp_i == 1'b1) begin
						burst_o <= line_i [255:192];
						state <= 3'b011;
					end
				end
				3'b011: begin					
					if(resp_i == 1'b1) begin
						resp_o <= 1'b1;
						state <= 3'b100;
					end
				end
				3'b100: begin
					resp_o <= 1'b0;
					write_o <= 1'b0;
					write_i_val <= 1'b0;
					state <= 3'b100;
					curr_writing <= 1'b0;
				end
			endcase
		
		end
		
	end

endmodule : cacheline_adaptor
