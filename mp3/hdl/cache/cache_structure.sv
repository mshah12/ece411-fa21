//import rv32i_types::*; 

module cache_structure (
    input logic clk,
    input logic rst,
    input logic dirty_in,
    input logic valid_in,
    input logic [23:0] tag_in,
    input logic [255:0] data_in,
    input logic [2:0] index,
    input logic ld_dirty,
    input logic ld_valid,
    input logic ld_tag,
    input logic [31:0] write_enable256,
    output logic dirty_out,
    output logic valid_out,
    output logic [23:0] tag_out,
    output logic [255:0] data_out
);

array dirty_array (
    .clk (clk),
    .rst (rst),
    .read (1'b1),
    .load (ld_dirty),
    .rindex (index),
    .windex (index),
    .datain (dirty_in),
    .dataout (dirty_out)
);

array valid_array (
    .clk (clk),
    .rst (rst),
    .read (1'b1),
    .load (ld_valid),
    .rindex (index),
    .windex (index),
    .datain (valid_in),
    .dataout (valid_out)
);

array #(.s_index(3), .width(24)) tag_array(
    .clk (clk),
    .rst (rst),
    .read (1'b1),
    .load (ld_tag),
    .rindex (index),
    .windex (index),
    .datain (tag_in),
    .dataout (tag_out)
);

data_array cache_data (
    .clk (clk),
    .rst (rst),
    .read (1'b1),
    .write_en (write_enable256),
    .rindex (index),
    .windex (index),
    .datain (data_in),
    .dataout (data_out)
);

endmodule : cache_structure
