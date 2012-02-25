#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import re
import os
import settings
import git
import HTML
import sqlite3
import datetime
from time import time
import shlex, subprocess
from optparse import OptionParser


class DrupalCores():
    def __init__(self, opts, args):
        """Initial setup and config of database
        """
        self.opts = opts
        self.args = args

        # Set up the sqlite3 db
        self.setDatabase()

        #the repo we've been asked to parse
        # @TODO: shell out to clone a repo into self.opts.temp dir/
        #git.Git(dcores.opts.temp).clone(dcores.args[0])

    def setDatabase(self):
        """Set up the sqlite3 db"""
        self.conn = sqlite3.connect(self.opts.db)
        self.conn.text_factory = str
        self.c = self.conn.cursor()

        self.c.execute('''create table if not exists users
        (username text, count real)''')
        self.c.execute('''create table if not exists hash
        (hash text, timestampt real)''')
        self.conn.commit()

    def lastHash(self, hash):
        """Add the last has to the sqlite database"""
        self.c.execute('insert into hash values (?, ?)', [hash, time()])
        self.conn.commit()

    def readLogs(self):
        pushd = os.getcwd()
        os.chdir(self.opts.temp)
        logs = subprocess.Popen(settings.GIT_LOG, stdout=subprocess.PIPE, shell=True).stdout.read()
        os.chdir(pushd)
        self.parseUsers(logs)

    def parseUsers(self, logs):
        lines = logs.splitlines()
        for item in lines:
            item = item.strip().split(":")
            sha = item[0]
            users = item[1]
            if users.startswith(" Issue"):
                commit_message = users.strip()
                commit_message = re.sub('Issue #[0-9]* (follow-up by|by) ', '', commit_message)
                commit_users = commit_message.split(",")
                for user in commit_users:
                    self.insertUser(user.strip(), sha)
            
            if users.startswith("- Patch"):
                commit_message = users.strip()
                commit_message = re.sub('- Patch #[0-9]* (follow-up by|by) ', '', commit_message)
                commit_users = commit_message.split(",")
                for user in commit_users:
                    self.insertUser(user.strip(), sha)

    def insertUser(self, username, hash):
        count = self.getUserCount(username)
        count = count + 1
        if count == 1:
            self.c.execute('insert into users values (?, ?)',[username, count])
        else:
            self.c.execute('update users set count = ? where username = ?', [count, username])

        self.conn.commit()

    def getUserCount(self, username):
        self.c.execute("select count from users where username = ?", [username])
        values = self.c.fetchone()
        if not values:
            return 0

        return values[0]

    def getAllUsers(self):
        pushd = os.getcwd()
        os.chdir(self.opts.temp)
        commitcount = subprocess.Popen(settings.GIT_COMMIT_COUNT, stdout=subprocess.PIPE, shell=True).stdout.read()
        print commitcount;
        os.chdir(pushd)
        self.c.execute("select *, (count*100 / ?) from users order by count desc", [commitcount])
        return self.c.fetchall()

#optparse stuff
def config():
    """Definition for acceptable options with python's optparse library.
    """
    parser = OptionParser(usage='%prog [options] URL', description='Parse '
            'gitrepository at URL and generate commit-statistics to reward'
            'your users')
    parser.add_option('-d', '--database', dest='db', default=':memory:',
        help="Database to use in counting user's commits.")
    parser.add_option('-b', '--branch', dest='branch', default='master',
        help="Branch you'd like to parse when checking out URL.")
    parser.add_option('-t', '--temp', dest='temp', default='drupal',
        help="Temporary directory you'd like to make a mess in.")
    parser.add_option('-o', '--output', dest='htmltable', default='pages/index.html',
        help="Filename that the HTML output should be written to.")

    return parser.parse_args()

def main():
    (opts, args) = config()
    dcores = DrupalCores(opts, args)

    #kick off the important leg work
    dcores.readLogs()

    #render our results
    writeHTML(dcores.getAllUsers(), dcores.opts.htmltable)

    #close sqlite3
    dcores.c.close()

def writeHTML(userCounts, tableName):
    htmlcode = "---\n"
    htmlcode += "layout: default\n"
    htmlcode += "date: " + str(datetime.datetime.now()) + "\n"
    htmlcode += "---\n\n\n"
    htmlcode += HTML.table(userCounts)
    f = open(tableName, 'w')
    f.writelines(htmlcode)
    f.close()

if __name__ == '__main__':
    main()

# vim: et:ts=4:sw=4:sts=4
