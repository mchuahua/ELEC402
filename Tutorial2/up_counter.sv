
module up_counter (
    input logic clk,
    input logic rst,
    input logic en,
  
    output logic[7:0] count
);
    
always_ff @(posedge clk) begin
    if (rst) begin
        count <= 0;
    end

    else if (en) begin
        count <= count + 1;
    end
end
    
endmodule