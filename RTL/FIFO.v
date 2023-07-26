module FIFO #(parameter FIFO_DEPTH = 256, DATA_SIZE=8)(
    input wire [DATA_SIZE-1:0] Data_in,
    input wire wr_en,rd_en,
    input wire rst_n,clk,
    output reg [DATA_SIZE-1:0] Data_out,
    output reg Full,Empty
);

/*The FIFO Memory*/
reg [DATA_SIZE-1:0] FIFO [0:FIFO_DEPTH-1];

/*Internal signals to temporarily store output data before providing it on the external bus*/
reg [DATA_SIZE-1:0] Data_out_next;

/*Counter to count the occuppied cells in the FIFO*/
localparam Counter_Bits = $clog2(FIFO_DEPTH);
reg [Counter_Bits-1:0] counter_reg,counter_next;

/*
    FIFO Head and Tail pointers:
    - The Head points at the first empty cells in the FIFO
    - The Tail points at the cell whose data should be read.
*/
reg [Counter_Bits-1 : 0] Head_reg,Head_next,Tail_reg,Tail_next;

/*********************Counter Logic************************/
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)
    begin
        counter_reg<='b0;
    end
    else
    begin
        counter_reg<=counter_next;
    end
end

 /*Next state of counter logic*/
always @(*) begin
    if((!Empty && rd_en) && (!Full && wr_en))
    begin
        counter_next = counter_reg;
    end
    else if(!Full && wr_en)
    begin
        counter_next = counter_reg + 1'b1;
    end
    else if(!Empty && rd_en)
    begin
        counter_next = counter_reg - 1'b1;
    end
    else
    begin
        counter_next = counter_reg;
    end
end

/*********************Full and Empty flags Logic************************/
always @(counter_reg) begin
    Full = (counter_reg == FIFO_DEPTH);
    Empty =(counter_reg == 'b0);
end

/*********************Head and Tail Pointers Logic************************/
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)
    begin
        Head_reg<='b0;
        Tail_reg<='b0;
    end
    else
    begin
        Head_reg<=Head_next;
        Tail_reg<=Tail_next;
    end
end

/*Next State Logic*/
always @(*) begin
    /*Head*/
    if(!Full && wr_en && (Head_reg != FIFO_DEPTH))
    begin
        Head_next = Head_reg + 1'b1;
    end
    else if(!Full && wr_en && (Head_reg == FIFO_DEPTH))
    begin
        Head_next = 'b0;
    end
    else
    begin
        Head_next = Head_reg;
    end

    /*Tail*/
    if(!Empty && rd_en && (Tail_reg != FIFO_DEPTH))
    begin
        Tail_next = Tail_reg + 1'b1;
    end
    else if(!Empty && rd_en && (Tail_reg == FIFO_DEPTH))
    begin
        Tail_next = 'b0;
    end
    else
    begin
        Tail_next = Tail_reg;
    end
end

/*********************Reading Operation Logic************************/
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)
    begin
        Data_out<='b0;
    end
    else
    begin
        Data_out<=Data_out_next;
    end
end

/*Next State Logic*/
always @(*) begin
    if(!Empty && rd_en)
    begin
        Data_out_next = FIFO[Tail_reg];
    end
    else
    begin
        Data_out_next = Data_out;    
    end
end

/*********************Writing Operation Logic************************/
always @(posedge clk) begin
    if(!Full && wr_en)
    begin
        FIFO[Head_reg] <= Data_in;
    end
    else
    begin
        FIFO[Head_reg] <= FIFO[Head_reg];
    end
end
endmodule