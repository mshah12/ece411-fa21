import rv32i_types::*;

module cmp
(
    input branch_funct3_t cmpop,
    input rv32i_word rs1_out, rs2_imm,
    output logic cmp_out
);

always_comb
begin
    unique case (cmpop)
        beq:  cmp_out = (rs1_out == rs2_imm);
        bne:  cmp_out = (rs1_out != rs2_imm);
        blt:  cmp_out = ($signed(rs1_out) < $signed(rs2_imm));
        bge:  cmp_out = ($signed(rs1_out) >= $signed(rs2_imm));
        bltu: cmp_out = (rs1_out < rs2_imm);
        bgeu: cmp_out = (rs1_out >= rs2_imm);
    endcase
end

endmodule : cmp