import rv32i_types::*;

module mp3
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

logic [255:0] pmem_wdata256;
logic [255:0] pmem_rdata256;
logic [31:0] pmem_address_cache;
logic pmem_write_cache;
logic pmem_read_cache;
logic pmem_resp_cache;
logic mem_resp;
logic [31:0] mem_wdata;
logic mem_read;
logic mem_write;
logic [3:0] mem_byte_enable;
logic [31:0] mem_rdata;
logic [31:0] mem_address;

// Keep cpu named `cpu` for RVFI Monitor
// Note: you have to rename your mp2 module to `cpu`
cpu_golden cpu(.*);

// Keep cache named `cache` for RVFI Monitor
cache cache(
    .clk (clk),
    .rst (rst),
    .mem_address (mem_address),
    .mem_wdata (mem_wdata),
    .mem_read (mem_read),
    .mem_write (mem_write),
    .mem_byte_enable (mem_byte_enable),
    .mem_rdata (mem_rdata),
    .mem_resp (mem_resp),
    .pmem_rdata (pmem_rdata256),
    .pmem_resp (pmem_resp_cache),
    .pmem_read (pmem_read_cache),
    .pmem_write (pmem_write_cache),
    .pmem_address (pmem_address_cache),
    .pmem_wdata (pmem_wdata256)
);

// From MP1
cacheline_adaptor cacheline_adaptor
(
    .clk (clk),
    .reset_n (~rst),
    .line_i (pmem_wdata256),
    .line_o (pmem_rdata256),
    .read_i (pmem_read_cache),
    .write_i (pmem_write_cache),
    .resp_o (pmem_resp_cache),
    .burst_i (pmem_rdata),
    .burst_o (pmem_wdata),
    .address_o (pmem_address),
    .read_o (pmem_read),
    .write_o (pmem_write),
    .resp_i (pmem_resp),
	.address_i (pmem_address_cache)
);

endmodule : mp3
