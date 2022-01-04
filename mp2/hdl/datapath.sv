`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module datapath
(
    input clk,
    input rst,
    input logic load_mdr,
	 input logic load_pc,
	 input logic load_ir,
	 input logic load_regfile,
	 input logic load_mar,
	 input logic load_data_out,
    input rv32i_word mem_rdata,
	 input alu_ops aluop,
	 input pcmux::pcmux_sel_t pcmux_sel,
	 input branch_funct3_t cmpop,
	 input alumux::alumux1_sel_t alumux1_sel,
	 input alumux::alumux2_sel_t alumux2_sel,
	 input regfilemux::regfilemux_sel_t regfilemux_sel,
	 input marmux::marmux_sel_t marmux_sel,
	 input cmpmux::cmpmux_sel_t cmpmux_sel,
	 output rv32i_opcode opcode,
	 output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic br_en,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output rv32i_word mem_wdata,
	 output rv32i_word mem_address,
	 output logic [1:0] shift_bits 
	 // signal used by RVFI Monitor
    /* You will need to connect more signals to your datapath module*/	 
);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out;
rv32i_word marmux_out;
rv32i_word mdrreg_out;
rv32i_word ir_outi;
rv32i_word ir_outs;
rv32i_word ir_outb;
rv32i_word ir_outu;
rv32i_word ir_outj;
logic [4:0] rd;
logic [31:0] pc_out;
logic [31:0] alumux1_sel_out;
logic [31:0] alumux2_sel_out;
logic [31:0] alu_out;
logic [31:0] cmpmux_out;
logic [31:0] regfilemux_out;
logic [31:0] rs1_out;
logic [31:0] rs2_out;
logic [31:0] temp_address;
logic [31:0] write_data;

assign mem_wdata = write_data << (8 * shift_bits); 
assign mem_address = temp_address & 32'hFFFFFFFC;
assign shift_bits = temp_address[1:0];
/*****************************************************************************/


/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
	.clk (clk),
	.rst (rst),
	.load (load_ir),
	.in (mdrreg_out),
	.funct3 (funct3),
	.funct7 (funct7),
	.opcode (opcode),
	.i_imm (ir_outi),
	.s_imm (ir_outs),
	.b_imm (ir_outb),
	.u_imm (ir_outu),
	.j_imm (ir_outj),
	.rs1 (rs1),
	.rs2 (rs2),
	.rd (rd)
);

pc_register PC(
	.clk (clk),
	.rst (rst),
	.load (load_pc),
	.in (pcmux_out),
	.out (pc_out)
);

register MDR(
    .clk  (clk),
    .rst (rst),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);

register MAR(
    .clk  (clk),
    .rst (rst),
    .load (load_mar),
    .in   (marmux_out),
    .out  (temp_address)
);

register mem_data_out(
    .clk  (clk),
    .rst (rst),
    .load (load_data_out),
    .in   (rs2_out),
    .out  (write_data)
);

regfile regfile(
	.clk (clk),
	.rst (rst),
	.load (load_regfile),
	.in (regfilemux_out),
	.src_a (rs1),
	.src_b (rs2),
	.dest (rd),
	.reg_a (rs1_out),
	.reg_b (rs2_out)
);

/*****************************************************************************/

/******************************* ALU and CMP *********************************/
alu ALU (
	.aluop (aluop),
	.a (alumux1_sel_out),
	.b (alumux2_sel_out),
	.f (alu_out)
);

cmp CMP (
	.cmpop (cmpop),
	.rs1_out (rs1_out),
	.rs2_imm (cmpmux_out),
	.cmp_out (br_en)
);

/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog.  In this case, we actually use
    // Offensive programming --- making simulation halt with a fatal message
    // warning when an unexpected mux select value occurs
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out: pcmux_out = alu_out;
    	  pcmux::alu_mod2: pcmux_out = ({alu_out[31:1], 1'b0});
        default: `BAD_MUX_SEL;
    endcase
	 
	 unique case (marmux_sel)
        marmux::pc_out: marmux_out = pc_out;
        marmux::alu_out: marmux_out = alu_out;
        default: `BAD_MUX_SEL;
    endcase
	 
	 unique case (alumux1_sel)
        alumux::rs1_out: alumux1_sel_out = rs1_out;
        alumux::pc_out: alumux1_sel_out = pc_out;
        default: `BAD_MUX_SEL;
    endcase
	 
	 unique case (alumux2_sel)
        alumux::i_imm: alumux2_sel_out = ir_outi;
        alumux::u_imm: alumux2_sel_out = ir_outu;
		  alumux::b_imm: alumux2_sel_out = ir_outb;
        alumux::s_imm: alumux2_sel_out = ir_outs;
		  alumux::j_imm: alumux2_sel_out = ir_outj;
        alumux::rs2_out: alumux2_sel_out = rs2_out;
        default: `BAD_MUX_SEL;
    endcase
	 
	 unique case (cmpmux_sel)
        cmpmux::rs2_out: cmpmux_out = rs2_out;
        cmpmux::i_imm: cmpmux_out = ir_outi;
        default: `BAD_MUX_SEL;
    endcase
	 
	 unique case (regfilemux_sel)
        regfilemux::alu_out: regfilemux_out = alu_out;
        regfilemux::br_en: regfilemux_out = {{31'd0}, br_en};
		  regfilemux::u_imm: regfilemux_out = ir_outu;  
        regfilemux::lw: regfilemux_out = mdrreg_out;
		  regfilemux::pc_plus4: regfilemux_out = pc_out + 4;
        regfilemux::lb: begin
									case(shift_bits)
										2'b00: regfilemux_out = {{24{mdrreg_out[7]}}, mdrreg_out[7:0]};
										2'b01: regfilemux_out = {{24{mdrreg_out[15]}}, mdrreg_out[15:8]};
										2'b10: regfilemux_out = {{24{mdrreg_out[23]}}, mdrreg_out[23:16]};
										2'b11: regfilemux_out = {{24{mdrreg_out[31]}}, mdrreg_out[31:24]};
										default: regfilemux_out = {{24{mdrreg_out[7]}}, mdrreg_out[7:0]};
									endcase
								end
		  regfilemux::lbu: begin
									case(shift_bits)
										2'b00: regfilemux_out = {{24'd0}, mdrreg_out[7:0]};
										2'b01: regfilemux_out = {{24'd0}, mdrreg_out[15:8]};
										2'b10: regfilemux_out = {{24'd0}, mdrreg_out[23:16]};
										2'b11: regfilemux_out = {{24'd0}, mdrreg_out[31:24]};
										default: regfilemux_out = {{24'd0}, mdrreg_out[7:0]};
									endcase
								end
        regfilemux::lh: begin
									case(shift_bits)
										2'b00: regfilemux_out = {{16{mdrreg_out[15]}}, mdrreg_out[15:0]};
										2'b10: regfilemux_out = {{16{mdrreg_out[31]}}, mdrreg_out[31:16]};
										default: regfilemux_out = {{16{mdrreg_out[15]}}, mdrreg_out[15:0]};
									endcase
								end 		  
		  regfilemux::lhu: begin
									case(shift_bits)
										2'b00: regfilemux_out = {{16'd0}, mdrreg_out[15:0]};
										2'b10: regfilemux_out = {{16'd0}, mdrreg_out[31:16]};
										default: regfilemux_out = {{16'd0}, mdrreg_out[15:0]};
									endcase
								end 
        default: `BAD_MUX_SEL;
    endcase
end
/*****************************************************************************/
endmodule : datapath
