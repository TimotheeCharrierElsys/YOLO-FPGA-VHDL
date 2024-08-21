import numpy as np
import matplotlib.pyplot as plt


class ExportToVHDL:
    """
    A class to export vectors, matrices, and volumes into VHDL format. The class export for predefined types:
        - **t_vec**     = type t_vec is array (natural range <>) of std_logic_vector;
        - **t_mac**     = type t_mat is array (natural range <>) of t_vec;
        - **t_volume**  = type t_volume is array (natural range <>) of t_mat;


    Attributes:
        bitwidth (int): The bit width for the VHDL representation, typically for signed integers.
        scale_factor (int): The factor by which to scale weights before converting to VHDL.
    """

    def format_weight(self, weight, bitwidth, scale_factor, bitwidth_str):
        """
        Converts a floating-point weight into a scaled and clamped integer and formats it as a VHDL std_logic_vector.

        Args:
            weight (float): The weight to be formatted.

        Returns:
            str: A string representing the weight as a VHDL std_logic_vector.
        """
        # Scale the weight by the scale factor
        scaled_weight = int(weight * scale_factor)

        # Determine the range of the signed integer based on the bitwidth
        min_value = -2**(bitwidth - 1)
        max_value = 2**(bitwidth - 1) - 1

        # Clamp the scaled weight to ensure it fits within the range of a signed integer of the given bitwidth
        clamped_weight = max(min_value, min(max_value, scaled_weight))

        # Return the clamped weight formatted as a VHDL std_logic_vector
        return f'std_logic_vector(to_signed({clamped_weight}, {bitwidth_str}))'

    def format_row(self, row, bitwidth, scale_factor, bitwidth_str):
        """
        Formats a list of weights into a VHDL vector (row).

        Args:
            row (list of float): A list of weights representing a row.

        Returns:
            str: A string representing the row as a VHDL vector.
        """
        # Format each weight in the row and join them into a VHDL vector
        return '(' + ', '.join(self.format_weight(w, bitwidth, scale_factor, bitwidth_str) for w in row) + ')'

    def format_matrix(self, matrix, bitwidth, scale_factor, bitwidth_str):
        """
        Formats a 2D list of weights into a VHDL matrix.

        Args:
            matrix (list of list of float): A 2D list where each sub-list represents a row.

        Returns:
            str: A string representing the matrix in VHDL format.
        """
        # Format each row of the matrix and join them into a VHDL matrix format
        formatted_rows = ',\n            '.join(
            self.format_row(row, bitwidth, scale_factor, bitwidth_str) for row in matrix)
        return f'(\n            {formatted_rows}\n        )'

    def format_volume(self, volume, bitwidth, scale_factor, bitwidth_str):
        """
        Formats a 3D list (volume) of weights into VHDL assignment statements for a kernel.

        Args:
            volume (numpy.ndarray): A 4D array where each 3D sub-array represents a set of kernels.

        Returns:
            str: A string representing the volume as VHDL assignment statements.
        """
        # Iterate through each matrix (kernel) in the volume and format it
        formatted_layers = []
        for i in range(volume.shape[0]):
            for j in range(volume.shape[1]):
                formatted_layers.append(f'i_kernel({i})({j}) <= {self.format_matrix(
                    volume[i][j], bitwidth, scale_factor, bitwidth_str)};')

        return '\n'.join(formatted_layers)

    def export_to_vector(self, vector, bitwidth, scale_factor, bitwidth_str, output_path='vector_export.vhd'):
        """
        Exports a vector (row) to a VHDL file.

        Args:
            vector (list of float): A list representing the vector to be exported.
            output_path (str): The file path where the VHDL output will be saved.
        """
        vector = vector.flip(dims=[0])
        with open(output_path, 'w') as f:
            f.write(self.format_row(vector, bitwidth,
                    scale_factor, bitwidth_str) + ';')

    def export_to_matrix(self, matrix, bitwidth, scale_factor, bitwidth_str, output_path='matrix_export.vhd'):
        """
        Exports a 2D matrix to a VHDL file.

        Args:
            matrix (list of list of float): A 2D list representing the matrix to be exported.
            output_path (str): The file path where the VHDL output will be saved.
        """
        with open(output_path, 'w') as f:
            f.write(self.format_matrix(matrix, bitwidth,
                    scale_factor, bitwidth_str) + ';')

    def export_to_volume(self, volume, bitwidth, scale_factor, bitwidth_str, output_path='volume_export.vhd'):
        """
        Exports a 3D volume to a VHDL file as assignment statements.

        Args:
            volume (numpy.ndarray): A 3D array representing the volume to be exported.
            output_path (str): The file path where the VHDL output will be saved.
        """
        with open(output_path, 'w') as f:
            f.write(self.format_volume(volume, bitwidth,
                    scale_factor, bitwidth_str) + ';')

    def to_python(self, file_path, image_width):
        """
        Recreate iamges into an torch array from a text file.

        Args:
            file_path (str): the path of the file
            image_width (int): the image width of each image
        """
        data = []

        # Read the data from the file
        with open(file_path, 'r') as file:
            for line in file:
                # Convert each line to a signed integer and append to the data list
                data.append(int(line.strip()))

        pixels_per_image = image_width * image_width

        # Check if the data length is a multiple of pixels_per_image
        if len(data) % pixels_per_image != 0:
            raise ValueError(
                f"Data length {len(data)} is not a multiple of single image size {pixels_per_image}.")

        # Calculate the number of images
        num_images = len(data) // pixels_per_image

        # Split and reshape the data for each image
        images = []
        for i in range(num_images):
            start_index = i * pixels_per_image
            end_index = start_index + pixels_per_image
            image_data = data[start_index:end_index]
            image_matrix = np.array(image_data).reshape(
                (image_width, image_width))
            image_matrix = np.rot90(np.rot90(image_matrix))
            images.append(image_matrix)

        images = np.array(images)

        # Shape will be (num_images, 1, image_width, image_width)
        images = images[:, np.newaxis, :, :]
        images = np.transpose(images, (1, 0, 2, 3))

        return images

    def imshow_vhdl_output(self, images):

        images = np.array(images)
        images = images[0]

        # Number of images
        num_images = images.shape[0]

        # Calculate the grid size
        grid_size = int(np.ceil(np.sqrt(num_images)))

        # Create the plot
        fig, axes = plt.subplots(grid_size, grid_size, figsize=(15, 15))

        # Flatten the axes array for easy iteration
        axes = axes.flatten()

        for i, ax in enumerate(axes):
            if i < num_images:
                ax.imshow(images[i], cmap='plasma')
                ax.axis('off')
            else:
                # Hide any extra subplots
                ax.axis('off')

        plt.tight_layout()
        plt.show()


