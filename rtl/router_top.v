module router_top(
    input clock,
    input resetn,
    input pkt_valid,
    input [7:0] data_in,

    input read_enb_0,
    input read_enb_1,
    input read_enb_2,

    output [7:0] data_out_0,
    output [7:0] data_out_1,
    output [7:0] data_out_2,

    output busy,
    output error
);

wire detect_add;
wire ld_state;
wire laf_state;
wire full_state;
wire write_enb_reg;
wire rst_int_reg;
wire lfd_state;

wire [2:0] write_enb;

wire fifo_full;

wire full_0,full_1,full_2;
wire empty_0,empty_1,empty_2;

wire parity_done;
wire low_pkt_valid;

wire [7:0] dout;

router_fsm FSM(
    .clock(clock),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .fifo_full(fifo_full),

    .detect_add(detect_add),
    .ld_state(ld_state),
    .laf_state(laf_state),
    .full_state(full_state),
    .write_enb_reg(write_enb_reg),
    .rst_int_reg(rst_int_reg),
    .lfd_state(lfd_state),
    .busy(busy)
);

router_reg REG(
    .clock(clock),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .fifo_full(fifo_full),
    .rst_int_reg(rst_int_reg),
    .detect_add(detect_add),
    .ld_state(ld_state),
    .laf_state(laf_state),
    .full_state(full_state),
    .lfd_state(lfd_state),
    .data_in(data_in),

    .parity_done(parity_done),
    .low_pkt_valid(low_pkt_valid),
    .err(error),
    .dout(dout)
);

router_sync SYNC(
    .clock(clock),
    .resetn(resetn),
    .detect_add(detect_add),
    .write_enb_reg(write_enb_reg),

    .read_enb_0(read_enb_0),
    .read_enb_1(read_enb_1),
    .read_enb_2(read_enb_2),

    .empty_0(empty_0),
    .empty_1(empty_1),
    .empty_2(empty_2),

    .full_0(full_0),
    .full_1(full_1),
    .full_2(full_2),

    .data_in(data_in[1:0]),

    .write_enb(write_enb),
    .fifo_full(fifo_full)
);

router_fifo FIFO0(
    .clock(clock),
    .resetn(resetn),
    .write_enb(write_enb[0]),
    .read_enb(read_enb_0),
    .soft_reset(1'b0),
    .lfd_state(lfd_state),
    .data_in(dout),

    .full(full_0),
    .empty(empty_0),
    .data_out(data_out_0)
);

router_fifo FIFO1(
    .clock(clock),
    .resetn(resetn),
    .write_enb(write_enb[1]),
    .read_enb(read_enb_1),
    .soft_reset(1'b0),
    .lfd_state(lfd_state),
    .data_in(dout),

    .full(full_1),
    .empty(empty_1),
    .data_out(data_out_1)
);

router_fifo FIFO2(
    .clock(clock),
    .resetn(resetn),
    .write_enb(write_enb[2]),
    .read_enb(read_enb_2),
    .soft_reset(1'b0),
    .lfd_state(lfd_state),
    .data_in(dout),

    .full(full_2),
    .empty(empty_2),
    .data_out(data_out_2)
);

endmodule
