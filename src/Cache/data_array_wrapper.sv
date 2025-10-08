module data_array_wrapper (
    input          CK,
    input          CS,
    input          OE,
    input  [4:0]   A,
    input  [ 15:0] WEB1,
    input  [ 15:0] WEB2,
    input  [127:0] DI,
    output [127:0] DO1,
    output [127:0] DO2
);

    logic        CEB1, CEB2, CEB3, CEB4;
    logic [63:0] Q1, Q2, Q3, Q4;
    logic [63:0] BWEB1, BWEB2, BWEB3, BWEB4;

    assign CEB1 = ~(CS & (OE | (|WEB1[15:8]) ));
    assign CEB2 = ~(CS & (OE | (|WEB1[ 7:0]) ));
    assign CEB3 = ~(CS & (OE | (|WEB2[15:8]) ));
    assign CEB4 = ~(CS & (OE | (|WEB2[ 7:0]) ));

    assign BWEB1 = {{8{WEB1[15]}}, {8{WEB1[14]}}, {8{WEB1[13]}}, {8{WEB1[12]}},
                    {8{WEB1[11]}}, {8{WEB1[10]}}, {8{WEB1[ 9]}}, {8{WEB1[ 8]}}};
    assign BWEB2 = {{8{WEB1[ 7]}}, {8{WEB1[ 6]}}, {8{WEB1[ 5]}}, {8{WEB1[ 4]}},
                    {8{WEB1[ 3]}}, {8{WEB1[ 2]}}, {8{WEB1[ 1]}}, {8{WEB1[ 0]}}};
    assign BWEB3 = {{8{WEB2[15]}}, {8{WEB2[14]}}, {8{WEB2[13]}}, {8{WEB2[12]}},
                    {8{WEB2[11]}}, {8{WEB2[10]}}, {8{WEB2[ 9]}}, {8{WEB2[ 8]}}};
    assign BWEB4 = {{8{WEB2[ 7]}}, {8{WEB2[ 6]}}, {8{WEB2[ 5]}}, {8{WEB2[ 4]}},
                    {8{WEB2[ 3]}}, {8{WEB2[ 2]}}, {8{WEB2[ 1]}}, {8{WEB2[ 0]}}};

    assign DO1 = {Q1, Q2};
    assign DO2 = {Q3, Q4};

    TS1N16ADFPCLLLVTA128X64M4SWSHOD_data_array i_data_array1_1 (
        .CLK        ( CK           ),
        .A          ( A            ),
        .CEB        ( CEB1         ),  // chip enable, active LOW
        .WEB        ( ~|WEB1[15:8] ),  // write:LOW, read:HIGH
        .BWEB       ( ~BWEB1       ),  // bitwise write enable write:LOW
        .D          ( DI[127:64]   ),  // Data into RAM
        .Q          ( Q1           ),  // Data out of RAM
        .RTSEL      (              ),
        .WTSEL      (              ),
        .SLP        (              ),
        .DSLP       (              ),
        .SD         (              ),
        .PUDELAY    (              )
    );

    TS1N16ADFPCLLLVTA128X64M4SWSHOD_data_array i_data_array1_2 (
        .CLK        ( CK           ),
        .A          ( A            ),
        .CEB        ( CEB2         ),  // chip enable, active LOW
        .WEB        ( ~|WEB1[ 7:0] ),  // write:LOW, read:HIGH
        .BWEB       ( ~BWEB2       ),  // bitwise write enable write:LOW
        .D          ( DI[63:0]     ),  // Data into RAM
        .Q          ( Q2           ),  // Data out of RAM
        .RTSEL      (              ),
        .WTSEL      (              ),
        .SLP        (              ),
        .DSLP       (              ),
        .SD         (              ),
        .PUDELAY    (              )
    );

    TS1N16ADFPCLLLVTA128X64M4SWSHOD_data_array i_data_array2_1 (
        .CLK        ( CK           ),
        .A          ( A            ),
        .CEB        ( CEB3         ),  // chip enable, active LOW
        .WEB        ( ~|WEB2[15:8] ),  // write:LOW, read:HIGH
        .BWEB       ( ~BWEB3       ),  // bitwise write enable write:LOW
        .D          ( DI[127:64]   ),  // Data into RAM
        .Q          ( Q3           ),  // Data out of RAM
        .RTSEL      (              ),
        .WTSEL      (              ),
        .SLP        (              ),
        .DSLP       (              ),
        .SD         (              ),
        .PUDELAY    (              )
    );

    TS1N16ADFPCLLLVTA128X64M4SWSHOD_data_array i_data_array2_2 (
        .CLK        ( CK           ),
        .A          ( A            ),
        .CEB        ( CEB4         ),  // chip enable, active LOW
        .WEB        ( ~|WEB2[ 7:0] ),  // write:LOW, read:HIGH
        .BWEB       ( ~BWEB4       ),  // bitwise write enable write:LOW
        .D          ( DI[63:0]     ),  // Data into RAM
        .Q          ( Q4           ),  // Data out of RAM
        .RTSEL      (              ),
        .WTSEL      (              ),
        .SLP        (              ),
        .DSLP       (              ),
        .SD         (              ),
        .PUDELAY    (              )
    );

endmodule