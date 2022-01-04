import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control
(
    input clk,
    input rst,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
	 input mem_resp,
    input rv32i_word mem_rdata,
	 input logic [1:0] shift_bits,
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
	 output branch_funct3_t cmpop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = 4'b0011 << shift_bits /* Modify for MP1 Final */ ;
                lb, lbu: rmask = 4'b0001 << shift_bits /* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = 4'b0011 << shift_bits /* Modify for MP1 Final */ ;
                sb: wmask = 4'b0001 << shift_bits /* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
	fetch1,
	fetch2,
	fetch3,
	decode,
	imm,
	lui,
	br,
	auipc,
	regstate,
	calc_addr,
	ld1,
	ld2,
	st1,
	st2,
	jal,
	jalr
} state, next_states;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
	 load_pc = 1'b0;
    load_ir = 1'b0;
    load_regfile = 1'b0;
    load_mar = 1'b0;
    load_mdr = 1'b0;
    load_data_out = 1'b0;
	 pcmux_sel = pcmux::pc_plus4;
	 alumux1_sel = alumux::rs1_out;
    alumux2_sel = alumux::i_imm;
    regfilemux_sel = regfilemux::alu_out;
    marmux_sel = marmux::pc_out;
    cmpmux_sel = cmpmux::rs2_out;
	 aluop = alu_add;
	 cmpop = beq;
	 mem_read = 1'b0;
    mem_write = 1'b0;
	 mem_byte_enable = 4'b1111;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = 1'b1;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
	load_regfile = 1'b1;
	regfilemux_sel = sel;
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
	load_mar = 1'b1;
	marmux_sel = sel;
endfunction

function void loadMDR();
	load_mdr = 1'b1;
endfunction

function void loadIR();
	load_ir = 1'b1;
endfunction

function void loadDataOut();
	load_data_out = 1'b1;
endfunction

