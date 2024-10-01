SiLU Activation function
************************

The YOLO model uses the SiLU activation function in all layers. The SiLU function is defined as:

.. math::
    \text{SiLU}(x) = x \times \sigma(x) \text{, where } \sigma(x)=\frac{1}{1+e^{-x}} \text{ is the logistic sigmoid}

This non-linear function is very difficult to compute in hardware. For our project, we can use an approximation where sigmoid
function is replaced with its piece-wise linear hard analog approximation from `article <https://arxiv.org/pdf/1905.02244>`__ :cite:p:`howard2019searching`.
The SiLU function is then approximated as HardSwish function:

.. math::
    \begin{split}
    \text{Hardswish}(x) = x \cdot \frac{\text{ReLU6}(x+3)}{6} = 
    \begin{cases}
        0                  & \text{if}~ x \le -3, \\
        x                  & \text{if}~ x \ge +3, \\
        x \cdot (x + 3) /6 & \text{otherwise}
    \end{cases}
    \end{split}

This approximation, however, leads to slightly different results within this interval. The difference between the actual
and approximated values needs to be quantified to understand the impact on the overall performance of the neural network.

HardSwish Implementation
========================

The only complex operation in this is the second order polynomial followed by the division by 6. We can simplify this by
we can rescale 6 times a power of 2. This way, we can replace the division by 6 with a right shift operation. The higher 
the power of 2, the more accurate the approximation will be.

The following plot shows the functions SiLU, HardSwish and their absolute error:

.. raw:: html
   :file: ../_static/html/silu_implementation/silu_hardswish_plot.html

.. raw:: html
   :file: ../_static/html/silu_implementation/hardswish_computed_vs_hardswish_abs_error_plot.html

We can also compare the simulation results of the HDL implementation with the original SiLU function:

.. raw:: html
   :file: ../_static/html/silu_implementation/silu_hardswish_abs_error_plot.html