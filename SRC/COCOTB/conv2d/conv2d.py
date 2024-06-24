import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import convolve2d
import random
import os
import time
import torch
from torch.nn import MaxPool2d

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
    "filter_test": [np.array([[11, 11, 11], [11, 11, 11], [11, 11, 11]]) for _ in range(3)]
}


class conv2d:
    def __init__(self, img, filter, stride=1, padding=1):
        self.img = img
        self.img_padded = np.pad(img, ((
            padding, padding), (padding, padding), (0, 0)), mode='constant', constant_values=0)
        self.filter = filter
        self.stride = stride
        self.padding = padding
        self.conv2d_output = self.convolution2d()

    def convolution2d(self, bias=0):
        tic = time.perf_counter_ns()
        R = self.img_padded[:, :, 0]
        G = self.img_padded[:, :, 1]
        B = self.img_padded[:, :, 2]

        F_R = self.filter[0]
        F_G = self.filter[1]
        F_B = self.filter[2]

        # Convolution
        conv_R = convolve2d(R, F_R, mode='valid')
        conv_G = convolve2d(G, F_G, mode='valid')
        conv_B = convolve2d(B, F_B, mode='valid')

        # Sum all the convolutions
        conv = conv_R + conv_G + conv_B + bias

        toc = time.perf_counter_ns()
        print(f"Executed in {(toc - tic)/1000:0.4f} us")

        return conv

    def maxpool2d(self, input, kernel_size=3, stride=1, padding=0):
        # Add padding to the input array
        if padding > 0:
            padded_input = np.pad(input, ((
                padding, padding), (padding, padding)), mode='constant', constant_values=0)
        else:
            padded_input = input

        # Get the dimensions of the padded input
        (h, w) = padded_input.shape

        # Calculate the dimensions of the output after pooling
        out_h = (h - kernel_size + 2*padding) // stride + 1
        out_w = (w - kernel_size + 2*padding) // stride + 1

        # Initialize the pooled output
        pooled_output = np.zeros((out_h, out_w))

        # Perform max pooling
        for i in range(out_h):
            for j in range(out_w):
                h_start = i * stride
                h_end = h_start + kernel_size
                w_start = j * stride
                w_end = w_start + kernel_size

                pooled_output[i, j] = np.max(
                    padded_input[h_start:h_end, w_start:w_end])

        return pooled_output

    def __str__(self):
        return f"conv2d(img, filter, stride={self.stride}, padding={self.padding})"


def reconstruct_image(file_path, image_width):
    # Initialize a list to hold the image data
    data = []

    # Read the data from the file
    with open(file_path, 'r') as file:
        for line in file:
            # Convert each line to a float and append to the data list
            data.append(binary_to_signed(line.strip()))

    file.close()

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
        image_matrix = np.array(image_data).reshape((image_width, image_width))
        images.append(image_matrix)

    return images


def binary_to_signed(bin_str):
    return int(bin_str, 2)


def plot_images(folder_path, filters):
    # Get the list of files in the folder
    files = os.listdir(folder_path)

    # Determine the number of rows needed for the subplots
    num_rows = len(files)

    # Create a figure with subplots
    fig, axs = plt.subplots(num_rows, 2, figsize=(10, num_rows * 5))

    # Loop through all the files
    for i, file in enumerate(files):
        # Load the image
        img = plt.imread(os.path.join(folder_path, file))

        # Plot the image on the left
        axs[i, 0].imshow(img)
        axs[i, 0].axis('off')

        # Check if the file name is in the filters dictionary (remove the extension .png)
        file = file.split(".")[0]
        if file in filters:
            # Get the filter
            filter = filters[file]

            # Compute the convolution
            conv = conv2d(img, filter)

            # Plot the computed image on the right
            axs[i, 1].imshow(conv.output, cmap='gray')
            axs[i, 1].axis('off')

    # Improve layout
    plt.tight_layout()
    plt.subplots_adjust(wspace=0.02, hspace=0.2)
    plt.show()


def plot_image(img):
    files = os.listdir("output_images")
    for i, file in enumerate(files):
        file = file.split(".")[0]
        if file in filters:
            # Get the filter
            filter = filters[file]

            # Compute the convolution
            conv = conv2d(img, filter)

            # Plot the computed image alone with no border in a square shape
            plt.figure(figsize=(4, 4))
            plt.imshow(conv.output, cmap='gray')
            plt.axis('off')
            plt.savefig(
                f"./output_images/computed_{file}.png", bbox_inches='tight', pad_inches=0, dpi=1000)


if __name__ == "__main__":
    img = plt.imread(
        r"/home/tim/YOLO-FPGA-VHDL/SRC/COCOTB/conv2d/wolf.jpg")

    # Apply ridge filter to the image
    filter_ridge_conv2d_output = conv2d(
        img, filters["filter_ridge"]).conv2d_output

    # Show the result
    plt.figure(figsize=(4, 4))
    plt.imshow(filter_ridge_conv2d_output)
    plt.axis('off')
    plt.tight_layout()
    plt.show()

    # Apply conv2d and maxpool2d
    filter_ridge_maxpool2d_output = conv2d(
        img, filters["filter_ridge"]).maxpool2d_output

    # Show the result
    plt.figure(figsize=(4, 4))
    plt.imshow(filter_ridge_maxpool2d_output)
    plt.axis('off')
    plt.tight_layout()
    plt.show()
