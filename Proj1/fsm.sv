module fsm
#(
    parameter CORRECT_PIN = 14'd1234,
    parameter SAVINGS_FUNDS_AMOUNT = 14'd1000,
    parameter CHEQUING_FUNDS_AMOUNT = 14'd25
)
(
    //Inputs
    input logic clk, 
    input logic rst,
    input logic bank_card_insert, //Start
    input logic deposit_withdrawal_selection,
    input logic account_selection,
    input logic [13:0] amount,
    input logic [13:0] pin,

    //Outputs
    output logic open_atm_out,
    output logic open_atm_in,
    output logic ready

);

    localparam WITHDRAWAL = 1'b0;
    localparam DEPOSIT = 1'b1;
    localparam CHEQUING = 1'b0;
    localparam SAVINGS = 1'b1;

    // Local registers to store values of the savings/chequing/pw that we set via parameters above.
    logic [13:0] savings_local;
    logic [13:0] chequing_local;
    logic [13:0] pin_local;

// States
    enum {
        idle,
        pin_check,
        select_deposit_withdrawal,
        
        //Deposit states
        deposit_account_selection,
        deposit_cash_or_check,
        open_atm_in,

        //Withdrawal states
        withdrawal_account_selection,
        withdrawal_amount_selection,
        withdraw_chequing,
        withdraw_savings,
        insufficient_funds_check,
        open_atm_out,

        // Done, telling you to withdraw card, wait for bank_card_insert to goto low
        withdraw_card
    } state, state_next;

    // Next state logic
    always_comb begin
        case(state)
            open_atm_out:       next_state = withdraw_card;
            open_atm_in:        next_state = withdraw_card;
            withdraw_chequing:  next_state = insufficient_funds_check;
            withdraw_savings:   next_state = insufficient_funds_check;
            default:            next_state = state;
        endcase
    end

// Main logic state machine
    always@(posedge clk) begin
        if (rst) begin
            //reset stuff in here, including controls for opening/closing the withdrawal + deposit windows as well as the local values for the atm.
            open_atm_in = 1'b0;
            open_atm_out = 1'b0;
            {savings_local, chequing_local, pin_local} = {SAVINGS_FUNDS_AMOUNT, CHEQUING_FUNDS_AMOUNT, CORRECT_PIN};
        end
        else begin
            case(state)
                idle: begin
                    if (bank_card_insert) begin
                        state <= pin_check;
                    end
                end
                pin_check: begin
                    if (pin == pin_local) begin
                        state <= select_deposit_withdrawal;
                    end
                    else begin
                        state <=  idle;
                    end
                end
                select_deposit_withdrawal: begin
                    if (deposit_withdrawal_selection == WITHDRAWAL) begin
                        state <= withdrawal_account_selection;
                    end
                    else begin
                        state <= deposit_account_selection;
                    end
                end
                // Deposit states
                deposit_account_selection: begin
                    if (account_selection == CHEQUING)
                        chequing_local = chequing_local + amount;
                    else begin
                        savings_local = savings_local + amount;
                    end
                        state <= deposit_cash_or_check;
                end
                deposit_cash_or_check: begin
                    state <= open_atm_in;
                end
                // Withdrawal states
                withdrawal_account_selection: begin
                    if(account_selection == CHEQUING) begin
                        state <= withdraw_chequing;
                    end
                    else begin
                        state <= withdraw_savings;
                    end
                end
                // Loop insufficient funds check until amount is possible
                insufficient_funds_check: begin
                    if (account_selection == CHEQUING && amount <= chequing_local) begin
                        state <= open_atm_out;
                        chequing_local = chequing_local - amount;
                    end
                    else if (account_selection == SAVINGS && amount <= savings_local) begin
                        state <= open_atm_out;
                        savings_local = savings_local - amount;
                    end
                end
                // Wait for card to be withdrawn before entering idle again
                withdraw_card: begin
                    if (~bank_card_insert) begin
                        state <= idle;
                    end
                end
                default: state <= next_state;    
            endcase
        end
    end

    // So we know that the ATM isn't in use.
    assign ready = (state == idle);

endmodule