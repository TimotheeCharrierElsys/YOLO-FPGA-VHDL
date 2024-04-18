.. _module_common:

Module common 
=============

.. _common.full_adder:

full_adder.v 
------------

`View source code on GitHub <https://github.com/TimotheeCharrierElsys/doc/blob/dev/docs/source/modules/common/source/ripple_carry_adder.v>`__.

.. code-block:: verilog
    :linenos:
    :caption: Full Adder module

    module full_adder (
        input a, 
        input b,
        input cin,
        output sum,
        output cout
    );

        // Full adder combinational logic
        assign sum  = a ^ b ^ cin;
        assign cout = ((a ^ b) & cin) | (a & b);

    endmodule

:math:`\text{sum}= a~\oplus~b~\oplus~c`

:math:`c_{out}  = ((a~\oplus~b)~\&~c_{in})~|~(a~\&~b)`



.. _common.ripple_carry_adder:

ripple_carry_adder.v
--------------------

`View source code on GitHub <https://github.com/TimotheeCharrierElsys/doc/blob/dev/docs/source/modules/common/source/full_adder.v>`__.

.. image:: ripple_carry_adder.svg
    :alt: Ripple Carry Adder architecture

.. code-block:: verilog
    :linenos:
    :caption: Ripple Carry Adder module

    module adder100 #(
        parameter data_width = 100
    )(
        input [data_width-1:0] a,
        input [data_width-1:0] b,
        input cin,
        output cout,
        output [data_width-1:0] sum
    );

        assign {cout, sum} = a + b + cin;

    endmodule


.. warning::
    The **drawback** of the ripple carry adder is that the delay for an adder to compute the carry out (from the carry-in, in the worst case) is fairly slow, and the second-stage adder cannot begin computing its carry-out until the first-stage adder has finished.
    See :ref:`common.carry_select_adder` for a reduced computation delay.


.. _common.carry_select_adder:

carry_select_adder.v
--------------------

`View source code on GitHub <https://github.com/TimotheeCharrierElsys/doc/blob/dev/docs/source/modules/common/source/carry_select_adder.v>`__.


One improvement is a carry-select adder, shown below. The first-stage adder is the same as before, but we duplicate the second-stage adder, one assuming `carry_in=0`` and one assuming carry-in=1, then using a fast 2-to-1 multiplexer to select which result happened to be correct.

.. code-block:: verilog

    module top_module(
        input [31:0] a,
        input [31:0] b,
        output reg [31:0] sum
    );
        wire [15:0] cout,con2;
        wire [15:0]alt_sum1, alt_sum2;
        add16 adder1(a[15:0], b[15:0], 0, sum[15:0], cout);
        add16 adder_sel1(a[31:16], b[31:16], 0, alt_sum1, con2);
        add16 adder_sel2(a[31:16], b[31:16], 1, alt_sum2, con2);
        
        always @(cout, alt_sum1, alt_sum2) begin
            case(cout)
                0 : sum[31:16] = alt_sum1;
                1 : sum[31:16] = alt_sum2;
            endcase
        end

    endmodule


.. warning::
    The carry select adder use more components.