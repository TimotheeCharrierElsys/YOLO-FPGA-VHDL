BatchNorm2D Implementation
**************************

As explained previously, the BatchNorm2D layer is the second layer in the Conv block. This layer is mainly here for the model training to
tackle the vanishing gradient problem. For reminder, here the formula of the BatchNorm2D layer:

.. math::
   y = \frac{x - \mathrm{E}[x]}{ \sqrt{\mathrm{Var}[x] + \epsilon}} * \gamma + \beta

This is something we do not want to see in hardware, as it is a very complex operation. To implement it in hardware, we need 
to minimize the input parameters and avoid performing square root and division operations. To do so, we can use the fact that
in inference mode, the mean and variance, and the gamma and beta parameters are fixed. We can then precompute a new parameter 
called :math:`\Theta` where:

.. math::
   \Theta = \frac{2^{N} \times \gamma}{\sqrt{\mathrm{Var}[x] + \epsilon}} \quad N \text{ is an integer number}

The BatchNorm2D layer is then simplified to:

.. math::
   y = \left(\Theta \times (x - \mathrm{E}[x])\right) \gg N + \beta

It is then much easier to implement in hardware.