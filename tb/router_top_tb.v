module router_top_tb;

reg clock;
reg resetn;
reg pkt_valid;

reg [7:0] data_in;

reg read_enb_0;
reg read_enb_1;
reg read_enb_2;

wire [7:0] data_out_0;
wire [7:0] data_out_1;
wire [7:0] data_out_2;

wire busy;
wire error;

router_top DUT(
    .clock(clock),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .data_in(data_in),

    .read_enb_0(read_enb_0),
    .read_enb_1(read_enb_1),
    .read_enb_2(read_enb_2),

    .data_out_0(data_out_0),
    .data_out_1(data_out_1),
    .data_out_2(data_out_2),

    .busy(busy),
    .error(error)
);

//////////////////////////////////////////////////////
// CLOCK
//////////////////////////////////////////////////////

always #5 clock = ~clock;

//////////////////////////////////////////////////////
// TASK : PACKET SEND
//////////////////////////////////////////////////////

task packet_send;

input [1:0] addr;
input [5:0] payload_len;

reg [7:0] header;
reg [7:0] parity;

integer i;

begin

    parity = 0;

    // HEADER

    header = {payload_len,addr};

    @(negedge clock);

    pkt_valid = 1;
    data_in = header;

    parity = parity ^ header;

    // PAYLOAD

    for(i=0;i<payload_len;i=i+1)
    begin

        @(negedge clock);

        data_in = i;

        parity = parity ^ i;

    end

    // PARITY

    @(negedge clock);

    pkt_valid = 0;
    data_in = parity;

end

endtask

//////////////////////////////////////////////////////
// INITIAL
//////////////////////////////////////////////////////

initial
begin

    clock = 0;

    resetn = 0;

    pkt_valid = 0;

    data_in = 0;

    read_enb_0 = 0;
    read_enb_1 = 0;
    read_enb_2 = 0;

    //////////////////////////////////////////////////
    // RESET
    //////////////////////////////////////////////////

    #20;
    resetn = 1;

    //////////////////////////////////////////////////
    // SEND PACKET TO FIFO0
    //////////////////////////////////////////////////

    #20;

    packet_send(2'b00,6'd5);

    //////////////////////////////////////////////////
    // READ FIFO0
    //////////////////////////////////////////////////

    #50;

    read_enb_0 = 1;

    #100;

    read_enb_0 = 0;

    //////////////////////////////////////////////////
    // SEND PACKET TO FIFO1
    //////////////////////////////////////////////////

    #20;

    packet_send(2'b01,6'd4);

    //////////////////////////////////////////////////
    // READ FIFO1
    //////////////////////////////////////////////////

    #50;

    read_enb_1 = 1;

    #100;

    read_enb_1 = 0;

    //////////////////////////////////////////////////
    // SEND PACKET TO FIFO2
    //////////////////////////////////////////////////

    #20;

    packet_send(2'b10,6'd3);

    //////////////////////////////////////////////////
    // READ FIFO2
    //////////////////////////////////////////////////

    #50;

    read_enb_2 = 1;

    #100;

    read_enb_2 = 0;

    //////////////////////////////////////////////////
    // FINISH
    //////////////////////////////////////////////////

    #100;
    $finish;

end

endmodule
