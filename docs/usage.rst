Usage
=====

robofinch was intended to be used with other libraries, most prominently `zftftb <https://github.com/jmarkow/zftftb>`_ and `intan_frontend <https://github.com/jmarkow/intan_frontend>`_. 

How options/parameters are handled
----------------------------------

Because many of these scripts are intended to run without user intervention, parameters are stored in text files.  All ``robofinch`` functions read special text files in the directories you want to process.  For instance, say ``/Volumes/my_great_folder_of_data/`` contains data from 4 birds ``LHP57``, ``RB15``, ``LG720RBLK`` and ``RM10``.  You may want a default set of parameters for all birds, you would place a text file with the default options in ``/Volumes/my_great_folder_of_data/``.  What if you want parameter B to be different for ``LHP57``?  Simply place another text file with the setting for parameter B in ``/Volumes/my_great_folder_of_data/LHP57``.  The options files are scanned hierarchically, and are read from first to last.  

Setting parameters
^^^^^^^^^^^^^^^^^^

robofinch_parameters.txt


Parameters required for all robofinch functions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

audio_load
data_load



Computing sound features 
------------------------

.. warning:: This function will not work unless you specify how to read data from your files, see SECTION X

A common usage scenario involves data from an electrophysiology or imaging experiment being parsed by `intan_frontend <https://github.com/jmarkow/intan_frontend>`_.  Now you have a bunch of data aligned to singing in a folder somewhere.  A first step is to compute sound features for all data files.  This is done using ``robofinch_sound_score``, which recurses all directories, checks for sound files, and computes features using ``zftftb_song_score`` and stores them in the subdirectory ``syllable_data`` (history lesson:  the name is a holdover from a software package that preceded this called ``syllable_detector``).  For details on the specific features that are computed see `this section of the zftftb documentation <http://zftftb.readthedocs.org/en/latest/usage.html#features-used-for-clustering>`_.  

Open up MATLAB, ``cd`` into a directory that contains data files somewhere.  Say you have lots of data files in various subdirectories in ``/Volumes/my_great_folder_of_data/`` placed by `intan_frontend <https://github.com/jmarkow/intan_frontend>`_::

	>>cd /Volumes/my_great_folder_of_data/
	>>robofinch_sound_score;

``robofinch_sound_clust`` hunts for all files with a specific prefix to compute sound features for, which can be set using the parameter ``filename_filter`` (see table below).  By default, it searches for files that begin with ``songdet1`` and end with ``.mat``, which is the default setting for `intan_frontend <https://github.com/jmarkow/intan_frontend>`_. 

Clustering sounds
-----------------

.. warning:: This function will not work unless you specify how to read data from your files, see SECTION X

If you have used `zftftb <https://github.com/jmarkow/zftftb>`_ to select a template and cluster some data manually, if the option ``train_classifier`` was set to ``true``, then a support vector machine (SVM) is trained to do template matching automatically.  The upshot is you can cluster a day's worth of data manually, then ``robofinch_sound_clust`` automatically extract examples of that template from the rest of your data and all data you collect in the future for the same animal.  

#. After running ``zftftb_song_clust`` with the ``train_classifier`` parameter set to ``1`` or ``true``, cd into the sub-directory with files from your "run"::
	
	>>zftftb_song_clust(pwd,'audio_load',myloadfunction,'train_classifier',1); 

   Assuming that you created a new run and used the name ``testing``::

   	>>cd testing_MANUALCLUST
   	>>ls

   You should see 

		#. cluster_data.mat -> contains a data structure used for clustering
		#. cluster_results.mat -> contains the result of the manual clustering procedure
		#. *classify_data.mat* -> contains the specifications of the support vector machine for automatic clustering
		#. *template_data.mat* -> contains the template 

   You will need ``classify_data.mat`` and ``template_data.mat`` for automatic clustering.  They are copied to a special directory in the hierarchy created by `intan_frontend <https://github.com/jmarkow/intan_frontend>`_ (you do not have to use the hierarchy created by this, as long you follow the same conventions) ``/Volumes/my_great_folder_of_data/[BIRD]/templates/[NAME_OF_TEMPLATE]/``.  Substitute whatever you like with [NAME_OF_TEMPLATE], this will be the name used for automatic template matching.  So let's say you want the template to be named "best_song_A" and the bird's ID is "LHP57", you would do the following

   		#. create the directory ``/Volumes/my_great_folder_of_data/LHP57/templates/best_song_A/``
   		#. copy the files ``classify_data.mat`` and ``template_data.mat`` to the folder you just created
   
#. Now run the following commands::
   
   >>cd /Volumes/my_great_folder_of_data/
   >>robofinch_sound_clust;


Aggregating data
----------------

Use ``robofinch_agg_data``. 

Running function on aggregated data
-----------------------------------

Use ``robofinch_agg_scripts``

The daemon
----------

In all likelihood you will not interact with many of the other functions in the robofinch toolbox, and instead you will run the daemon ``robofinch_daemon``, which runs sound feature calculation, sound clustering, data aggregation, and any custom functions you want to use to generate figures from the aggregated data.
