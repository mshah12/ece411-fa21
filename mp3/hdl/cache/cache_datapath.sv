/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */
`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input logic clk,
    input logic rst,
    input logic [31:0] mem_address, // from CPU
    output logic [255:0] mem_rdata256, // to CPU
    input logic [255:0] mem_wdata256, // from CPU
    input logic [31:0] mem_byte_enable256, // from CPU
    output logic [31:0] pmem_address, // to Memory
    input logic [255:0] pmem_rdata, // from Memory
    output logic [255:0] pmem_wdata, // to Memory
    input logic lru_in,
    input logic dirty0_in,
    input logic dirty1_in,
    input logic valid0_in,
    input logic valid1_in,
    input logic ld_dirty0,
    input logic ld_dirty1,
    input logic ld_valid0,
    input logic ld_valid1,
    input logic ld_lru,
    input logic ld_tag0,
    input logic ld_tag1,
    input logic pmem_addr_sel,
    input logic [31:0] way0_byte_enable,
    input logic [31:0] way1_byte_enable,
    input logic way0_sel,
    input logic way1_sel,
    output logic lru_out,
    output logic dirty0_out,
    output logic dirty1_out,
    output logic valid0_out,
    output logic valid1_out,
    output logic hit_out,
	 output logic hit0,
	 output logic hit1
);

logic [23:0] tag0_out;
logic [23:0] tag1_out;
logic [255:0] data0_out;
logic [255:0] data1_out;
logic [255:0] cache_data_mux_out;
logic [31:0] address_mux1_out;
logic [31:0] write_byte_enable;
logic [255:0] write_data_out0;
logic [255:0] write_data_out1;

assign hit0 = ((tag0_out == mem_address[31:8]) && valid0_out);
assign hit1 = ((tag1_out == mem_address[31:8]) && valid1_out);
assign hit_out = (hit0 | hit1);
assign mem_rdata256 = cache_data_mux_out;

cache_structure way0 (
    .clk (clk),
    .rst (rst),
    .dirty_in (dirty0_in),
    .valid_in (valid0_in),
    .tag_in (mem_address[31:8]),
    .data_in (write_data_out0),
    .index (mem_address[7:5]),
    .ld_dirty (ld_dirty0),
    .ld_valid (ld_valid0),
    .ld_tag (ld_tag0),
    .write_enable256 (way0_byte_enable),
    .dirty_out (dirty0_out),
    .valid_out (valid0_out),
    .tag_out (tag0_out),
    .data_out (data0_out)
);

cache_structure way1 (
    .clk (clk),
    .rst (rst),
    .dirty_in (dirty1_in),
    .valid_in (valid1_in),
    .tag_in (mem_address[31:8]),
    .data_in (write_data_out1),
    .index (mem_address[7:5]),
    .ld_dirty (ld_dirty1),
    .ld_valid (ld_valid1),
    .ld_tag (ld_tag1),
    .write_enable256 (way1_byte_enable),
    .dirty_out (dirty1_out),
    .valid_out (valid1_out),
    .tag_out (tag1_out),
    .data_out (data1_out)
);

array lru (
    .clk (clk),
    .rst (rst),
    .read (1'b1),
    .load (ld_lru),
    .rindex (mem_address[7:5]),
    .windex (mem_address[7:5]),
    .datain (lru_in),
    .dataout (lru_out)
);

/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    //Cache Data Mux
    unique case (hit1)
        1'b0: cache_data_mux_out = data0_out;
        1'b1: cache_data_mux_out = data1_out;
        default: ;
    endcase

    //Address Mux 1
    unique case (lru_out)
        1'b0: address_mux1_out = {tag0_out, mem_address[7:5], 5'b00000};
        1'b1: address_mux1_out = {tag1_out, mem_address[7:5], 5'b00000};
        default: ;
    endcase

    //Address Mux 2
    unique case (pmem_addr_sel)
        1'b0: pmem_address = {mem_address[31:5], 5'b00000};
        1'b1: pmem_address = address_mux1_out;
        default: ;
    endcase

    //Cacheline Adapter line_i Mux
    unique case (lru_out)
        1'b0: pmem_wdata = data0_out;
        1'b1: pmem_wdata = data1_out;
        default: ;
    endcase

    //Way0 Data Mux
    unique case (way0_sel)
        1'b0: write_data_out0 = mem_wdata256;
        1'b1: write_data_out0 = pmem_rdata;
        default: ;
    endcase  

    //Way1 Data Mux
    unique case (way1_sel)
        1'b0: write_data_out1 = mem_wdata256;
        1'b1: write_data_out1 = pmem_rdata;
        default: ;
    endcase  
end
/*****************************************************************************/

endmodule : cache_datapath
