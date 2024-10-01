import argparse

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torch.optim.lr_scheduler import StepLR
from torch.utils.data import DataLoader
from torchvision import datasets, transforms


class Net(nn.Module):
    """
    A simple convolutional neural network for MNIST classification.

    Attributes
    ----------
    conv1 : nn.Conv2d
        First convolutional layer.
    bn1 : nn.BatchNorm2d
        Batch normalization layer after the first convolution.
    conv2 : nn.Conv2d
        Second convolutional layer.
    bn2 : nn.BatchNorm2d
        Batch normalization layer after the second convolution.
    dropout1 : nn.Dropout
        Dropout layer after the first max pooling.
    dropout2 : nn.Dropout
        Dropout layer after the first fully connected layer.
    fc1 : nn.Linear
        First fully connected layer.
    fc2 : nn.Linear
        Second fully connected layer.
    """

    def __init__(self):
        """
        Initialize the neural network layers.
        """
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(1, 32, 3, 2, 1)
        self.bn1 = nn.BatchNorm2d(32)
        self.conv2 = nn.Conv2d(32, 64, 3, 1)
        self.bn2 = nn.BatchNorm2d(64)
        self.dropout1 = nn.Dropout(0.25)
        self.dropout2 = nn.Dropout(0.5)
        self.fc1 = nn.Linear(64 * 6 * 6, 128)
        self.fc2 = nn.Linear(128, 10)

    def forward(self, x):
        """
        Define the forward pass of the network.

        Parameters
        ----------
        x : torch.Tensor
            Input tensor.

        Returns
        -------
        torch.Tensor
            Output tensor after passing through the network.
        """
        x = self.conv1(x)
        x = self.bn1(x)
        x = F.silu(x)

        x = self.conv2(x)
        x = self.bn2(x)
        x = F.silu(x)

        x = F.max_pool2d(x, 2)
        x = self.dropout1(x)

        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.silu(x)
        x = self.dropout2(x)
        x = self.fc2(x)
        output = F.log_softmax(x, dim=1)
        return output

    def forward_first_layer_hs(self, x):
        """
        Forward pass through the first layer using HardSwish activation.

        Parameters
        ----------
        x : torch.Tensor
            Input tensor.

        Returns
        -------
        torch.Tensor
            Output tensor after the first layer.
        """
        with torch.no_grad():
            x = self.conv1(x)
            x = self.bn1(x)
            output = F.hardswish(x)

        return output

    def forward_first_layer_silu(self, x):
        """
        Forward pass through the first layer using SiLU activation.

        Parameters
        ----------
        x : torch.Tensor
            Input tensor.

        Returns
        -------
        torch.Tensor
            Output tensor after the first layer.
        """
        with torch.no_grad():
            x = self.conv1(x)
            x = self.bn1(x)
            output = F.silu(x)

        return output

    def forward_second_layer_hs(self, x):
        """
        Forward pass through the first two layers using HardSwish activation.

        Parameters
        ----------
        x : torch.Tensor
            Input tensor.

        Returns
        -------
        torch.Tensor
            Output tensor after the second layer.
        """
        with torch.no_grad():
            x = self.conv1(x)
            x = self.bn1(x)
            x = F.hardswish(x)
            x = self.conv2(x)
            x = self.bn2(x)
            output = F.hardswish(x)

        return output

    def forward_second_layer_silu(self, x):
        """
        Forward pass through the first two layers using SiLU activation.

        Parameters
        ----------
        x : torch.Tensor
            Input tensor.

        Returns
        -------
        torch.Tensor
            Output tensor after the second layer.
        """
        with torch.no_grad():
            x = self.conv1(x)
            x = self.bn1(x)
            x = F.silu(x)
            x = self.conv2(x)
            x = self.bn2(x)
            output = F.silu(x)

        return output

    def forward_end(self, x):
        """
        Forward pass through the final layers of the network.

        Parameters
        ----------
        x : torch.Tensor
            Input tensor.

        Returns
        -------
        torch.Tensor
            Output tensor after the final layers.
        """
        with torch.no_grad():
            x = F.max_pool2d(x, 2)
            x = torch.flatten(x, 1)
            x = self.fc1(x)
            x = F.silu(x)
            x = self.fc2(x)
            output = F.log_softmax(x, dim=1)

        return output


