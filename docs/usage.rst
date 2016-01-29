Usage
=====

robofinch was intended to be used with other libraries, most prominently `zftftb <https://github.com/jmarkow/zftftb>`_ and `intan_frontend <https://github.com/jmarkow/intan_frontend>`_. 

Computing sound features 
------------------------

A common usage scenario involves data from an electrophysiology or imaging experiment being parsed by `intan_frontend <https://github.com/jmarkow/intan_frontend>`_.  Now you have a bunch of data aligned to singing in a folder somewhere.  A first step is to compute sound features for all data files.  This is done using ``robofinch_sound_clust``, which recurses all directories, checks for sound files, and computes features using ``zftftb_song_score`` and stores them in the subdirectory ``syllable_data`` (history lesson:  the name is a holdover from a software package that preceded this called ``syllable_detector``).  For details on the specific features that are computed see `this section of the zftftb documentation <http://zftftb.readthedocs.org/en/latest/usage.html#features-used-for-clustering>`_.  

Open up MATLAB, ``cd`` into a directory that contains data files somewhere.  Say you have lots of data files in various subdirectories in ``/Volumes/my_great_folder_of_data/`` placed by `intan_frontend <https://github.com/jmarkow/intan_frontend>`_::

	>>cd /Volumes/my_great_folder_of_data/
	>>robofinch_sound_clust;

``robofinch_sound_clust`` hunts for all files with a specific prefix to compute sound features for, which can be set using the parameter ``filename_filter`` (see table below).  By default, it searches for files that begin with ``songdet1`` and end with ``.mat``, which is the default setting for `intan_frontend <https://github.com/jmarkow/intan_frontend>`_. 

Clustering sounds
-----------------

If you have used `zftftb <https://github.com/jmarkow/zftftb>`_ to select a template and cluster some data manually, if the option ``train_classifier`` was set to ``true``, then a support vector machine (SVM) is trained to do template matching automatically.  The upshot is you can cluster a day's worth of data manually, then automatically extract examples of that template from the rest of your data and all data you collect in the future.  

The daemon
----------

In all likelihood you will not interact with many of the other functions in the robofinch toolbox, and instead you will run the daemon ``robofinch_daemon``, which runs sound feature calculation, sound clustering, data aggregation, and any custom functions you want to use to generate figures from the aggregated data.
