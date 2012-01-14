#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import git
import sqlite3
from optparse import OptionParser

#optparse stuff
def config():
    """Definition for acceptable options with python's optparse library.
    """
    parser = OptionParser(usage='%prog [options] URL', description='Parse '
            'gitrepository at URL and generate commit-statistics to reward'
            'your users')
    parser.add_option('-b', '--branch', dest='branch', default='master',
        help="Branch you'd like to parse when checking out URL.")
    parser.add_option('-t', '--temp', dest='temp', default='tmp/',
        help="Temporary directory you'd like to make a mess in.")

    return parser.parse_args()

def main():
    global conn
    global c
    (opts, args) = config()

    #sqlite db
    conn = sqlite3.connect('cores.db')
    c = conn.cursor()

    # Set up the sqlite3 db
    setDatabase();

    #the repo we've been asked to parse
    #@TODO: install bleeding-edge gitpython (instead of old debian version),
    # maybe .clone will work, see:
    # - https://github.com/davvid/GitPython/blob/00c5497f190172765cc7a53ff9d8852a26b91676/CHANGES#L63-67

    #git.Git(opts.temp).clone(args[0])


    # close the cursor
    c.close();


def setDatabase():
    # Set up the sqlite3 db
    c.execute('''create table if not exists users
    (username text, count real)''')
    c.execute('''create table if not exists hash
    (hash test, timestampt real)''')
    conn.commit()

if __name__ == '__main__':
    main()

# vim: et:ts=4:sw=4:sts=4

