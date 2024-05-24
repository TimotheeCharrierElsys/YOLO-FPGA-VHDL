
Package: types_pkg
==================


* **File**\ : types_pkg.vhd

Types
-----

.. list-table::
   :header-rows: 1

   * - Name
     - Type
     - Description
   * - t_vec
     - array (natural range <>) of std_logic_vector
     - @type t_vec


 @brief Defines an unconstrained array of std_logic_vectors.
        This type is used to represent a vector of std_logic_vectors. |
| t_mat | array (natural range <>) of t_vec            | @type t_mat  @brief Defines an unconstrained array of t_vec.                                                                                   |
