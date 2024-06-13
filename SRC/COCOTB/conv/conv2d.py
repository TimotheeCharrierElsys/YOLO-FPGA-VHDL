import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import convolve2d
import random

filters = {
    "filter_identity": [np.array([[0, 0, 0], [0, 1, 0], [0, 0, 0]]) for _ in range(3)],
    "filter_ridge": [np.array([[0, -1, 0], [-1, 4, -1], [0, -1, 0]]) for _ in range(3)],
    "filter_edge": [np.array([[-1, -1, -1], [-1, 8, -1], [-1, -1, -1]]) for _ in range(3)],
    "filter_sharp": [np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]]) for _ in range(3)],
    "filter_blur": [np.array([[1, 1, 1], [1, 1, 1], [1, 1, 1]]) / 9 for _ in range(3)],
    "filter_gaussian_33": [np.array([[1, 2, 1], [2, 4, 2], [1, 2, 1]]) / 16 for _ in range(3)],
    "filter_gaussian_55": [np.array([[1, 4, 6, 4, 1], [4, 16, 24, 16, 4], [6, 24, 36, 24, 6], [4, 16, 24, 16, 4], [1, 4, 6, 4, 1]]) / 256 for _ in range(3)],
    "filter_unsharp_55": [np.array([[1, 4, 6, 4, 1], [4, 16, 24, 16, 4], [6, 24, -476, 24, 6], [4, 16, 24, 16, 4], [1, 4, 6, 4, 1]]) / 256 for _ in range(3)],
    "filter_emboss": [np.array([[-2, -1, 0], [-1, 1, 1], [0, 1, 2]]) for _ in range(3)],
    "filter_sobel_x": [np.array([[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]]) for _ in range(3)],
    "filter_sobel_y": [np.array([[-1, -2, -1], [0, 0, 0], [1, 2, 1]]) for _ in range(3)],
    "filter_prewitt_x": [np.array([[-1, 0, 1], [-1, 0, 1], [-1, 0, 1]]) for _ in range(3)],
    "filter_prewitt_y": [np.array([[-1, -1, -1], [0, 0, 0], [1, 1, 1]]) for _ in range(3)],
    "filter_laplacian": [np.array([[0, 1, 0], [1, -4, 1], [0, 1, 0]]) for _ in range(3)],
    "filter_laplacian_diag": [np.array([[1, 1, 1], [1, -8, 1], [1, 1, 1]]) for _ in range(3)],
    "filter_laplacian_gaussian": [np.array([[0, 0, -1, 0, 0], [0, -1, -2, -1, 0], [-1, -2, 16, -2, -1], [0, -1, -2, -1, 0], [0, 0, -1, 0, 0]]) for _ in range(3)],
    "filter_randoml_33": [np.array([[random.randint(-1, 1) for _ in range(3)] for _ in range(3)]) for _ in range(3)],
    "filter_randoml_55": [np.array([[random.randint(-1, 1) for _ in range(5)] for _ in range(5)]) for _ in range(3)],
    "filter_test": [np.array([[-30, -21, 7], [-19, 10, -1], [-4, -2, 8]]) for _ in range(3)]
}


