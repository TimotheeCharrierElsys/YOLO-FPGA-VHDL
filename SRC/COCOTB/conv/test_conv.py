import numpy as np
from PIL import Image
import matplotlib.pyplot as plt


class conv_test:
    def __init__(self, image_path,
                 bitwidth=8,
                 vhdl_vector_file=r"./vhdl_vector_file.txt",
                 vhdl_output_result_file=r"conv_output_results.txt"):
        """
        Initialize the conv_test class with the given parameters.

        Args:
            image_path (str): Path to the input image file.
            bitwidth (int): Bitwidth for VHDL vector representation.
            vhdl_vector_file (str): Path to the VHDL vector file.
            vhdl_output_result_file (str): Path to the VHDL output result file.
        """
        self.image_path = image_path
        self.bitwidth = bitwidth
        self.vhdl_vector_file = vhdl_vector_file
        self.vhdl_output_result_file = vhdl_output_result_file

        # Initialize R, G, B channels
        self.R, self.G, self.B = self.get_RGB_channels()

    def get_RGB_channels(self):
        """
        Load the image from the given path and extract the R, G, B channels.

        Returns:
            tuple: Three numpy arrays representing the R, G, and B channels.
        """
        # Load image and convert to numpy array
        image = Image.open(self.image_path)
        image_np = np.array(image)

        # Extract the R, G, B channels
        return image_np[:, :, 0], image_np[:, :, 1], image_np[:, :, 2]


# Usage example
if __name__ == "__main__":
    # Create an instance of the conv_test class
    conv = conv_test(r"./espresso.jpeg")

    # Access the R, G, B channels
    R_channel = conv.R
    G_channel = conv.G
    B_channel = conv.B

    # Display the channels using matplotlib
    plt.figure(figsize=(15, 5))

    plt.subplot(1, 3, 1)
    plt.imshow(R_channel, cmap='Reds')
    plt.title('Red Channel')

    plt.subplot(1, 3, 2)
    plt.imshow(G_channel, cmap='Greens')
    plt.title('Green Channel')

    plt.subplot(1, 3, 3)
    plt.imshow(B_channel, cmap='Blues')
    plt.title('Blue Channel')

    plt.show()
