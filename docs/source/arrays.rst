.. include:: defs.rst
.. _arrays:

Compressed Arrays
=================

.. cpp:namespace:: zfp

|zfp|'s compressed arrays are C++ classes, plus C wrappers around these
classes, that implement random-accessible single- and multi-dimensional
floating-point arrays whose storage size, specified in number of bits per
array element, is set by the user.  Such arbitrary storage is achieved via
|zfp|'s lossy :ref:`fixed-rate compression <mode-fixed-rate>` mode, by
partitioning each *d*-dimensional array into blocks of |4powd| values
and compressing each block to a fixed number of bits.  The more smoothly
the array values vary along each dimension, the more accurately |zfp| can
represent them.  In other words, these arrays are not suitable for
representing data where adjacent elements are not correlated.  Rather,
the expectation is that the array represents a regularly sampled and
predominantly continuous function, such as a temperature field in a physics
simulation.

The *rate*, measured in number of bits per array element, can be specified
in fractions of a bit (but see FAQs :ref:`#12 <q-granularity>` and
:ref:`#18 <q-rate>` for limitations).  Note that array dimensions need not
be multiples of four; |zfp| transparently handles partial blocks on array
boundaries.

The C++ templated array classes are implemented entirely as header files
that call the |zfp| C library to perform compression and decompression.
These arrays cache decompressed blocks to reduce the number of compression
and decompression calls.  Whenever an array value is read, the corresponding
block is first looked up in the cache, and if found the uncompressed value
is returned.  Otherwise the block is first decompressed and stored in the
cache.  Whenever an array element is written (whether actually modified or
not), a "dirty bit" is set with its cached block to indicate that the block
must be compressed back to persistent storage when evicted from the cache.

This section documents the public interface to the array classes, including
base classes and member accessor classes like proxy references/pointers,
iterators, and views.

The following sections are available:

* :ref:`array_classes`
* :ref:`header`
* :ref:`exceptions`
* :ref:`caching`
* :ref:`references`
* :ref:`pointers`
* :ref:`iterators`
* :ref:`views`
* :ref:`cfp`

.. _array_classes:

Array Classes
-------------

Currently there are six array classes for 1D, 2D, and 3D arrays, each of
which can represent single- or double-precision values.  Although these
arrays store values in a form different from conventional single- and
double-precision floating point, the user interacts with the arrays via
floats and doubles.

The array classes can often serve as direct substitutes for C/C++
single- and multi-dimensional floating-point arrays and STL vectors, but
have the benefit of allowing fine control over storage size.  All classes
below belong to the :cpp:any:`zfp` namespace.

Base Class
^^^^^^^^^^

.. cpp:class:: array

  Virtual base class for common array functionality.

.. cpp:function:: double array::rate() const

  Return rate in bits per value.

.. cpp:function:: double array::set_rate(double rate)

  Set desired compression rate in bits per value.  Return the closest rate
  supported.  See :ref:`FAQ #12 <q-granularity>` and :ref:`FAQ #18 <q-rate>`
  for discussions of the rate granularity.  This method destroys the previous
  contents of the array.

.. cpp:function:: virtual void array::clear_cache() const

  Empty cache without compressing modified cached blocks, i.e., discard any
  cached updates to the array.

.. cpp:function:: virtual void array::flush_cache() const

  Flush cache by compressing all modified cached blocks back to persistent
  storage and emptying the cache.  This method should be called before
  writing the compressed representation of the array to disk, for instance.

.. cpp:function:: size_t array::compressed_size() const

  Return number of bytes of storage for the compressed data.  This amount
  does not include the small overhead of other class members or the size
  of the cache.  Rather, it reflects the size of the memory buffer
  returned by :cpp:func:`compressed_data`.

.. cpp:function:: uchar* array::compressed_data() const

  Return pointer to compressed data for read or write access.  The size
  of the buffer is given by :cpp:func:`compressed_size`.

.. cpp:function:: uint dimensionality() const

  Return the dimensionality of the compressed array.

.. cpp:function:: zfp_type scalar_type() const

  Return the underlying :c:type:`zfp_type` of the compressed array.

.. cpp:function:: void write_header(header& h) const

  Write a header describing this compressed array into struct
  :cpp:type:`header`.

