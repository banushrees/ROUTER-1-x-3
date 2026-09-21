module router_sync(
    input clock,
    input resetn,
    input detect_add,
    input write_enb_reg,

    input read_enb_0,
    input read_enb_1,
    input read_enb_2,

    input empty_0,
    input empty_1,
    input empty_2,

    input full_0,
    input full_1,
    input full_2,

    input [1:0] data_in,

    output reg [2:0] write_enb,
    output reg fifo_full
);

reg [1:0] addr;

always @(posedge clock)
begin

    if(!resetn)
        addr <= 0;

    else if(detect_add)
        addr <= data_in;

end

always @(*)
begin

    write_enb = 3'b000;

    case(addr)

        2'b00:
        begin
            write_enb = (write_enb_reg) ? 3'b001 : 3'b000;
            fifo_full = full_0;
        end

        2'b01:
        begin
            write_enb = (write_enb_reg) ? 3'b010 : 3'b000;
            fifo_full = full_1;
        end

        2'b10:
        begin
            write_enb = (write_enb_reg) ? 3'b100 : 3'b000;
            fifo_full = full_2;
        end

        default:
        begin
            write_enb = 3'b000;
            fifo_full = 1'b0;
        end

    endcase

end

endmodule
