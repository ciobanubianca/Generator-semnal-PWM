module counter (
    // peripheral clock signals
    input clk,
    input rst_n,
    // register facing signals
    output reg [15:0] count_val,
    input [15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input [7:0] prescale
);

reg [15:0] prescale_cnt;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count_val     <= 16'h0000;
        prescale_cnt  <= 16'h0000;
    end 
    else begin
        
        // COUNTER RESET logic
        if(count_reset) begin
            count_val    <= 16'h0000;
            prescale_cnt <= 16'h0000;
        end
        
        // COUNTER ENABLED
        else if(en) begin
            
            prescale_cnt <= prescale_cnt + 16'd1;

            if(prescale_cnt == (16'd1 << prescale) - 1) begin

                prescale_cnt <= 16'd0;

                // UP counting
                if(upnotdown) begin
                    if(count_val >= period)
                        count_val <= 16'd0; // overflow
                    else
                        count_val <= count_val + 16'd1;
                end 

                // DOWN counting
                else begin
                    if(count_val == 16'd0)
                        count_val <= period; // underflow
                    else
                        count_val <= count_val - 16'd1;
                end
            end
        end

        // COUNTER DISABLED
        else begin
            prescale_cnt <= 16'd0; 
        end
    end
end

endmodule
