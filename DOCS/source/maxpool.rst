MaxPool2d
=========

**Maxpool2d architecture**
--------------------------

**Overview:**
The maxpool2d architecture is based on maxpool2d_layer and volume_slicer entities.

**Dependencies:**
- `types_pkg.vhd`
- `pipeline.vhd`
- `maxpool2d_layer.vhd`
- `volume_slicer.vhd`

The following image illustrate the architecture of the maxpool2d, by apllying maxpool to the RGB channels of an input image.

.. image:: fig/architecture-maxpool2d.drawio.svg
   :target: fig/architecture-maxpool2d.drawio.svg
   :alt: Diagram

**Output Table**
----------------

This is an example of the output of the maxpool2d where the input image is a 64x64 RGB image. The hyperparameters
used are: *Stride=1*, *Padding=1* and with a *Kernel Size=3*. The output size is a 64x64 gray image.

.. image:: fig/filters/wolf.png

+--------------------+-----------------------------------------------+------------------------------------------+
|     Channel        |             Python Output                     |               HDL Output                 |
+====================+===============================================+==========================================+
| Red                | .. image:: fig/maxpool/maxpoolR.png           | .. image:: fig/maxpool/maxpool_simR.png  |
+--------------------+-----------------------------------------------+------------------------------------------+
| Green              | .. image:: fig/maxpool/maxpoolG.png           | .. image:: fig/maxpool/maxpool_simG.png  |
+--------------------+-----------------------------------------------+------------------------------------------+
| Blue               | .. image:: fig/maxpool/maxpoolB.png           | .. image:: fig/maxpool/maxpool_simB.png  |
+--------------------+-----------------------------------------------+------------------------------------------+