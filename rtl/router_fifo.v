module router_fifo(
    input clock,
    input resetn,
    input write_enb,
    input read_enb,
    input soft_reset,
    input lfd_state,
    input [7:0] data_in,

    output full,
    output empty,
    output reg [7:0] data_out
);

reg [8:0] mem[15:0];

reg [4:0] wr_ptr;
reg [4:0] rd_ptr;

integer i;

assign full =
       ((wr_ptr[4] != rd_ptr[4]) &&
       (wr_ptr[3:0] == rd_ptr[3:0]));

assign empty = (wr_ptr == rd_ptr);

always @(posedge clock)
begin

    if(!resetn)
    begin

        wr_ptr <= 0;
        rd_ptr <= 0;
        data_out <= 0;

        for(i=0;i<16;i=i+1)
            mem[i] <= 0;

    end

    else if(soft_reset)
    begin

        wr_ptr <= 0;
        rd_ptr <= 0;
        data_out <= 0;

        for(i=0;i<16;i=i+1)
            mem[i] <= 0;

    end

    else
    begin

        if(write_enb && !full)
        begin
            mem[wr_ptr[3:0]] <= {lfd_state,data_in};
            wr_ptr <= wr_ptr + 1'b1;
        end

        if(read_enb && !empty)
        begin
            data_out <= mem[rd_ptr[3:0]][7:0];
            rd_ptr <= rd_ptr + 1'b1;
        end

    end

end

endmodule
