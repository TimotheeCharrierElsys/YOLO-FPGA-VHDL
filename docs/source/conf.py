# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'YOLO implementation on FPGA'
copyright = '2024, Timothée CHARRIER'
author = 'Timothée CHARRIER'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx.ext.duration',
    'sphinx.ext.doctest',
    'sphinx.ext.autodoc',
    "sphinx.ext.graphviz",
    "sphinx.ext.intersphinx",
    "sphinx_copybutton",
    "sphinxcontrib.bibtex",
]

templates_path = ['_templates']
exclude_patterns = []

bibtex_bibfiles = ['refs.bib']
bibtex_encoding = 'latin'

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'furo'
html_static_path = ['_static']

html_theme_options = {
    "navigation_with_keys": True,
     "top_of_page_button": "edit",
}

pygments_style = "emacs"
pygments_dark_style = "monokai"
