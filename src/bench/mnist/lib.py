import plotly.graph_objects as go
import torch
from torchvision import transforms
from random import randint
import numpy as np
import warnings

warnings.filterwarnings(
    "ignore", category=ResourceWarning
)  # ignore plotly resource warning
warnings.filterwarnings(
    "ignore",
    category=DeprecationWarning,
    message="__array__ implementation doesn't accept a copy keyword",
)  # Plotly is using deprecated numpy functions


def calculate_output_dimensions(generics):
    """
    Calculate the output height and width based on the input dimensions and parameters.
    """
    # first layer
    return 12, 12


def convert_output_to_int(output):
    """
    Convert the output tensor to integers based on the bitwidth.
    """
    for i in range(len(output[0])):
        for j in range(len(output[0][0])):
            for k in range(len(output)):
                output[k][i][j] = output[k][i][j].signed_integer

    return output


def preprocess_layer(
    generics: dict,
    conv2d_layer: torch.nn.Conv2d,
    bn_layer: torch.nn.BatchNorm2d,
):
    """
    Preprocesses convolutional and batch normalization layers.
    Scales weights, biases, and batch norm parameters for integer conversion.

    Parameters:
    ----------
        generics (dict): Dictionary containing configuration parameters.
        conv2d_layer (torch.nn.Conv2d): The Conv2D layer to preprocess.
        bn_layer (torch.nn.BatchNorm2d): The BatchNorm layer to preprocess.

    Returns:
    -------
        Tuple[List[int]]: Preprocessed convolution weights, biases, batch norm mean, weight, and bias.
    """
    scale_factor = 2 ** generics["DATA_SCALE_FACTOR"]

    def scale_and_convert(tensor, scale_factor):
        return (tensor * scale_factor).int().tolist()

    # Convolutional layer weights and bias scaling
    i_kernel_conv2d = scale_and_convert(conv2d_layer.weight, scale_factor)
    i_bias_conv2d = scale_and_convert(conv2d_layer.bias, scale_factor)

    epsilon = 1e-5  # A small constant to prevent division by zero
    scaled_var = (bn_layer.running_var + epsilon).sqrt()
    new_bn_weight = scale_and_convert(
        bn_layer.weight / scaled_var, scale_factor
    )

    # BatchNorm mean and bias scaling
    bn_running_mean = scale_and_convert(bn_layer.running_mean, scale_factor)
    bn_bias = scale_and_convert(bn_layer.bias, scale_factor)

    return (
        i_kernel_conv2d,
        i_bias_conv2d,
        bn_running_mean,
        new_bn_weight,
        bn_bias,
    )


def calculate_error(output, gotten_output):
    """
    Calculate the error between the output and the gotten output channel-wise.
    It means for each channel, the average, maximum, and minimum error is calculated.
    Inputs shape is (batch_size, num_channels, height, width).

    Parameters:
    ----------
        output (torch.Tensor): The output tensor.
        gotten_output (torch.Tensor): The gotten output tensor.

    Returns:
    -------
        Tuple[torch.Tensor]: Average, maximum, and minimum error per channel
    """

    abs_diff = torch.abs(output - gotten_output)

    # Compute across (height, width)
    avg_diff_per_channel = abs_diff.mean(dim=(2, 3))
    max_diff_per_channel = abs_diff.max(dim=3).values.max(dim=2).values
    min_diff_per_channel = abs_diff.min(dim=3).values.min(dim=2).values

    return (
        abs_diff,
        avg_diff_per_channel,
        max_diff_per_channel,
        min_diff_per_channel,
    )


def postprocess_output(input, output_hs, output_silu, gotten_output):
    """
    Postprocess the output tensors for visualization.
    All types handles are converted to float except for the input tensor.
    Because the VHDL does not return the same type, we need to add a batch dimension to the gotten output.

    Parameters:
    ----------
        input (torch.Tensor, int32): The input tensor.
        output_hs (torch.Tensor, float32): The output tensor with Hardswish activation.
        output_silu (torch.Tensor, float32): The output tensor with SiLU activation.
        gotten_output (torch.Tensor, float32): The output tensor from the DUT

    Returns:
    -------
        Tuple[torch.Tensor]: Preprocessed tensors for visualization.
    """
    # First case, the input is the output of the previous layer
    if isinstance(input, list):
        input = torch.tensor(
            np.array(convert_output_to_int(input)),
            dtype=torch.int32,
        )

    # Second case, it is the first layer so the input is an image
    elif isinstance(input, torch.Tensor) and input.shape == torch.Size(
        [1, 28, 28]
    ):
        # Apply inverse transformation to the input to get the RGB values
        inverse_transform = transforms.Compose(
            [
                transforms.Normalize(mean=[-0.1307 / 0.3081], std=[1 / 0.3081]),
            ]
        )

        input = inverse_transform(input)
        input = (input * 255).int()

    # Convert the output tensors to float32
    gotten_output = torch.tensor(
        np.array(convert_output_to_int(gotten_output)),
        dtype=torch.float32,
    )

    # Add a batch dimension to the gotten output
    gotten_output = gotten_output.unsqueeze(0)

    return input, output_hs, output_silu, gotten_output