Common Methods
^^^^^^^^^^^^^^

The following methods are common to 1D, 2D, and 3D arrays, but are implemented
in the array class specific to each dimensionality rather than in the base
class.

.. cpp:function:: size_t array::size() const

  Total number of elements in array, e.g. *nx* |times| *ny* |times| *nz* for
  3D arrays.

.. cpp:function:: size_t array::cache_size() const

  Return the cache size in number of bytes.

.. cpp:function:: void array::set_cache_size(size_t csize)

  Set minimum cache size in bytes.  The actual size is always a power of two
  bytes and consists of at least one block.  If *csize* is zero, then a
  default cache size is used, which requires the array dimensions to be known.

.. cpp:function:: void array::get(Scalar* p) const

  Decompress entire array and store at *p*, for which sufficient storage must
  have been allocated.  The uncompressed array is assumed to be contiguous
  (with default strides) and stored in the usual "row-major" order, i.e. with
  *x* varying faster than *y* and *y* varying faster than *z*.

.. cpp:function:: void array::set(const Scalar* p)

  Initialize array by copying and compressing data stored at *p*.  The
  uncompressed data is assumed to be stored as in the :cpp:func:`get`
  method.

.. cpp:function:: Scalar array::operator[](uint index) const

  Return scalar stored at given flat index (inspector).  For a 3D array,
  :code:`index = x + nx * (y + ny * z)`.

.. cpp:function:: reference array::operator[](uint index)

  Return :ref:`proxy reference <references>` to scalar stored at given flat
  index (mutator).  For a 3D array, :code:`index = x + nx * (y + ny * z)`.

.. cpp:function:: iterator array::begin()

  Return iterator to beginning of array.

.. cpp:function:: iterator array::end()

  Return iterator to end of array.  As with STL iterators, the end points
  to a virtual element just past the last valid array element.


1D, 2D, and 3D Arrays
^^^^^^^^^^^^^^^^^^^^^

Below are classes and methods specific to each array dimensionality and
template scalar type (:code:`float` or :code:`double`).  Since the classes
and methods share obvious similarities regardless of dimensionality, only
one generic description for all dimensionalities is provided.

Note: In the class declarations below, the class template for the scalar
type is ommitted for readability, e.g.,
:code:`class array1` is used as shorhand for
:code:`template <typename Scalar> class array1`.  Wherever the type
:code:`Scalar` appears, it refers to this template argument.

..
  .. cpp:class:: template<typename Scalar> array1 : public array
  .. cpp:class:: template<typename Scalar> array2 : public array
  .. cpp:class:: template<typename Scalar> array3 : public array

.. cpp:class:: array1 : public array
.. cpp:class:: array2 : public array
.. cpp:class:: array3 : public array

  This is a 1D/2D/3D array that inherits basic functionality from the generic
  :cpp:class:`array` base class.  The template argument, :cpp:type:`Scalar`,
  specifies the floating type returned for array elements.  The suffixes
  :code:`f` and :code:`d` can also be appended to each class to indicate float
  or double type, e.g. :cpp:class:`array1f` is a synonym for
  :cpp:class:`array1\<float>`.

.. cpp:class:: arrayANY : public array

  Fictitious class used to refer to any one of :cpp:class:`array1`,
  :cpp:class:`array2`, and :cpp:class:`array3`.  This class is not part of
  the |zfp| API.

.. _array_ctor_default:
.. cpp:function:: array1::array1()
.. cpp:function:: array2::array2()
.. cpp:function:: array3::array3()

  Default constructor.  Creates an empty array.

.. _array_ctor:
.. cpp:function:: array1::array1(uint n, double rate, const Scalar* p = 0, size_t csize = 0)
.. cpp:function:: array2::array2(uint nx, uint ny, double rate, const Scalar* p = 0, size_t csize = 0)
.. cpp:function:: array3::array3(uint nx, uint ny, uint nz, double rate, const Scalar* p = 0, size_t csize = 0)

  Constructor of array with dimensions *n* (1D), *nx* |times| *ny* (2D), or
  *nx* |times| *ny* |times| *nz* (3D) using *rate* bits per value, at least
  *csize* bytes of cache, and optionally initialized from flat, uncompressed
  array *p*.  If *csize* is zero, a default cache size is chosen.

