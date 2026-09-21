module router_reg(
    input clock,
    input resetn,
    input pkt_valid,
    input fifo_full,
    input rst_int_reg,
    input detect_add,
    input ld_state,
    input laf_state,
    input full_state,
    input lfd_state,
    input [7:0] data_in,

    output reg parity_done,
    output reg low_pkt_valid,
    output reg err,
    output reg [7:0] dout
);

reg [7:0] header_byte;
reg [7:0] fifo_full_state_byte;
reg [7:0] internal_parity;
reg [7:0] packet_parity;

always @(posedge clock)
begin

    if(!resetn)
    begin
        dout <= 0;
        internal_parity <= 0;
        parity_done <= 0;
        err <= 0;
    end

    else
    begin

        if(detect_add && pkt_valid)
            header_byte <= data_in;

        if(lfd_state)
        begin
            dout <= header_byte;
            internal_parity <= internal_parity ^ header_byte;
        end

        else if(ld_state && !fifo_full)
        begin
            dout <= data_in;
            internal_parity <= internal_parity ^ data_in;
        end

        else if(laf_state)
            dout <= fifo_full_state_byte;

        if(!pkt_valid)
            packet_parity <= data_in;

        if(parity_done)
        begin
            if(internal_parity != packet_parity)
                err <= 1'b1;
        end

    end

end

endmodule
