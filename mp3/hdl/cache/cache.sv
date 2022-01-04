/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    // Cache & CPU Connections
    input logic clk,
    input logic rst,
    input logic [31:0] mem_address,
    input logic [31:0] mem_wdata,
    input logic mem_read,
    input logic mem_write,
    input logic [3:0] mem_byte_enable,
    output logic [31:0] mem_rdata,
    output logic mem_resp,
    // Cache & Memory Connections
    input logic [255:0] pmem_rdata,
    input logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write,
    output logic [31:0] pmem_address,
    output logic [255:0] pmem_wdata
);

logic [255:0] mem_rdata256;
logic [255:0] mem_wdata256;
logic [31:0] mem_byte_enable256;
logic lru_in;
logic dirty0_in;
logic dirty1_in;
logic valid0_in;
logic valid1_in;
logic ld_dirty0;
logic ld_dirty1;
logic ld_valid0;
logic ld_valid1;
logic ld_lru;
logic ld_tag0;
logic ld_tag1;
logic pmem_addr_sel;
logic [31:0] way0_byte_enable;
logic [31:0] way1_byte_enable;
logic way0_sel;
logic way1_sel;
logic lru_out;
logic dirty0_out;
logic dirty1_out;
logic valid0_out;
logic valid1_out;
logic hit_out;
logic hit0;
logic hit1;
logic [31:0] address;
assign address = mem_address;

cache_control control(.*);

cache_datapath datapath(.*);

bus_adapter bus_adapter(.*);

endmodule : cache