def generate_report_first_layer(
    input,
    output_hs,
    output_silu,
    gotten_output,
    scale_factor,
    name="First Layer",
):
    """
    Generate a report for the first layer inference.
    A random channel and batch are selected for visualization.

    Parameters:
    ----------
        input (torch.Tensor): The input tensor.
        output_silu (torch.Tensor): The output tensor with SiLU activation.
        output_hs (torch.Tensor): The output tensor with Hardswish activation.
        gotten_output (torch.Tensor): The output tensor from the DUT

    Returns:
    -------
        None
    """

    # Postprocess the output tensors
    (
        input,
        output_hs,
        output_silu,
        gotten_output,
    ) = postprocess_output(
        input,
        output_hs * scale_factor,
        output_silu * scale_factor,
        gotten_output,
    )

    # Calculate the error
    abs_diff_hs, abs_diff_hs_avg, abs_diff_hs_max, abs_diff_hs_min = (
        calculate_error(output_hs, gotten_output)
    )

    abs_diff_silu, abs_diff_silu_avg, abs_diff_silu_max, abs_diff_silu_min = (
        calculate_error(output_silu, gotten_output)
    )

    # Calculte Global Average Error
    g_abs_diff_hs_avg = abs_diff_hs_avg.mean() / scale_factor * 100
    g_abs_diff_avg_silu = abs_diff_silu_avg.mean() / scale_factor * 100

    # Setup the data
    batch_size, num_channels, height, width = output_hs.shape

    channel = randint(0, num_channels - 1)
    batch = randint(0, batch_size - 1)

    # Create Generic Parameters for the report
    font = dict(family="Arial, sans-serif", size=12, color="black")
    main_title = dict(
        text=(
            f"<b>Convolutional Layer Report For {name} Inference</b><br>"
            f"<span style='font-size: 14px;'>"
            f"Input Shape: {input.shape}, Output Shape: {output_hs.shape}<br>"
            f"Global Average Error (HS): {g_abs_diff_hs_avg:.2f}%, Global Average Error (SiLU): {g_abs_diff_avg_silu:.2f}%"
        ),
        x=0.0,
        y=0.95,
        font={"family": "Arial, sans-serif", "color": "black"},
        xanchor="left",
        yanchor="top",
    )

    # Heatmap traces
    data_hs = go.Heatmap(
        z=output_hs[batch][channel],
        colorscale="Viridis",
        visible=False,
        coloraxis="coloraxis",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_silu = go.Heatmap(
        z=output_silu[batch][channel],
        colorscale="Viridis",
        visible=False,
        coloraxis="coloraxis",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_gotten = go.Heatmap(
        z=gotten_output[batch][channel],
        colorscale="Viridis",
        visible=False,
        coloraxis="coloraxis",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_abs_diff_hs = go.Heatmap(
        z=abs_diff_hs[batch][channel],
        colorscale="Thermal",
        visible=False,
        coloraxis="coloraxis2",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_abs_diff_silu = go.Heatmap(
        z=abs_diff_silu[batch][channel],
        colorscale="Thermal",
        visible=False,
        coloraxis="coloraxis4",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_input = go.Heatmap(
        z=input[0],
        colorscale="gray",
        visible=True,
        coloraxis="coloraxis3",
        hovertemplate="(%{x}, %{y})<br>Value: %{z}",
        name="",
    )

    # Combine the data
    data = [
        data_input,
        data_hs,
        data_silu,
        data_gotten,
        data_abs_diff_hs,
        data_abs_diff_silu,
    ]

    # Create figure
    fig = go.Figure(data=data)

    # Create buttons
    buttons = [
        dict(
            label="Input Image",
            method="update",
            args=[
                {"visible": [True, False, False, False, False, False]},
                {"xaxis": {"title": "Input Image"}},
            ],
        ),
        dict(
            label="Python HS",
            method="update",
            args=[
                {"visible": [False, True, False, False, False, False]},
                {
                    "xaxis": {
                        "title": f"Python Result with Hardswish Function (Channel: {channel})"
                    }
                },
            ],
        ),
        dict(
            label="Python SiLU",
            method="update",
            args=[
                {"visible": [False, False, True, False, False, False]},
                {
                    "xaxis": {
                        "title": f"Python Result with SiLU Function (Channel: {channel})"
                    }
                },
            ],
        ),
        dict(
            label="VHDL Output",
            method="update",
            args=[
                {"visible": [False, False, False, True, False, False]},
                {"xaxis": {"title": f"VHDL Result (Channel: {channel})"}},
            ],
        ),
        dict(
            label="Abs Diff HS",
            method="update",
            args=[
                {"visible": [False, False, False, False, True, False]},
                {
                    "xaxis": {
                        "title": f"Absolute Difference between Python HS and VHDL (Channel: {channel})"
                    }
                },
            ],
        ),
        dict(
            label="Abs Diff SiLU",
            method="update",
            args=[
                {"visible": [False, False, False, False, False, True]},
                {
                    "xaxis": {
                        "title": f"Absolute Difference between Python SiLU and VHDL (Channel: {channel})"
                    }
                },
            ],
        ),
    ]

    # Create layout
    fig.update_layout(
        updatemenus=[
            dict(
                buttons=buttons,
                direction="down",
                pad={"r": 10, "t": 10},
                showactive=True,
                x=1,
                xanchor="left",
                y=1.1,
                yanchor="top",
            )
        ],
        coloraxis=dict(
            colorscale="Viridis",
            colorbar=dict(
                title="Scale",
                tickformat=".2e",
                exponentformat="power",
            ),
        ),
        coloraxis2=dict(
            colorscale="Thermal",
            colorbar=dict(
                title="Abs Diff Scale",
                tickvals=[
                    abs_diff_hs_min[batch][channel],
                    abs_diff_hs_avg[batch][channel],
                    abs_diff_hs_max[batch][channel],
                ],
                ticktext=[
                    f"min: {abs_diff_hs_min[batch][channel]:.2f}",
                    f"avg: {abs_diff_hs_avg[batch][channel]:.2f}",
                    f"max: {abs_diff_hs_max[batch][channel]:.2f}",
                ],
                tickformat=".2f",
            ),
        ),
        coloraxis3=dict(
            colorscale="gray",
            colorbar=dict(title="Value"),
        ),
        coloraxis4=dict(
            colorscale="Thermal",
            colorbar=dict(
                title="Abs Diff Scale",
                tickvals=[
                    abs_diff_silu_min[batch][channel],
                    abs_diff_silu_avg[batch][channel],
                    abs_diff_silu_max[batch][channel],
                ],
                ticktext=[
                    f"min: {abs_diff_silu_min[batch][channel]:.2f}",
                    f"avg: {abs_diff_silu_avg[batch][channel]:.2f}",
                    f"max: {abs_diff_silu_max[batch][channel]:.2f}",
                ],
                tickformat=".2f",
            ),
        ),
        # Update the layout
        title=main_title,
        xaxis_title="Input Image",
        width=800,
        height=800,
        font=font,
        margin=dict(l=20, r=20, t=100, b=20),
    )

    fig.update_yaxes(autorange="reversed")

    # Show the figure
    fig.show()


def preprocess_input(generics: dict, i_data: torch.Tensor):
    """
    Preprocesses the input data by scaling it and converting to integer format.

    Parameters:
    ----------
        generics (dict): Configuration dictionary with scale factor.
        i_data (torch.Tensor): Input data tensor.

    Returns:
    -------
        List[int]: Preprocessed input data.
    """
    scale_factor = 2 ** generics["DATA_SCALE_FACTOR"]
    return (i_data * scale_factor).int().tolist()


def run_inference(image, model, dut_output):
    """
    Run inference on the model and the DUT and return the output tensors.

    Parameters:
    ----------
        image (torch.Tensor): The input image tensor.
        model (torch.nn.Module): The model used for inference.
        dut_output (torch.Tensor): The output tensor from the DUT.

    Returns:
    -------
        Tuple[torch.Tensor]: The output tensors from the model and the DUT.
    """

    # Run inference with the model and DUT
    prediction_silu = model.forward_end(
        model.forward_second_layer_silu(image.unsqueeze(0))
    )
    prediction_hs = model.forward_end(
        model.forward_second_layer_hs(image.unsqueeze(0))
    )
    prediction_dut = model.forward_end(dut_output)

    # Apply exponential to the output tensors (log_softmax -> softmax to get probabilities)
    prediction_silu = torch.exp(prediction_silu)
    prediction_hs = torch.exp(prediction_hs)
    prediction_dut = torch.exp(prediction_dut)

    return prediction_silu, prediction_hs, prediction_dut


def generate_probabilty_plot(input, ground_truth, model, output, scale_factor):
    """
    Generate a probability plot for the MNIST dataset and compare the predictions
    between different activation functions.

    Parameters:
    ----------
        input (torch.Tensor): The input tensor.
        ground_truth (torch.Tensor): The ground truth label.
        model (torch.nn.Module): The model used for inference.
        output (torch.Tensor): The output tensor from the DUT.
        scale_factor (float): Factor to scale the DUT output.

    Returns:
    -------
        None
    """

    # Convert DUT output to the correct tensor shape and type
    dut_output = torch.tensor(
        np.array(convert_output_to_int(output)), dtype=torch.float32
    ).unsqueeze(0)
    dut_output /= scale_factor

    # Run inference
    prediction_silu, prediction_hs, prediction_dut = run_inference(
        input, model, dut_output
    )

    # Convert tensors to numpy arrays for Plotly
    prediction_silu = prediction_silu.squeeze().detach().numpy()
    prediction_hs = prediction_hs.squeeze().detach().numpy()
    prediction_dut = prediction_dut.squeeze().detach().numpy()

    # Define the x-axis labels (digits 0 to 9)
    digits = list(range(10))

    # Convert input to grayscale image for visualization
    inverse_transform = transforms.Compose(
        [
            transforms.Normalize(mean=[-0.1307 / 0.3081], std=[1 / 0.3081]),
        ]
    )

    image = inverse_transform(input)
    image = (image * 255).int()[0]

    digits = list(range(10))
    fig = go.Figure()

    fig.add_trace(
        go.Bar(
            x=digits,
            y=prediction_silu,
            name="SiLU Activation",
            marker_color="royalblue",
            hovertemplate="SiLU Activation: %{y:.3f}<extra></extra>",
        )
    )

    fig.add_trace(
        go.Bar(
            x=digits,
            y=prediction_hs,
            name="Hardswish Activation",
            marker_color="lightgreen",
            hovertemplate="Hardswish Activation: %{y:.3f}<extra></extra>",
        )
    )

    fig.add_trace(
        go.Bar(
            x=digits,
            y=prediction_dut,
            name="VHDL Output",
            marker_color="salmon",
            hovertemplate="VHDL Output: %{y:.3f}<extra></extra>",
        )
    )

    fig.add_trace(
        go.Scatter(
            x=[ground_truth.item(), ground_truth.item()],
            y=[0, 1],
            mode="lines",
            line=dict(color="black", width=3, dash="dashdot"),
            name=f"Ground Truth: {ground_truth.item()}",
            hoverinfo="skip",
        )
    )

    fig.update_layout(
        title=dict(
            text=(
                f"<b>MNIST Prediction Comparison</b><br>"
                f"<span style='font-size: 14px;'>"
                f"Comparing SiLU, Hardswish Activations, and VHDL Outputs<br>"
                f"Ground Truth: {ground_truth.item()}</span>"
            ),
            x=0.5,
            y=0.95,
            font=dict(family="Arial, sans-serif", size=18, color="black"),
            xanchor="center",
            yanchor="top",
        ),
        xaxis=dict(
            title="<b>Digits (0-9)</b>",
            titlefont=dict(size=14, family="Arial, sans-serif"),
            tickfont=dict(size=12),
            tickvals=digits,
            showgrid=True,
            gridcolor="lightgray",
            zeroline=False,
        ),
        yaxis=dict(
            title="<b>Probability</b>",
            titlefont=dict(size=14, family="Arial, sans-serif"),
            tickfont=dict(size=12),
            showgrid=True,
            gridcolor="lightgray",
            range=[
                0,
                1.1,
            ],
        ),
        barmode="group",
        bargap=0.2,
        legend=dict(
            title="<b>Predictions</b>",
            orientation="h",
            yanchor="bottom",
            y=-0.2,
            xanchor="center",
            x=0.5,
            font=dict(size=12),
        ),
        margin=dict(l=50, r=50, t=100, b=80),
        plot_bgcolor="rgba(0, 0, 0, 0)",
        paper_bgcolor="white",
    )

    # Show the figure
    fig.show()