def train(args, model, device, train_loader, optimizer, epoch):
    """
    Train the model for one epoch.

    Parameters
    ----------
    args : argparse.Namespace
        Command-line arguments.
    model : nn.Module
        The neural network model.
    device : torch.device
        The device to run the model on.
    train_loader : DataLoader
        DataLoader for the training data.
    optimizer : torch.optim.Optimizer
        Optimizer for updating the model parameters.
    epoch : int
        The current epoch number.
    """
    model.train()
    for batch_idx, (data, target) in enumerate(train_loader):
        data, target = data.to(device), target.to(device)
        optimizer.zero_grad()
        output = model(data)
        loss = F.nll_loss(output, target)
        loss.backward()
        optimizer.step()
        if batch_idx % args.log_interval == 0:
            print(
                "Train Epoch: {} [{}/{} ({:.0f}%)]\tLoss: {:.6f}".format(
                    epoch,
                    batch_idx * len(data),
                    len(train_loader.dataset),
                    100.0 * batch_idx / len(train_loader),
                    loss.item(),
                )
            )
            if args.dry_run:
                break


def test(model, device, test_loader):
    """
    Test the model on the test dataset.

    Parameters
    ----------
    model : nn.Module
        The neural network model.
    device : torch.device
        The device to run the model on.
    test_loader : DataLoader
        DataLoader for the test data.
    """
    model.eval()
    test_loss = 0
    correct = 0
    with torch.no_grad():
        for data, target in test_loader:
            data, target = data.to(device), target.to(device)
            output = model(data)
            # sum up batch loss
            test_loss += F.nll_loss(output, target, reduction="sum").item()
            # get the index of the max log-probability
            pred = output.argmax(dim=1, keepdim=True)
            correct += pred.eq(target.view_as(pred)).sum().item()

    test_loss /= len(test_loader.dataset)

    print(
        "\nTest set: Average loss: {:.4f}, Accuracy: {}/{} ({:.0f}%)\n".format(
            test_loss,
            correct,
            len(test_loader.dataset),
            100.0 * correct / len(test_loader.dataset),
        )
    )


def process_batchnorm2d(layer):
    """
    Process a BatchNorm2d layer to normalize its weights.

    Parameters
    ----------
    layer : nn.BatchNorm2d
        The BatchNorm2d layer to process.

    Returns
    -------
    torch.Tensor
        The normalized weights.
    """
    weights = layer.weight
    running_var = layer.running_var

    return weights / np.sqrt(running_var)


def load_dataset(model_path):
    """
    Load the MNIST dataset and a pre-trained model.

    Parameters
    ----------
    model_path : str
        Path to the pre-trained model file.

    Returns
    -------
    tuple
        A tuple containing the model and the test DataLoader.
    """
    model = Net()
    model.load_state_dict(
        torch.load(
            model_path, weights_only=True, map_location=torch.device("cpu")
        )
    )
    model.eval()

    # Define transformations and load the dataset
    transform = transforms.Compose(
        [transforms.ToTensor(), transforms.Normalize((0.1307,), (0.3081,))]
    )

    # Load the MNIST test dataset
    dataset = datasets.MNIST(
        "../data", train=False, transform=transform, download=True
    )
    test_loader = DataLoader(dataset, batch_size=500, shuffle=True)

    return model, test_loader


