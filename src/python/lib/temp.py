import torch
import torch.nn as nn
from ultralytics import YOLO

# Load the YOLOv8 model (replace 'yolov8n.pt' with other model variants if needed)
model = YOLO("yolov8n.pt")
yolo_model = model.model


# Function to calculate the output size of a convolutional layer
def conv_output_size(input_size, kernel_size, stride, padding):
    return (input_size + 2 * padding - kernel_size) // stride + 1


# Define the initial input size of the image (e.g., 640x640 for YOLOv8)
input_height = 640
input_width = 640

total_computation_time = 0
count = 0

# Iterate through each layer in the model and process Conv2d layers
for layer in yolo_model.modules():
    if isinstance(layer, nn.Conv2d):
        # Get layer parameters
        kernel_size = layer.kernel_size[0]  # Kernel size (assuming square kernel)
        stride = layer.stride[0]  # Stride (assuming square stride)
        padding = layer.padding[0]  # Padding (assuming symmetric padding)

        # Calculate the output size of this convolution layer
        output_height = conv_output_size(input_height, kernel_size, stride, padding)
        output_width = conv_output_size(input_width, kernel_size, stride, padding)

        # Number of windows processed by this Conv layer
        num_windows = output_height * output_width

        # Computation time for each window
        computation_time_per_window = kernel_size * kernel_size

        # Total computation time for this Conv layer
        computation_time_for_layer = num_windows * computation_time_per_window + 2 * num_windows

        # Accumulate the total computation time
        total_computation_time += computation_time_for_layer

        # Update input size for the next layer (output of this layer is input to the next)
        input_height = output_height
        input_width = output_width
        count += 1

        if count == 1:
            print(output_height, output_width)


# Clock frequency in Hz (100 MHz)
clock_frequency_hz = 100e6  # 100 million Hz

# Compute the time required
time_required_seconds = total_computation_time / clock_frequency_hz

print(f"Time required to process all Conv layers: {time_required_seconds:.6f} seconds")
