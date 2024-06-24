# Getting started

## Installation guide

### Cloning the repo

Open a terminal and run

```bash
git clone https://github.com/TimotheeCharrierElsys/YOLO-FPGA-VHDL.git
```

And go to dev branch

```bash
git checkout dev
```

### Setup virtual environment
Install package for virtual environment support:

```bash
apt install python3.10-venv
```

Then create a virtual environment:


```bash
python3 -m venv .venv
```

and then install the package for building the documentation

```bash
pip install -r requirements.txt
```

You are now ready to build the documentation. Go to the ``/DOCS`` folder and run

```bash
make html
```

Open the built index in ``DOCS/build/index.html``.