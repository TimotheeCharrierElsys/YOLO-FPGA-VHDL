import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import convolve2d
import random
import time
import plotly.graph_objects as go
import plotly.express as px
import pandas as pd


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


def binary_to_signed(binary_str):
    # Convert binary string to signed integer
    if binary_str[0] == '1':  # If the sign bit is 1, the number is negative
        return -((1 << len(binary_str)) - int(binary_str, 2))
    else:
        return int(binary_str, 2)


def relu6(x):
    return np.minimum(np.maximum(x, 0), 6 * 1024)


def hardswish(x_prime):
    return x_prime * relu6(x_prime + 3 * 1024) / (6 * 1024)


def compute_mean_variance(image_path):
    """
    Computes the mean and variance of each channel in the image.

    Parameters:
    image_path (str): The path to the image file.

    Returns:
    tuple: Two lists containing the mean and variance for each channel.
    """
    # Read the image
    img = plt.imread(image_path)

    # Initialize lists to store mean and variance for each channel
    mean_values = []
    variance_values = []

    # If the image has multiple channels (e.g., RGB)
    if img.ndim == 3:
        for channel in range(img.shape[2]):
            channel_data = img[:, :, channel]
            mean_values.append(np.mean(channel_data))
            variance_values.append(np.var(channel_data))
    else:  # Grayscale image (single channel)
        mean_values.append(np.mean(img))
        variance_values.append(np.var(img))

    return mean_values, variance_values


def batchnorm2d_silu(X, running_mean, running_var, weight, bias, eps=0):

    # Normalize the input
    X_normalized = (X - running_mean) / np.sqrt(running_var + eps)

    # Scale and shift
    X_scaled_shifted = X_normalized * weight + bias

    # Apply Hardswish (Sigmoid Linear Unit) activation function approxiamtion
    Y = hardswish(X_scaled_shifted)

    return Y


def create_fig(filter_name, error, parameters, index):
    # Common font settings
    common_font = {'family': 'Arial, sans-serif', 'color': 'black'}

    # Compute min/max/avg
    error_min = np.min(error)
    error_max = np.max(error)
    error_avg = np.mean(error)  # Renamed for clarity

    # Create figure
    fig = go.Figure()

    # Add surface trace
    fig.add_trace(go.Surface(
        z=error,
        colorbar=dict(
            title="Error Values",
            tickvals=[error_min, error_avg, error_max],
            ticktext=[f"Min: {error_min:.2f}",
                      f"Avg: {error_avg:.2f}",
                      f"Max: {error_max:.2f}"],
            title_font=common_font,
            tickfont=common_font
        ),
        colorscale='Viridis',
        cmin=error_min,
        cmax=error_max
    ))

    # Update plot sizing and layout
    fig.update_layout(
        width=800,
        height=800,
        autosize=False,
        margin=dict(t=150, b=0, l=0, r=0),
        template="plotly_white",
        title=dict(
            text=(
                f"<b>Heatmap Absolute Error for Filter {filter_name}</b><br>"
                "<span style='font-size: 14px;'>"
                f"Batchnorm2d Parameters: Running Mean={parameters['running_mean'][index]: .2f}, "
                f"Running Variance={parameters['running_var'][index]: .2f}, Weight={parameters['weight'][index]}, "
                f"Bias={parameters['bias'][index]}<br>"
                f"Conv2d Parameters: Stride={parameters['stride'][index]}, Padding={parameters['padding'][index]}, "
                f"Kernel Size={parameters['kernel_size'][index]}"
                "</span>"
            ),
            font=common_font,
            x=0.0,
            xanchor='left',
            y=0.95,
            yanchor='top'
        )
    )

    # Update 3D scene options
    fig.update_scenes(
        aspectratio=dict(x=1, y=1, z=0.7),
        aspectmode="manual"
    )

    # Define annotations with common font
    annotations = [
        dict(
            text="Trace type:", showarrow=False,
            x=0.0, y=1.085, yref="paper", align="left", visible=True,
            font=common_font
        )
    ]

    # Add dropdown with callback to toggle annotations visibility
    fig.update_layout(
        updatemenus=[
            dict(
                buttons=[
                    dict(
                        args=[{"type": "surface"}, {
                            "annotations": annotations}],
                        label="3D Surface",
                        method="update"
                    ),
                    dict(
                        args=[{"type": "heatmap"}, {"annotations": []}],
                        label="Heatmap",
                        method="update"
                    )
                ],
                direction="down",
                pad={"r": 10, "t": 10},
                showactive=True,
                x=0.0,
                xanchor="left",
                y=1.1,
                yanchor="top"
            ),
        ]
    )

    # Show and save the figure
    fig.show()
    fig.write_html(f"filter_{filter_name}_heatmap.html")


if __name__ == "__main__":
    img_path = r"SRC/COCOTB/conv2d/wolf.jpg"
    img = plt.imread(img_path)

    running_mean, running_var = compute_mean_variance(img_path)
    weight, bias = [3, 3, 3], [15, 15, 15]
    print(running_mean, running_var)

    conv2d_result_emboss = conv2d(img, filters["filter_emboss"]).conv2d_output
    conv2d_result_identity = conv2d(
        img, filters["filter_identity"]).conv2d_output
    conv2d_result_sharp = conv2d(img, filters["filter_sharp"]).conv2d_output

    print("Computing Batchnorm2d and SiLU")
    batchnorm2d_silu_result_emboss = batchnorm2d_silu(conv2d_result_emboss, running_mean[0],
                                                      running_var[0], weight[0], bias[0])
    batchnorm2d_silu_result_identity = batchnorm2d_silu(conv2d_result_identity, running_mean[1],
                                                        running_var[1], weight[1], bias[1])
    batchnorm2d_silu_result_sharp = batchnorm2d_silu(conv2d_result_sharp, running_mean[2],
                                                     running_var[2], weight[2], bias[2])

    images = reconstruct_image(
        "SRC/BENCH/conv_output_results.txt", 64)

    # Absolute Error
    error_emboss = np.rot90(
        np.rot90(np.abs(batchnorm2d_silu_result_emboss-images[2])))
    error_identity = np.rot90(
        np.rot90(np.abs(batchnorm2d_silu_result_identity-images[1])))
    error_sharp = np.rot90(
        np.rot90(np.abs(batchnorm2d_silu_result_sharp-images[0])))

    print(f"Average Absolute Error with Emboss: {np.mean(error_emboss)}")
    print(f"Average Absolute Error with Identity: {np.mean(error_identity)}")
    print(f"Average Absolute Error with Sharp: {np.mean(error_sharp)}")

    parameters = {
        "running_mean": running_mean,
        "running_var": running_var,
        "weight": weight,
        "bias": bias,
        "stride": [1, 1, 1],
        "padding": [1, 1, 1],
        "kernel_size": [3, 3, 3]
    }

    create_fig("Emboss", error_emboss, parameters, 0)
    create_fig("Identity", error_identity, parameters, 1)
    create_fig("Sharp", error_sharp, parameters, 2)
