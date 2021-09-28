module fsm
#(
    parameter CORRECT_PIN = 14'd1234,
    parameter SAVINGS_FUNDS_AMOUNT = 14'd1000,
    parameter CHEQUING_FUNDS_AMOUNT = 14'd25
)
(
    //Inputs
    input logic clk,                            // Drives entire FSM module
    input logic rst,                            // Drives initialization reset 
    input logic bank_card_insert,               // Starts FSM 
    input logic deposit_withdrawal_selection,   // Selects deposit or withdrawal (see localparam below)
    input logic account_selection,              // Selects chequing/savings (see localparam below)
    input logic [13:0] amount,                  // Indicates amount for withdrawal/deposit
    input logic [13:0] pin,                     // Indicates input pin (for validation with CORRECT_PIN / pin_local)

    //Outputs
    output logic open_atm_out,                  // Opens ATM deposit out slot for dispensing cash
    output logic open_atm_in,                   // Opens ATM withdraw in slow for receiving cash / check
    output logic ready                          // Indicates that ATM is ready to be used (not currently being used)

);

    // Local parameters for usage (easier to read later on)
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
        idle,                       // (1) Idle state for after reset.
        pin_check,                  // (2) Pin check state for validating input pin is correct to local pin.
        select_deposit_withdrawal,  // (3) Deposit/Withdrawal check state for selecting either deposit or withdrawal
        
        //Deposit states
        deposit_account_selection,  // (4) If deposit was chosen in (3), this state starts the deposit phase and selects the deposit account
        deposit_cash_or_check,      // (5) Confirmation state that moves to open_atm_in state
        open_atm_in,                // (6) State for ATM deposit slot to be opened.

        //Withdrawal states
        withdrawal_account_selection,// (7) If withdrawal was chosen in (3), this state starts the deposit phase and selects the withdrawal account
        withdrawal_amount_selection,// (8) Records amount to be withdrawn from the amount input
        withdraw_chequing,          // (9) Confirmation state for chequing (automatically moves to insufficient funds check)
        withdraw_savings,           // (10) Confirmation state for savings (automatically moves to insufficient funds check)
        insufficient_funds_check,   // (11) Checks for insufficient funds in chosen chequing/savings to withdraw from
        open_atm_out,               // (12) State for ATM withdrawal slot to be opened.

        // Done, telling you to withdraw card, wait for bank_card_insert to goto low
        withdraw_card               // (13) Loop to make sure card is withdrawn (bank_card_insert set to low)
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

// Main logic state machine. See state comments above for their functionality
    always@(posedge clk) begin
        if (rst) begin
            //reset stuff in here, including controls for opening/closing the withdrawal + deposit windows as well as the local values for the atm.
            open_atm_in <= 1'b0;
            open_atm_out <= 1'b0;
            {savings_local, chequing_local, pin_local} <= {SAVINGS_FUNDS_AMOUNT, CHEQUING_FUNDS_AMOUNT, CORRECT_PIN};
            state <= idle;
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