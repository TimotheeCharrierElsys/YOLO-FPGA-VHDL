# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = "HDL CNN"
copyright = "2024, Timothée CHARRIER"
author = "Timothée CHARRIER"


extensions = [
    "sphinx.ext.duration",
    "sphinx.ext.doctest",
    "sphinx.ext.autodoc",
    "sphinx.ext.graphviz",
    "sphinx.ext.intersphinx",
    "sphinx_copybutton",
    "sphinxcontrib.bibtex",
    "sphinx.ext.autosectionlabel",
]

autosectionlabel_prefix_document = True

templates_path = ["_templates"]
exclude_patterns = []

bibtex_bibfiles = ["refs.bib"]
bibtex_encoding = "latin"

html_theme = "furo"

html_theme_options = {
    "navigation_with_keys": True,
    "top_of_page_button": "edit",
}

html_static_path = ["_static"]

pygments_style = "emacs"
pygments_dark_style = "monokai"
