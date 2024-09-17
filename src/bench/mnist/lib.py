import plotly.graph_objects as go
import torch
from torchvision import transforms


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
    Calculate the error between the output and the gotten output.

    Parameters:
    ----------
        output (torch.Tensor): The output tensor.
        gotten_output (torch.Tensor): The gotten output tensor.

    Returns:
    -------
        Tuple[torch.Tensor]: Average, maximum, and minimum error per channel
    """
    abs_diff = torch.abs(output - gotten_output).float()

    # Compute statistics channel-wise
    avg_diff_per_channel = torch.mean(abs_diff, dim=(1, 2))
    max_diff_per_channel = torch.max(
        abs_diff.view(abs_diff.size(0), -1), dim=1
    ).values
    min_diff_per_channel = torch.min(
        abs_diff.view(abs_diff.size(0), -1), dim=1
    ).values

    return (
        abs_diff,
        avg_diff_per_channel,
        max_diff_per_channel,
        min_diff_per_channel,
    )


def postprocess_output(input, output_hs, output_silu, gotten_output):
    """
    Postprocess the output tensors for visualization.

    Parameters:
    ----------
        input (torch.Tensor): The input tensor.
        output_hs (torch.Tensor): The output tensor with Hardswish activation.
        output_silu (torch.Tensor): The output tensor with SiLU activation.
        gotten_output (torch.Tensor): The output tensor from the DUT

    Returns:
    -------
        Tuple[torch.Tensor]: Preprocessed tensors for visualization.
    """
    # Apply inverse transformation to the input
    inverse_transform = transforms.Compose(
        [
            transforms.Normalize(mean=[-0.1307 / 0.3081], std=[1 / 0.3081]),
        ]
    )

    input = inverse_transform(input)

    # Flip y axis for a tensor (idk why, plotly is doing weird stuff)
    output_hs = torch.flip(output_hs, [1])
    output_silu = torch.flip(output_silu, [1])
    gotten_output = torch.flip(gotten_output, [1])

    return input, output_hs, output_silu, gotten_output


def generate_report_first_layer(
    input, output_silu, output_hs, gotten_output, name="First Layer"
):
    """
    Generate a report for the first layer inference.

    Parameters:
    ----------
        generics (dict): Configuration dictionary.
        input (torch.Tensor): The input tensor.
        output_silu (torch.Tensor): The output tensor with SiLU activation.
        output_hs (torch.Tensor): The output tensor with Hardswish activation.
        gotten_output (torch.Tensor): The output tensor from the DUT

    Returns:
    -------
        None
    """

    # Calculate the error
    abs_diff_hs, abs_diff_hs_avg, abs_diff_hs_max, abs_diff_hs_min = (
        calculate_error(output_hs, gotten_output)
    )

    abs_diff_silu, abs_diff_silu_avg, abs_diff_silu_max, abs_diff_silu_min = (
        calculate_error(output_silu, gotten_output)
    )

    # Setup the data
    num_channels, height, width = output_hs.shape

    # Create Generic Parameters for the report
    font = dict(family="Arial, sans-serif", size=12, color="black")
    main_title = dict(
        text=(
            f"<b>Convolutional Layer Report For {name} Inference</b><br>"
            f"<span style='font-size: 14px;'>"
            f"Input Shape: {input.shape}, Output Shape: {output_hs.shape}<br>"
        ),
        x=0.0,
        y=0.95,
        font={"family": "Arial, sans-serif", "color": "black"},
        xanchor="left",
        yanchor="top",
    )

    # Only use the first channel
    channel = 0

    # Heatmap traces
    data_hs = go.Heatmap(
        z=output_hs[channel],
        colorscale="Viridis",
        visible=False,
        coloraxis="coloraxis",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_silu = go.Heatmap(
        z=output_silu[channel],
        colorscale="Viridis",
        visible=False,
        coloraxis="coloraxis",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_gotten = go.Heatmap(
        z=gotten_output[channel],
        colorscale="Viridis",
        visible=False,
        coloraxis="coloraxis",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_abs_diff_hs = go.Heatmap(
        z=abs_diff_hs[channel],
        colorscale="Thermal",
        visible=False,
        coloraxis="coloraxis2",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_abs_diff_silu = go.Heatmap(
        z=abs_diff_silu[channel],
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
                {"xaxis": {"title": "Python Result with Hardswish Function"}},
            ],
        ),
        dict(
            label="Python SiLU",
            method="update",
            args=[
                {"visible": [False, False, True, False, False, False]},
                {"xaxis": {"title": "Python Result with SiLU Function"}},
            ],
        ),
        dict(
            label="VHDL Output",
            method="update",
            args=[
                {"visible": [False, False, False, True, False, False]},
                {"xaxis": {"title": "VHDL Result"}},
            ],
        ),
        dict(
            label="Abs Diff HS",
            method="update",
            args=[
                {"visible": [False, False, False, False, True, False]},
                {
                    "xaxis": {
                        "title": "Absolute Difference between Python HS and VHDL"
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
                        "title": "Absolute Difference between Python SiLU and VHDL"
                    }
                },
            ],
        ),
    ]

    # Create layout
    fig.update_layout(
        # Update the Menu
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
                    abs_diff_hs_min[channel],
                    abs_diff_hs_avg[channel],
                    abs_diff_hs_max[channel],
                ],
                ticktext=[
                    f"min: {abs_diff_hs_min[channel]:.2f}",
                    f"avg: {abs_diff_hs_avg[channel]:.2f}",
                    f"max: {abs_diff_hs_max[channel]:.2f}",
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
                    abs_diff_silu_min[channel],
                    abs_diff_silu_avg[channel],
                    abs_diff_silu_max[channel],
                ],
                ticktext=[
                    f"min: {abs_diff_silu_min[channel]:.2f}",
                    f"avg: {abs_diff_silu_avg[channel]:.2f}",
                    f"max: {abs_diff_silu_max[channel]:.2f}",
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
