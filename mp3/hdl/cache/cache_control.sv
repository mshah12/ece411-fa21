/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input logic clk,
    input logic rst,
    input logic lru_out,
    input logic dirty0_out,
    input logic dirty1_out,
	 input logic valid0_out,
    input logic valid1_out,
    input logic hit_out,
	 input logic hit0,
	 input logic hit1,
    input logic mem_read,
    input logic mem_write,
    input logic pmem_resp,
    input logic [31:0] mem_byte_enable256,
    output logic lru_in,
    output logic dirty0_in,
    output logic dirty1_in,
    output logic valid0_in,
    output logic valid1_in,
    output logic ld_dirty0,
    output logic ld_dirty1,
    output logic ld_valid0,
    output logic ld_valid1,
    output logic ld_lru,
    output logic ld_tag0,
    output logic ld_tag1,
    output logic pmem_addr_sel,
    output logic [31:0] way0_byte_enable,
    output logic [31:0] way1_byte_enable,
    output logic way0_sel,
    output logic way1_sel,
    output logic pmem_read,
    output logic pmem_write,
    output logic mem_resp
);

enum int unsigned {
    /* List of states */
	idle,
	compare,
	write_back,
	allocate,
	update
} state, next_state;

function void set_defaults();
    ld_dirty0 = 1'b0;
    ld_dirty1 = 1'b0;
    ld_valid0 = 1'b0;
    ld_valid1 = 1'b0;
    ld_lru = 1'b0;
    ld_tag0 = 1'b0;
    ld_tag1 = 1'b0;
    lru_in = lru_out;
    dirty0_in = dirty0_out;
    dirty1_in = dirty1_out;
    valid0_in = valid0_out;
    valid1_in = valid1_out;
    way0_byte_enable = {32{1'b0}};
    way1_byte_enable = {32{1'b0}};
    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
	pmem_addr_sel = 1'b0;
	way0_sel = 1'b0;
	way1_sel = 1'b0;
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
	 case(state)
		idle: ;
		compare: begin
                    if(hit_out) begin
									if(hit0 && mem_write) begin
										dirty0_in = 1'b1;
										ld_dirty0 = 1'b1;
										way0_byte_enable = mem_byte_enable256;
									end
									else if (hit1 && mem_write) begin
										dirty1_in = 1'b1;
										ld_dirty1 = 1'b1;
										way1_byte_enable = mem_byte_enable256;
									end
									mem_resp = 1'b1;
									lru_in = ~lru_out;
									ld_lru = 1'b1;
                    end
                 end
        write_back: begin
                      pmem_write = 1'b1;
                      pmem_addr_sel = 1'b1;  
                    end
        allocate: begin
                    pmem_read = 1'b1;
                    pmem_addr_sel = 1'b0;
                    if(lru_out == 0) begin
                        way0_byte_enable = {32{1'b1}};
                        way0_sel = 1'b1;
								ld_tag0 = 1'b1;
								dirty0_in = 1'b0;
								ld_dirty0 = 1'b1;
								ld_valid0 = 1'b1;
                        valid0_in = 1'b1;
                    end
                    else begin
                        way1_byte_enable = {32{1'b1}};
                        way1_sel = 1'b1;
								ld_tag1 = 1'b1;
								dirty1_in = 1'b0;
								ld_dirty1 = 1'b1;
								ld_valid1 = 1'b1;
                        valid1_in = 1'b1;
                    end
                  end
        update: begin
                    mem_resp = 1'b1;
                    lru_in = ~lru_out;
                    ld_lru = 1'b1;
                    if((lru_out == 0) && mem_write) begin
                        ld_dirty0 = 1'b1;
                        dirty0_in = 1'b1;
                        way0_byte_enable = mem_byte_enable256;
                    end
                    else if((lru_out == 1) && mem_write) begin
                        ld_dirty1 = 1'b1;
                        dirty1_in = 1'b1;
                        way1_byte_enable = mem_byte_enable256;                       
                    end
                end
        default: ;
     endcase
end


always_comb
begin : next_state_logic
	  if(rst) begin
			next_state = idle; 
	  end
	  else begin
			case(state)
				idle: begin
                        if(!mem_read && !mem_write) begin
                            next_state = idle;
                        end
                        else begin
                            next_state = compare;
                        end

                    end
				compare: begin
							if(hit_out) begin
								next_state = idle;
							end
							else if(lru_out == 0 && dirty0_out == 1'b1) begin
								next_state = write_back;
							end else if(lru_out && dirty1_out == 1'b1) begin
								next_state = write_back;
							end
                            else begin
                                next_state = allocate;
                            end
					end
                write_back: begin
                                if(pmem_resp) begin
                                    next_state = allocate;
                                end
                                else begin
                                    next_state = write_back;
                                end
                    end
                allocate: begin
                                if(pmem_resp) begin
                                    next_state = update;
                                end
                                else begin
                                    next_state = allocate;
                                end
                    end
                update: begin
                            next_state = idle;
                        end
			endcase
	  end
end

always_ff @(posedge clk)
begin: next_state_assignment
	 state <= next_state;
end

endmodule : cache_control