class Compare():
    def __init__(self, expected, gotten):
        self.expected = expected
        self.gotten = gotten
        self.error = np.abs(gotten - expected)

    def create_fig(self):

        # Compute min/max/avg
        error_min = np.min(self.error)
        error_max = np.max(self.error)
        error_avg = np.mean(self.error)

        # Create subplots
        fig, axs = plt.subplots(2, 2, figsize=(12, 10))

        # Plot the error as an image
        axs[0, 0].imshow(self.error, cmap='viridis')
        axs[0, 0].set_title('Error Map')
        axs[0, 0].axis('off')

        # Display min, max, and average error values
        axs[0, 1].text(0.5, 0.7, f'Min Error: {
                       error_min:.3f}', fontsize=14, ha='center')
        axs[0, 1].text(0.5, 0.5, f'Max Error: {
                       error_max:.3f}', fontsize=14, ha='center')
        axs[0, 1].text(0.5, 0.3, f'Avg Error: {
                       error_avg:.3f}', fontsize=14, ha='center')
        axs[0, 1].axis('off')

        # Plot the expected values
        axs[1, 0].imshow(self.expected, cmap='coolwarm')
        axs[1, 0].set_title('Expected Values')
        axs[1, 0].axis('off')

        # Plot the gotten values
        axs[1, 1].imshow(self.gotten, cmap='coolwarm')
        axs[1, 1].set_title('Gotten Values')
        axs[1, 1].axis('off')

        plt.tight_layout()
        plt.show()
