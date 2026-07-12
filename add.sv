module add #(
    parameter P_CH  = 4,
    parameter A_BIT = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  in1_valid,
    output logic                  in1_ready,
    input  logic [P_CH*A_BIT-1:0] in1_data,
    input  logic                  in2_valid,
    output logic                  in2_ready,
    input  logic [P_CH*A_BIT-1:0] in2_data,
    output logic                  out_valid,
    input  logic                  out_ready,
    output logic [P_CH*A_BIT-1:0] out_data
);

    logic                  pipe_valid;
    logic [P_CH*A_BIT-1:0] pipe_data;
    logic                  handshake_in;
    logic                  handshake_out;
    logic [P_CH*A_BIT-1:0] calc_result;

    assign handshake_in  = in1_valid && in1_ready && in2_valid && in2_ready;
    assign handshake_out = out_valid && out_ready;


    logic                  buf1_valid;
    logic [P_CH*A_BIT-1:0] buf1_data;
    logic                  buf1_consumed; 

    assign in1_ready = !buf1_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf1_valid <= 1'b0;
            buf1_data  <= '0;
        end else begin
            if (in1_valid && in1_ready) begin
                buf1_valid <= 1'b1;
                buf1_data  <= in1_data;
            end else if (buf1_valid && buf1_consumed) begin
                buf1_valid <= 1'b0;
            end
        end
    end

    logic                  buf2_valid;
    logic [P_CH*A_BIT-1:0] buf2_data;
    logic                  buf2_consumed;

    assign in2_ready = !buf2_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf2_valid <= 1'b0;
            buf2_data  <= '0;
        end else begin
            if (in2_valid && in2_ready) begin
                buf2_valid <= 1'b1;
                buf2_data  <= in2_data;
            end else if (buf2_consumed) begin
                buf2_valid <= 1'b0;
            end
        end
    end

    always_comb begin
        for (int i = 0; i < P_CH; i++) begin

            calc_result[i*A_BIT+:A_BIT] = buf1_data[i*A_BIT+:A_BIT] + buf2_data[i*A_BIT+:A_BIT];
        end
    end

    wire adder_ready_to_compute = buf1_valid && buf2_valid;
    wire pipe_push = adder_ready_to_compute && (!out_valid || out_ready);
    
    assign buf1_consumed = pipe_push;
    assign buf2_consumed = pipe_push;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_valid <= 1'b0;
            pipe_data  <= '0;
        end else begin
            if (pipe_push) begin
                pipe_valid <= 1;
                pipe_data <= calc_result;
            end else if (handshake_out) begin
                pipe_valid <= 0;
            end 
        end
    end
    assign out_valid = pipe_valid;
    assign out_data  = pipe_data;

endmodule