import cam_types::*;

module testbench(cam_itf itf);

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE

val_t temp;

task write(input key_t key, input val_t val);
		itf.key <= key;
		itf.val_i <= val;
		itf.rw_n <= 1'b0;
		itf.valid_i <= 1'b1;
		@(tb_clk);
endtask : write

task read(input key_t key, output val_t val);
	itf.key <= key;
	itf.rw_n <= 1'b1;
	itf.valid_i <= 1'b1;
	@(tb_clk);
	val <= itf.val_o;
endtask : read

task evict();
	for(int i = 0; i < camsize_p; ++i) begin
		write(i, i);
	end
	
	@(tb_clk);
	
	for(int i = 8; i < 16; ++i) begin
		write(i, i);
	end
	@(tb_clk);
	
endtask : evict

task test_read();
	for(int i = 0; i < camsize_p; ++i) begin
		write(i, i);
	end
	
	@(tb_clk);
	
	for(int i = 0; i < camsize_p; ++i) begin
		read(i, i);
	end
endtask : test_read

task write_write();
	for(int i = 0; i < camsize_p; ++i) begin
		write(i, i);
		@(tb_clk);
		write(i, i + 1'b1);
		@(tb_clk);
	end
endtask : write_write

task write_read();

	for(int i = 0; i < camsize_p; ++i) begin
		write(i, i);
		@(tb_clk);
		read(i, temp);
		@(tb_clk);
		assert (itf.val_o == i) else  begin
			itf.tb_report_dut_error(READ_ERROR);
			$error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, temp);
		end
		@(tb_clk);
	end
	
endtask : write_read

initial begin
    $display("Starting CAM Tests");

    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv

	 evict();
	 
	 test_read();
	 
	 write_write();
	 
	 write_read();

    /**********************************************************************/

    itf.finish();
end

endmodule : testbench
