
browenv
========

| Source: https://github.com/westurner/browenv

Objectives
------------
* SOCKS tunnel with supervisord
* Chrome over SOCKS proxy (with DNS)
* Per-(``VIRTUAL_ENV``,``_APP``) Chrome ``user-data-dir``
* Support venv: https://westurner.org/dotfiles/venv

Package
----------
* Makefile

  https://github.com/westurner/browenv/blob/master/Makefile

* supervisord.conf

  https://github.com/westurner/browenv/blob/master/supervisord.conf

Installation
--------------
Requirements:

* Git, SSH, Chrome
* (Optional) Python, Pip

.. code:: bash

   git clone https://github.com/westurner/browenv && cd browenv
   make install

Usage
-------

.. code:: bash

    # Start (supervisord w/ proxy) and browser
    make open SSH_USERHOST="user@host"

    # Stop (supervisord w/ proxy)
    make close

License
--------

`New BSD 3-Clause License
<https://github.com/westurner/browenv/blob/master/LICENSE>`__

* http://choosealicense.com/licenses/
* https://en.wikipedia.org/wiki/BSD_licenses
