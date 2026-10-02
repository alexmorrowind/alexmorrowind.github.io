"""Project package initialization.

The cPanel production database is MariaDB.  PyMySQL is a pure-Python driver,
so it works on shared hosting without requiring MySQL development headers.
Installing it as ``MySQLdb`` keeps Django's standard MySQL backend unchanged.
"""

try:
    import pymysql

    pymysql.install_as_MySQLdb()

    # Django 6.0 checks the mysqlclient version exposed by ``MySQLdb``
    # before opening a connection. PyMySQL is wire-compatible with the
    # driver API used by this project, but older PyMySQL releases report a
    # lower client version even though the required API is present. Keep
    # this compatibility shim local to the optional MariaDB path instead of
    # changing Django's backend or the system Python installation.
    import MySQLdb

    if getattr(MySQLdb, 'version_info', (0, 0, 0)) < (2, 2, 1):
        MySQLdb.version_info = (2, 2, 1)
        MySQLdb.__version__ = '2.2.1'
except ImportError:
    # Local environments that use SQLite do not need the optional driver.
    pass