/**
 * SystemVerilog allows for default argument values in a way similar toop
 *   C++.
**/
function void setALU(alumux::alumux1_sel_t sel1,
                     alumux::alumux2_sel_t sel2,
                     logic setop = 1'b0, alu_ops op = alu_add);
    /* Student code here */
    if (setop)
		begin
        aluop = op; // else default value
		  alumux1_sel = sel1;
		  alumux2_sel = sel2;
		end
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op = beq, logic setop = 1'b0);
	 if(setop)
		begin
			cmpop = op;
			cmpmux_sel = sel;
		end
endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
	 case(state)
		fetch1: begin
					loadMAR(marmux::pc_out);
				  end
		fetch2: begin
					loadMDR();
					mem_read = 1'b1;
				  end
		fetch3: begin
					loadIR();
				  end
		decode: begin
					;
				  end
		lui: begin
					loadRegfile(regfilemux::u_imm);
					loadPC(pcmux::pc_plus4);
				  end
		auipc: begin
						loadPC(pcmux::pc_plus4);
						setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
						loadRegfile(regfilemux::alu_out);
					 end
		br:   begin
						loadPC(pcmux::pcmux_sel_t'({{1'b0}, br_en}));
						setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
						setCMP(cmpmux::rs2_out, branch_funct3, 1'b1);
					 end
		imm:  begin
						case(arith_funct3)
						 slt: begin
									loadPC(pcmux::pc_plus4);
									loadRegfile(regfilemux::br_en);
									setCMP(cmpmux::i_imm, blt, 1'b1);
								end
						 sltu: begin
									loadPC(pcmux::pc_plus4);
									loadRegfile(regfilemux::br_en);
									setCMP(cmpmux::i_imm, bltu, 1'b1);
								 end
						 sr: begin
									if(funct7[5]) begin
										loadPC(pcmux::pc_plus4);
										loadRegfile(regfilemux::alu_out);
										setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
									end
									else begin
										loadPC(pcmux::pc_plus4);
										loadRegfile(regfilemux::alu_out);
										setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl);
									end
								end
						default: begin
										loadPC(pcmux::pc_plus4);
										loadRegfile(regfilemux::alu_out);
										setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(arith_funct3));										
									end
						endcase
					end
		calc_addr: begin
							case(opcode)
								op_load: begin
												loadMAR(marmux::alu_out);
												setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
											end
								op_store: begin
												loadMAR(marmux::alu_out);
												loadDataOut();
												setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
											 end
								default: ;
							endcase
					  end
		ld1: begin
					loadMDR();
					mem_read = 1'b1;
			  end
		ld2: begin
					loadPC(pcmux::pc_plus4);
					case(load_funct3)
						lb: loadRegfile(regfilemux::lb);
						lh: loadRegfile(regfilemux::lh);
						lw: loadRegfile(regfilemux::lw);
						lbu: loadRegfile(regfilemux::lbu);
						lhu: loadRegfile(regfilemux::lhu);
						default: ;
					endcase
			  end
		st1: begin
					mem_write = 1'b1;
					mem_byte_enable = wmask;
			  end
		st2: begin
					loadPC(pcmux::pc_plus4);
			  end
		regstate: begin
						case(arith_funct3)
							add: begin
									 loadPC(pcmux::pc_plus4);
									 loadRegfile(regfilemux::alu_out);
									 if(funct7[5]) begin
										setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
									 end else begin
										setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_add);
									 end
								  end
							 slt: begin
										loadPC(pcmux::pc_plus4);
										loadRegfile(regfilemux::br_en);
										setCMP(cmpmux::rs2_out, blt, 1'b1);
									end
							 sltu: begin
										loadPC(pcmux::pc_plus4);
										loadRegfile(regfilemux::br_en);
										setCMP(cmpmux::rs2_out, bltu, 1'b1);
									 end
							 sr: begin
									if(funct7[5]) begin
										loadPC(pcmux::pc_plus4);
										loadRegfile(regfilemux::alu_out);
										setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
									end
									else begin
										loadPC(pcmux::pc_plus4);
										loadRegfile(regfilemux::alu_out);
										setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
									end
								  end
							 default: begin
											loadPC(pcmux::pc_plus4);
											loadRegfile(regfilemux::alu_out);
											setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(arith_funct3));
										 end
						endcase
					 end
		jal: begin
				 loadPC(pcmux::alu_mod2);
				 loadRegfile(regfilemux::pc_plus4);
				 setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
			  end
		jalr: begin
				 loadPC(pcmux::alu_mod2);
				 loadRegfile(regfilemux::pc_plus4);
				 setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
				end
		default: ;
	 endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	  if(rst) begin
			next_states = fetch1; 
	  end
	  else begin
			case(state)
				fetch1: next_states = fetch2;
				fetch2: begin
							if(mem_resp) begin
								next_states = fetch3;
							end
							else begin
								next_states = fetch2;
							end
						  end
				fetch3: next_states = decode;
				decode: begin
							case(opcode)
								op_lui: next_states = lui;
								op_auipc: next_states = auipc;
								op_br: next_states = br;
								op_load: next_states = calc_addr;
								op_store: next_states = calc_addr;
								op_imm: next_states = imm;
								op_reg: next_states = regstate;
								op_jal: next_states = jal;
								op_jalr: next_states = jalr;
								default: next_states = fetch1;
							endcase
						  end
				imm: next_states = fetch1;
				lui: next_states = fetch1;
				auipc: next_states = fetch1;
				br: next_states = fetch1;
				regstate: next_states = fetch1;
				calc_addr: begin
						      if(opcode == op_load) begin
									next_states = ld1;
								end
								else begin
									next_states = st1;
								end
							  end
				ld1: begin
							if(mem_resp) begin
								next_states = ld2;
							end
							else begin
								next_states = ld1;
							end
					  end
				ld2: next_states = fetch1;
				st1: begin
							if(mem_resp) begin
								next_states = st2;
							end
							else begin
								next_states = st1;
							end
					  end
				st2: next_states = fetch1;
				jal: next_states = fetch1;
				jalr: next_states = fetch1;
				default: ;
			endcase
	  end
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_states;
end

endmodule : control
