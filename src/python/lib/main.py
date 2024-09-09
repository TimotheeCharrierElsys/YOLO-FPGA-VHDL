import numpy as np
import torch
import torch.nn.functional as F
from model import *
from python_vhdl import *


def relu6(x, scale_factor):
    return np.minimum(np.maximum(x, 0), 6 * 2**scale_factor)


def hardswish(x_prime, scale_factor):
    return (
        x_prime
        * relu6(x_prime + 3 * 2**scale_factor, scale_factor)
        / (6 * 2**scale_factor)
    )


class ExtractedNetConv:
    def __init__(self, model, scaling_factor=4096):
        self.model = model
        self.scaling_factor = scaling_factor

        self.conv1 = model.conv1
        self.bn1 = model.bn1
        self.conv2 = model.conv2
        self.bn2 = model.bn2

        self.dropout1 = model.dropout1
        self.dropout2 = model.dropout2

        self.fc1 = model.fc1
        self.fc2 = model.fc2

    def forward_first_layer(self, x):
        x = self.conv1(x)
        print(x * 4096)
        x = self.bn1(x)
        output = F.silu(x) * self.scaling_factor

        return output

    def forward_first_layer_approximate(self, x):
        x = self.conv1(x)
        x = self.bn1(x) * self.scaling_factor
        output = hardswish(x, np.log2(self.scaling_factor))

        return output

    def forward_second_layer(self, x):
        x = self.conv1(x)
        x = self.bn1(x)
        x = F.silu(x)
        x = self.conv2(x)
        x = self.bn2(x)
        output = F.silu(x) * self.scaling_factor

        return output

    def forward_second_layer_approximate(self, x):
        x = self.conv1(x)
        x = self.bn1(x) * self.scaling_factor
        x = hardswish(x, np.log2(self.scaling_factor)) / self.scaling_factor
        x = self.conv2(x)
        x = self.bn2(x) * self.scaling_factor
        output = hardswish(x, np.log2(self.scaling_factor))

        return output

    def estimate(self, x):
        x = self.forward_second_layer(x)

        x = F.max_pool2d(x, 2)
        x = self.dropout1(x)
        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.silu(x)
        x = self.dropout2(x)
        x = self.fc2(x)
        output = F.log_softmax(x, dim=1)

        return output, self.calculate_confidence(output)

    def estimate_approximate(self, x):
        x = self.forward_second_layer_approximate(x)

        x = F.max_pool2d(x, 2)
        x = self.dropout1(x)
        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.silu(x)
        x = self.dropout2(x)
        x = self.fc2(x)
        output = F.log_softmax(x, dim=1)

        return output, self.calculate_confidence(output)

    def estimate_last_layers(self, x):
        x = F.max_pool2d(x, 2)
        x = self.dropout1(x)
        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.silu(x)
        x = self.dropout2(x)
        x = self.fc2(x)
        output = F.log_softmax(x, dim=1)

        return output, self.calculate_confidence(output)

    def calculate_confidence(self, log_probs):
        # Convert log probabilities to probabilities
        probs = torch.exp(log_probs)
        confidence = probs.max().item()  # Get the maximum probability (confidence)
        return confidence


def main_export_model_to_vhdl(model, data, scaling_factor):
    export = ExportToVHDL()
    export.export_to_matrix(
        data[0].rot90().rot90(), 16, scaling_factor, "BITWIDTH", "input_data.vhd"
    )
    export.export_to_volume(
        model.conv1.weight, 32, scaling_factor, "BITWIDTH", "conv2d1_weights.vhd"
    )
    export.export_to_vector(
        model.conv1.bias, 32, scaling_factor, "2 * BITWIDTH", "conv2d1_bias.vhd"
    )
    export.export_to_vector(
        process_batchnorm2d(model.bn1),
        32,
        scaling_factor,
        "2 * BITWIDTH",
        "bn1_weight.vhd",
    )
    export.export_to_vector(
        model.bn1.bias, 32, scaling_factor, "2 * BITWIDTH", "bn1_bias.vhd"
    )
    export.export_to_vector(
        model.bn1.running_mean,
        32,
        scaling_factor,
        "2 * BITWIDTH",
        "bn1_running_mean.vhd",
    )

    export.export_to_volume(
        model.conv2.weight, 32, scaling_factor, "BITWIDTH", "conv2d2_weights.vhd"
    )
    export.export_to_vector(
        model.conv2.bias, 32, scaling_factor, "2 * BITWIDTH", "conv2d2_bias.vhd"
    )
    export.export_to_vector(
        process_batchnorm2d(model.bn2),
        32,
        scaling_factor,
        "2 * BITWIDTH",
        "bn2_weight.vhd",
    )
    export.export_to_vector(
        model.bn2.bias, 32, scaling_factor, "2 * BITWIDTH", "bn2_bias.vhd"
    )
    export.export_to_vector(
        model.bn2.running_mean,
        32,
        scaling_factor,
        "2 * BITWIDTH",
        "bn1_running_mean.vhd",
    )


def compare_conv(model, data, target, scaling_factor):
    # Prepare data and model
    data = data.unsqueeze(0)
    extracted_model = ExtractedNetConv(model, scaling_factor)

    with torch.no_grad():
        # First layer comparison
        images_first_layer = extract_and_compare_layers(
            data,
            extracted_model.forward_first_layer,
            extracted_model.forward_first_layer_approximate,
            layer_num=14,
            file_path=r"src/bench/conv_output_results_first_layer.txt",
            scaling_factor=scaling_factor,
        )

        # Second layer comparison
        images_second_layer = extract_and_compare_layers(
            data,
            extracted_model.forward_second_layer,
            extracted_model.forward_second_layer_approximate,
            layer_num=12,
            file_path=r"src/bench/conv_output_results_second_layer.txt",
            scaling_factor=scaling_factor,
        )

        pred, conf, is_correct = classify_and_visualize(
            extracted_model.estimate, data, target, title_suffix="(Original Model)"
        )
        pred_approx, conf_approx, is_correct_approx = classify_and_visualize(
            extracted_model.estimate_approximate,
            data,
            target,
            title_suffix="(Approximate Model)",
        )

        # Classification with reconstructed second layer output
        reconstructed_data = torch.from_numpy(images_second_layer).float()
        pred_reconstructed, conf_reconstructed, is_correct_reconstructed = (
            classify_and_visualize(
                extracted_model.estimate_last_layers,
                reconstructed_data,
                target,
                title_suffix="(Reconstructed Output)",
            )
        )


if __name__ == "__main__":
    scaling_factor = 4096

    model, data, target = load_dataset("./src/python/lib/mnist_cnn.pt")
    # main_export_model_to_vhdl(model, data, scaling_factor)
    compare_conv(model, data, target, scaling_factor)