class Conv2D:
    def __init__(self, input_volume, filters, biases, stride=1, padding=0):
        self.input_volume = input_volume
        self.filters = filters
        self.biases = biases
        self.stride = stride
        self.padding = padding
        self.output_volume = self.compute_conv2d()

    def compute_conv2d(self):
        # Assuming square filters and equal height and width
        filter_height, filter_width = self.filters[0].shape
        input_height, input_width, input_depth = self.input_volume.shape

        # Calculate the output dimensions
        output_height = ((input_height - filter_height + 2 *
                         self.padding) // self.stride) + 1
        output_width = ((input_width - filter_width + 2 *
                        self.padding) // self.stride) + 1
        num_filters = len(self.filters)

        # Initialize the output volume
        output_volume = np.zeros((output_height, output_width, num_filters))

        # Pad the input volume
        if self.padding > 0:
            input_volume_padded = np.pad(self.input_volume,
                                         ((self.padding, self.padding),
                                          (self.padding, self.padding),
                                          (0, 0)),
                                         mode='constant')
        else:
            input_volume_padded = self.input_volume

        # Perform convolution
        for filter_index, filter in enumerate(self.filters):
            for channel_index in range(input_depth):
                output_volume[:, :, filter_index] += convolve2d(input_volume_padded[:, :, channel_index],
                                                                filter,
                                                                mode='valid')[::self.stride, ::self.stride]
            # Add the bias
            output_volume[:, :, filter_index] += self.biases[filter_index]

        return output_volume

    def __str__(self):
        return (f'Conv2D(input_volume={self.input_volume.shape}, filters={self.filters[0].shape}, '
                f'biases={self.biases}, stride={
                    self.stride}, padding={self.padding}, '
                f'output_volume={self.output_volume.shape})')


class Image:
    def __init__(self, image_path):
        self.image_path = image_path
        self.image = plt.imread(image_path)
        self.R, self.G, self.B = self.image[:, :,
                                            0], self.image[:, :, 1], self.image[:, :, 2]
        self.conv2d_instance = None
        self.reconstructed_image = None

    def plot_image_and_channels(self):
        fig, axs = plt.subplots(1, 4, figsize=(20, 5))

        # Original image
        axs[0].imshow(self.image)
        axs[0].set_title('Original Image')

        # Channels
        channels = [self.R, self.G, self.B]
        titles = ['Red Channel', 'Green Channel', 'Blue Channel']
        cmaps = ['Reds_r', 'Greens_r', 'Blues_r']
        for i in range(3):
            axs[i + 1].imshow(channels[i], cmap=cmaps[i])
            axs[i + 1].set_title(titles[i])

        # Remove x and y ticks
        for ax in axs:
            ax.set_xticks([])
            ax.set_yticks([])

        plt.show()

    def conv2d(self, filters, biases, stride=1, padding=0):
        # Stack the channels to form the input volume
        input_volume = np.stack([self.R, self.G, self.B], axis=2)
        conv2d_instance = Conv2D(
            input_volume, filters, biases, stride, padding)
        self.conv2d_instance = conv2d_instance
        return conv2d_instance.output_volume

    def conv2d_and_plot(self, filters, biases, stride=1, padding=0):
        # Perform 2D convolution
        new_image = self.conv2d(filters, biases, stride, padding)

        # Plot the original image, the convolved image
        fig, axs = plt.subplots(1, 2, figsize=(15, 5))

        # Original image
        axs[0].imshow(self.image)
        axs[0].set_title('Original Image')

        # Convolved image (use only the first filter's result for simplicity)
        axs[1].imshow(new_image[:, :, 0], cmap='gray')
        axs[1].set_title('Convolved Image (Filter 1)')

        # Remove x and y ticks
        for ax in axs:
            ax.set_xticks([])
            ax.set_yticks([])

        plt.show()

    def loop_through_filters(self, filters, biases, stride=1, padding=0):
        # Number of filters
        num_filters = len(filters)

        # Determine the grid size
        grid_size = int(np.ceil(np.sqrt(num_filters + 1)))

        # Create a figure with subplots
        fig, axs = plt.subplots(grid_size, grid_size, figsize=(15, 10))

        # Flatten the axes array for easy iteration
        axs = axs.flatten()

        # Plot the original image
        axs[0].imshow(self.image)
        axs[0].set_title('Original Image')
        axs[0].axis('off')

        # Iterate over each filter and apply convolution
        for i, (filter_name, filter) in enumerate(filters.items()):
            # Perform 2D convolution
            new_image = self.conv2d(filter, biases, stride, padding)

            # Plot the convolved image
            axs[i + 1].imshow(new_image[:, :, 0], cmap='gray')
            axs[i + 1].set_title(f'Filter: {filter_name}')
            axs[i + 1].axis('off')

        # Hide any remaining empty subplots
        for j in range(num_filters + 1, grid_size * grid_size):
            axs[j].axis('off')

        # Adjust layout for better spacing
        plt.tight_layout()
        plt.show()

    def i_data_to_vhdl_vector(self, output_path="i_data.txt"):
        """
        Convert the image pixels to a VHDL vector format.

        Returns:
            str: VHDL formatted string representing the image pixels.
        """
        rows, cols, _ = self.image.shape
        print(rows, cols)

        def pixel_to_vhdl(value):
            return f"std_logic_vector(to_signed({value}, BITWIDTH))"

        # Prepare VHDL data for each channel
        vhdl_data = {'R': [], 'G': [], 'B': []}

        for channel, channel_name in enumerate(['R', 'G', 'B']):
            channel_data = []
            for row in range(rows):
                row_data = [pixel_to_vhdl(self.image[row, col, channel])
                            for col in range(cols)]
                channel_data.append(f"({', '.join(row_data)})")
            vhdl_data[channel_name] = channel_data

        # Generate VHDL formatted string
        vhdl_string = ""
        for i, channel_name in enumerate(['R', 'G', 'B']):
            vhdl_string += f"i_data({i}) <= (\n"
            vhdl_string += ",\n".join(vhdl_data[channel_name])
            vhdl_string += "\n);\n"

        # Save the output to a file
        with open(output_path, 'w') as file:
            file.write(vhdl_string)

        print(f"VHDL i_data saved to {output_path}")

    def __str__(self):
        return f'Image(image_path={self.image_path})'

    def charac(self):
        return f'Image(image_path={self.image_path}, shape={self.image.shape}, output_volume={self.conv2d_instance.output_volume.shape})'


def reconstruct_image(file_path):
    # Initialize a list to hold the image data
    data = []

    # Read the data from the file
    with open(file_path, 'r') as file:
        for line in file:
            # Convert each line to a float and append to the data list
            data.append(float(line.strip()))  # TOFIX: raw data is


def reconstruct_image(file_path, image_width):
    # Initialize a list to hold the image data
    data = []

    # Read the data from the file
    with open(file_path, 'r') as file:
        for line in file:
            # Convert each line to a float and append to the data list
            data.append(binary_to_signed_32bit(line.strip()))

    file.close()

    pixels_per_image = image_width * image_width

    # Check if the data length is a multiple of pixels_per_image
    if len(data) % pixels_per_image != 0:
        raise ValueError("Data length is not a multiple of single image size.")

    # Calculate the number of images
    num_images = len(data) // pixels_per_image

    # Split and reshape the data for each image
    images = []
    for i in range(num_images):
        start_index = i * pixels_per_image
        end_index = start_index + pixels_per_image
        image_data = data[start_index:end_index]
        image_matrix = np.array(image_data).reshape((image_width, image_width))
        images.append(image_matrix)

    return images


def binary_to_signed_32bit(bin_str):
    # Check if the binary string is 32 bits
    if len(bin_str) != 32:
        raise ValueError("The binary string must be exactly 32 bits long.")

    # Check if the number is negative
    if bin_str[0] == '1':
        # Compute the two's complement
        inverted_bin_str = ''.join('1' if b == '0' else '0' for b in bin_str)
        neg_value = int(inverted_bin_str, 2) + 1
        return -neg_value
    else:
        # The number is positive
        return int(bin_str, 2)


def i_kernels_to_vector(filter_name, filters, output_path="o_kernel.txt", bitwidth=16):
    """
    Convert the filter kernels to a VHDL vector format.

    Args:
        filter_name (str): Name of the filter set.
        filters (dict): Dictionary containing the filter kernels.
        output_path (str): Output file path for saving VHDL vector data.
        bitwidth (int): Bitwidth for VHDL representation (default: 16).
    """
    # Get the filters for the specified filter_name
    filter_set = filters[filter_name]

    # Determine the dimensions of the filters
    filter_height, filter_width = filter_set[0].shape

    def pixel_to_vhdl(value, bitwidth):
        return f"std_logic_vector(to_signed({value}, {bitwidth}))"

    # Prepare VHDL data for each filter
    vhdl_data = []

    for filter_index, kernel in enumerate(filter_set):
        kernel_data = []
        for row in range(filter_height):
            row_data = [pixel_to_vhdl(kernel[row, col], bitwidth)
                        for col in range(filter_width)]
            kernel_data.append(f"({', '.join(row_data)})")
        vhdl_data.append(f"i_kernel({filter_index}) <= (\n")
        vhdl_data.append(",\n".join(kernel_data))
        vhdl_data.append("\n);\n")

    # Generate VHDL formatted string
    vhdl_string = "".join(vhdl_data)

    # Save the output to a file
    with open(output_path, 'w') as file:
        file.write(vhdl_string)

    print(f"VHDL i_kernel saved to {output_path}")


if __name__ == '__main__':
    image_path = r"C:\Users\UF523TCH\Documents\GIT\YOLO-FPGA-VHDL\SRC\COCOTB\conv\wolf.jpg"

    # Choose filters
    filter_name1 = "filter_laplacian"
    filter1 = filters[filter_name1]
    filter_name2 = "filter_test"
    filter2 = filters[filter_name2]

    # Choose biases (one for each filter)
    biases = [-1 for _ in range(len(filter1))]

    # Create an image object
    img = Image(image_path)

    # Perform convolution with the filters
    output1 = img.conv2d(filter1, biases, padding=1, stride=1)
    output2 = img.conv2d(filter2, biases, padding=1, stride=1)
    output2 = output2 / 100

    # Loop through all the filters and plot the results
    # img.loop_through_filters(filters, biases, padding=0)
    print(img.charac())

    # img.i_data_to_vhdl_vector()
    # i_kernels_to_vector("filter_test", filters)

    # Reconstruct images from file
    images = reconstruct_image(
        r"C:\Users\UF523TCH\Documents\GIT\Modelsim\conv_output_results.txt", 64)
    images[1] = images[1] / 100

    # Plot each image on the same graph with expected outputs
    num_images = len(images)
    fig, axes = plt.subplots(2, num_images, figsize=(15, 10))

    for i in range(num_images):
        # Plot reconstructed images
        axes[0, i].imshow(images[i], cmap='gray')
        axes[0, i].axis('off')
        axes[0, i].set_title(f'Reconstructed Image {i + 1}')

        # Plot the expected value from output1 and output2
        # Adjust indexing as per your expected output structure
        axes[1, 0].imshow(output1[:, :, i], cmap='gray')
        axes[1, 0].axis('off')
        axes[1, 0].set_title(f'Expected Output for {filter_name1}')

        # Adjust indexing as per your expected output structure
        axes[1, 1].imshow(output2[:, :, i], cmap='gray')
        axes[1, 1].axis('off')
        axes[1, 1].set_title(f'Expected Output for {filter_name2}')

    plt.tight_layout()
    plt.show()
