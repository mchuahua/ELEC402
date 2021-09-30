module div7_tb();

    logic clk, rst, y;

    div7_fsm dut(.*);

    initial begin
        clk = 0;
        forever begin
            #1;
            clk = ~clk;
        end
    end

    initial begin
        rst = 1;
        #2; 
        rst = 0;
    end

endmodule