def load_model(model_path):
    """
    Load a pre-trained model.

    Parameters
    ----------
    model_path : str
        Path to the pre-trained model file.

    Returns
    -------
    nn.Module
        The loaded model.
    """
    model = Net()
    model.load_state_dict(
        torch.load(
            model_path, weights_only=True, map_location=torch.device("cpu")
        )
    )
    model.eval()

    return model


if __name__ == "__main__":
    # Training settings
    parser = argparse.ArgumentParser(description="PyTorch MNIST Example")
    parser.add_argument(
        "--batch-size",
        type=int,
        default=64,
        metavar="N",
        help="input batch size for training (default: 64)",
    )
    parser.add_argument(
        "--test-batch-size",
        type=int,
        default=1000,
        metavar="N",
        help="input batch size for testing (default: 1000)",
    )
    parser.add_argument(
        "--epochs",
        type=int,
        default=5,
        metavar="N",
        help="number of epochs to train (default: 14)",
    )
    parser.add_argument(
        "--lr",
        type=float,
        default=1.0,
        metavar="LR",
        help="learning rate (default: 1.0)",
    )
    parser.add_argument(
        "--gamma",
        type=float,
        default=0.7,
        metavar="M",
        help="Learning rate step gamma (default: 0.7)",
    )
    parser.add_argument(
        "--no-cuda",
        action="store_true",
        default=False,
        help="disables CUDA training",
    )
    parser.add_argument(
        "--no-mps",
        action="store_true",
        default=False,
        help="disables macOS GPU training",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        default=False,
        help="quickly check a single pass",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=1,
        metavar="S",
        help="random seed (default: 1)",
    )
    parser.add_argument(
        "--log-interval",
        type=int,
        default=10,
        metavar="N",
        help="how many batches to wait before logging training status",
    )
    parser.add_argument(
        "--save-model",
        action="store_true",
        default=True,
        help="For Saving the current Model",
    )
    args = parser.parse_args()
    use_cuda = not args.no_cuda and torch.cuda.is_available()
    use_mps = not args.no_mps and torch.backends.mps.is_available()

    torch.manual_seed(args.seed)

    if use_cuda:
        device = torch.device("cuda")
    elif use_mps:
        device = torch.device("mps")
    else:
        device = torch.device("cpu")

    train_kwargs = {"batch_size": args.batch_size}
    test_kwargs = {"batch_size": args.test_batch_size}
    if use_cuda:
        cuda_kwargs = {"num_workers": 1, "pin_memory": True, "shuffle": True}
        train_kwargs.update(cuda_kwargs)
        test_kwargs.update(cuda_kwargs)

    # Custom scaling transform
    class ScaleTransform:
        """
        Custom scaling transform for data augmentation.

        Parameters
        ----------
        scale_factor : float
            Factor to scale the input tensor.
        """

        def __init__(self, scale_factor):
            self.scale_factor = scale_factor

        def __call__(self, x):
            """
            Apply the scaling transform to the input tensor.

            Parameters
            ----------
            x : torch.Tensor
                Input tensor.

            Returns
            -------
            torch.Tensor
                Scaled tensor.
            """
            return x * self.scale_factor

    transform = transforms.Compose(
        [transforms.ToTensor(), transforms.Normalize((0.1307,), (0.3081,))]
    )
    dataset1 = datasets.MNIST(
        "../data", train=True, download=True, transform=transform
    )
    dataset2 = datasets.MNIST("../data", train=False, transform=transform)
    train_loader = torch.utils.data.DataLoader(dataset1, **train_kwargs)
    test_loader = torch.utils.data.DataLoader(dataset2, **test_kwargs)

    model = Net().to(device)
    optimizer = optim.Adadelta(model.parameters(), lr=args.lr)

    scheduler = StepLR(optimizer, step_size=1, gamma=args.gamma)
    for epoch in range(1, args.epochs + 1):
        train(args, model, device, train_loader, optimizer, epoch)
        test(model, device, test_loader)
        scheduler.step()

    if args.save_model:
        torch.save(model.state_dict(), "mnist_cnn.pt")
