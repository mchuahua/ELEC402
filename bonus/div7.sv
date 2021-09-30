// Bonus for extra 2% on ELEC402 midterm by Sept 28, 2021.
// Name: Martin Chua
// Student Number: 35713411
// Date: Sept 26, 2021

module div7_fsm(
    input logic clk,
    input logic rst,
    output logic y
);

    enum{
        S0, S1, S2, S3, S4, S5, S6, // ON States
        S7, S8, S9, S10, S11, S12, S13 // OFF States
    } state, next_state;

    always_ff @(posedge clk, negedge clk) begin
        if (rst)
            state <= S0;
        else
            state <= next_state;
    end

    // There are many ways to do div7; here I've done something similar to the div3_fsm example from the slides.
    // Alternatively, I could use a shift register and set a particular bit to be the output.
    always_comb begin : next_state_logic
        case(state)
            S0: next_state = S1;
            S1: next_state = S2;
            S2: next_state = S3;
            S3: next_state = S4;
            S4: next_state = S5;
            S5: next_state = S6;
            S6: next_state = S7;
            S8: next_state = S0;
            S9: next_state = S0;
            S10: next_state = S11;
            S11: next_state = S12;
            S12: next_state = S13;
            S13: next_state = S0;
            default: next_state = S0;
        endcase
    end

    // Output logic for 50% duty cycle
    assign y = (state == S0) || (state == S1) || (state == S3) || (state == S4) || (state == S5) || (state == S6);

endmodule