.. cpp:function:: array1::array1(const header& h, const uchar* buffer, size_t bufferSize = 0)
.. cpp:function:: array2::array2(const header& h, const uchar* buffer, size_t bufferSize = 0)
.. cpp:function:: array3::array3(const header& h, const uchar* buffer, size_t bufferSize = 0)

  Constructor of array from previously-serialized compressed array. Struct
  :cpp:type:`header` contains header information, while *buffer* points to the
  compressed-data. Optional *bufferSize* argument specifies *buffer* length, in
  bytes, in case header describes a longer array. Throws
  :cpp:class:`header_exception` if unable to construct.

.. cpp:function:: array1::array1(const array1& a)
.. cpp:function:: array2::array2(const array2& a)
.. cpp:function:: array3::array3(const array3& a)

  Copy constructor.  Performs a deep copy.

.. cpp:function:: virtual array1::~array1()
.. cpp:function:: virtual array2::~array2()
.. cpp:function:: virtual array3::~array3()

  Virtual destructor (allows for inheriting from |zfp| arrays).

.. _array_copy:
.. cpp:function:: array1& array1::operator=(const array1& a)
.. cpp:function:: array2& array2::operator=(const array2& a)
.. cpp:function:: array3& array3::operator=(const array3& a)

  Assignment operator.  Performs a deep copy.

.. _array_dims:
.. cpp:function:: uint array2::size_x() const
.. cpp:function:: uint array2::size_y() const
.. cpp:function:: uint array3::size_x() const
.. cpp:function:: uint array3::size_y() const
.. cpp:function:: uint array3::size_z() const

  Return array dimensions.

.. _array_resize:
.. cpp:function:: void array1::resize(uint n, bool clear = true)
.. cpp:function:: void array2::resize(uint nx, uint ny, bool clear = true)
.. cpp:function:: void array3::resize(uint nx, uint ny, uint nz, bool clear = true)

  Resize the array (all previously stored data will be lost).  If *clear* is
  true, then the array elements are all initialized to zero.

.. _array_accessor:
.. cpp:function:: Scalar array1::operator()(uint i) const
.. cpp:function:: Scalar array2::operator()(uint i, uint j) const
.. cpp:function:: Scalar array3::operator()(uint i, uint j, uint k) const

  Return scalar stored at multi-dimensional index given by *i*, *j*, and *k*
  (inspector).

.. _lvref:
.. cpp:function:: reference array1::operator()(uint i)
.. cpp:function:: reference array2::operator()(uint i, uint j)
.. cpp:function:: reference array3::operator()(uint i, uint j, uint k)

  Return :ref:`proxy reference <references>` to scalar stored at
  multi-dimensional index given by *i*, *j*, and *k* (mutator).

.. include:: header.inc
.. include:: exceptions.inc
.. include:: caching.inc
.. include:: references.inc
.. include:: pointers.inc
.. include:: iterators.inc
.. include:: views.inc
.. include:: cfp.inc

Serializing and Deserializing Compressed Arrays
-----------------------------------------------

|zfp|'s compressed arrays can be written to disk and recovered back into an
object. To serialize a compressed array object, record a header into struct
:cpp:type:`header` through :cpp:func:`write_header`. Also record the
compressed-stream (blocks) using :cpp:func:`compressed_data`, having length
:cpp:func:`compressed_size` (in bytes).

There are two methods to construct a compressed array object from memory. The
first is to use the correct array type's constructor, which accepts a *header*
, *buffer*, and an optional *bufferSize* argument. If the wrong array type is
used, then :cpp:class:`header_exception` is thrown.

The second method is useful when the serialized array type is unknown, but
described in the header. There is a utility function in zfputils.h

.. cpp:function:: array* construct_from_stream(const header& h, const uchar* buffer, size_t bufferSize = 0)

  Attempts to construct each type of compressed array, returning a pointer to
  the base class upon success, otherwise returning :c:macro:`NULL`. Just as
  with the constructor, :cpp:type:`header` holds the header and *buffer* holds
  the compressed data. Optional *bufferSize* argument specifies *buffer* length
  , in bytes.
