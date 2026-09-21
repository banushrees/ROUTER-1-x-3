module router_fsm(
    input clock,
    input resetn,
    input pkt_valid,
    input fifo_full,

    output reg detect_add,
    output reg ld_state,
    output reg laf_state,
    output reg full_state,
    output reg write_enb_reg,
    output reg rst_int_reg,
    output reg lfd_state,
    output reg busy
);

parameter DECODE_ADDRESS  = 3'b000,
          LOAD_FIRST_DATA = 3'b001,
          LOAD_DATA       = 3'b010,
          FIFO_FULL_STATE = 3'b011;

reg [2:0] state,next_state;

always @(posedge clock)
begin

    if(!resetn)
        state <= DECODE_ADDRESS;

    else
        state <= next_state;

end

always @(*)
begin

    next_state = state;

    case(state)

        DECODE_ADDRESS:
        begin
            if(pkt_valid)
                next_state = LOAD_FIRST_DATA;
        end

        LOAD_FIRST_DATA:
            next_state = LOAD_DATA;

        LOAD_DATA:
        begin
            if(fifo_full)
                next_state = FIFO_FULL_STATE;

            else if(!pkt_valid)
                next_state = DECODE_ADDRESS;
        end

        FIFO_FULL_STATE:
        begin
            if(!fifo_full)
                next_state = LOAD_DATA;
        end

    endcase

end

always @(*)
begin

    detect_add   = 0;
    ld_state     = 0;
    laf_state    = 0;
    full_state   = 0;
    write_enb_reg= 0;
    rst_int_reg  = 0;
    lfd_state    = 0;
    busy         = 0;

    case(state)

        DECODE_ADDRESS:
            detect_add = 1;

        LOAD_FIRST_DATA:
        begin
            lfd_state = 1;
            write_enb_reg = 1;
        end

        LOAD_DATA:
        begin
            ld_state = 1;
            write_enb_reg = 1;
        end

        FIFO_FULL_STATE:
        begin
            full_state = 1;
            busy = 1;
        end

    endcase

end

endmodule
