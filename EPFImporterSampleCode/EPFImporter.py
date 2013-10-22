#!/usr/bin/python

#
# File: EPFImporter.py
# Abstract: Main entry point into the EPF Import code. Parses options and runs the parser and ingester.
# Version: 1.0
# 
# Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
# Inc. ("Apple") in consideration of your agreement to the following
# terms, and your use, installation, modification or redistribution of
# this Apple software constitutes acceptance of these terms.  If you do
# not agree with these terms, please do not use, install, modify or
# redistribute this Apple software.
# 
# In consideration of your agreement to abide by the following terms, and
# subject to these terms, Apple grants you a personal, non-exclusive
# license, under Apple's copyrights in this original Apple software (the
# "Apple Software"), to use, reproduce, modify and redistribute the Apple
# Software, with or without modifications, in source and/or binary forms;
# provided that if you redistribute the Apple Software in its entirety and
# without modifications, you must retain this notice and the following
# text and disclaimers in all such redistributions of the Apple Software.
# Neither the name, trademarks, service marks or logos of Apple Inc. may
# be used to endorse or promote products derived from the Apple Software
# without specific prior written permission from Apple.  Except as
# expressly stated in this notice, no other rights or licenses, express or
# implied, are granted by Apple herein, including but not limited to any
# patent rights that may be infringed by your derivative works or by other
# works in which the Apple Software may be incorporated.
# 
# The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
# MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
# OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
# 
# IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
# MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
# AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
# STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# 
# Copyright (C) 2010 Apple Inc. All Rights Reserved.
# 

import EPFIngester
import MySQLdb
import os
import sys
import datetime
import re
import json
import copy
import optparse
import ConfigParser
import logging
import logging.config
import errno


VERSION = "1.1.2"
DESCRIPTION = """EPFImporter is a tool for importing EPF files into a database."""

CONFIG_PATH = "./EPFConfig.json"
FLAT_CONFIG_PATH = "./EPFFlatConfig.json"

#Snapshot is updated throughout the import; it is used for resuming interrupted imports
global SNAPSHOT_PATH, SNAPSHOT_DICT
SNAPSHOT_PATH = "./EPFSnapshot.json"
SNAPSHOT_DICT = {"tablePrefix":None, "dirsToImport":[], "dirsLeft":[], "currentDict":{}}

# FULL_STATUS_PATH = "./EPFStatusFull.json"
# INCREMENTAL_STATUS_PATH = "./EPFStatusIncremental.json"
# FULL_STATUS_DICT = {"tablePrefix":None, "dirsToImport":[], "dirsLeft":[], "currentDict":{}}
# INCREMENTAL_STATUS_DICT = {"tablePrefix":None, "dirsToImport":[], "dirsLeft":[], "currentDict":{}}
# 
# STATUS_MAP = {"full":(FULL_STATUS_DICT, FULL_STATUS_PATH),
#        "incremental":(INCREMENTAL_STATUS_DICT, INCREMENTAL_STATUS_PATH)}
       

#Create a directory for rotating logs
try:
    os.mkdir("EPFLogs")
except OSError, e:
    if e.errno == errno.EEXIST:
        pass

LOGGER_CONFIG_PATH = "./EPFLogger.conf"
if not os.path.exists(LOGGER_CONFIG_PATH):
    #If the logging config file is missing, create one
    conf = ConfigParser.RawConfigParser()
    conf.add_section("formatter_simpleFormatter")
    conf.set("formatter_simpleFormatter", "datefmt", "")
    conf.set("formatter_simpleFormatter", "format", "%(asctime)s [%(levelname)s]: %(message)s")
    conf.add_section("handler_fileHandler")
    #Set log to rotate every 24 hours and keep the last 120 logs before rotating.
    #We use seconds ('S') to force the date stamp to include minutes and seconds.
    #We will actually 'manually' roll over the log before each import.
    conf.set("handler_fileHandler", "args", "('EPFLogs/EPFLog.log', 'S', 86400, 120)")
    conf.set("handler_fileHandler", "formatter", "simpleFormatter")
    conf.set("handler_fileHandler", "level", "INFO")
    conf.set("handler_fileHandler", "class", "logging.handlers.TimedRotatingFileHandler")
    conf.add_section("handler_consoleHandler")
    conf.set("handler_consoleHandler", "args", "(sys.stdout, )")
    conf.set("handler_consoleHandler", "formatter", "simpleFormatter")
    conf.set("handler_consoleHandler", "level", "INFO")
    conf.set("handler_consoleHandler", "class", "StreamHandler")
    conf.add_section("formatters")
    conf.set("formatters", "keys", "simpleFormatter")
    conf.add_section("logger_root")
    conf.set("logger_root", "handlers", "consoleHandler, fileHandler")
    conf.set("logger_root", "level", "INFO")
    conf.add_section("handlers")
    conf.set("handlers", "keys", "consoleHandler, fileHandler")
    conf.add_section("loggers")
    conf.set("loggers", "keys", "root")

    with open(LOGGER_CONFIG_PATH, mode='w') as f:
        conf.write(f)

logging.config.fileConfig(LOGGER_CONFIG_PATH)
LOGGER = logging.getLogger()


def doImport(directoryPath,
            dbHost='localhost',
            dbUser='epfimporter',
            dbPassword='epf123',
            dbName='epf',
            whiteList=[r'.*?'],
            blackList=[],
            tablePrefix=None,
            allowExtensions=False,
            skipKeyViolators=False,
            recordDelim='\x02\n',
            fieldDelim='\x01'):
    """
    Perform a full import of the EPF files in the directory specified by directoryPath.
    
    importMode can be 'full' or 'incremental'
    
    whiteList is a sequence of regular expressions. Only files whose basenames (i.e., the last 
    element in the path) match one or more of the regexes in whiteList will be imported. For 
    example, whiteList=[".*song.*", ".*video.*"] would result in all files containing "song" or 
    "video" anywhere in the filename being imported, and the rest being ignored. To import only
    exact matches, precede the name with a caret (^) and follow it with a dollar sign ($), e.g.
    "^video$".
    
    The default is for all files to be whitelisted.
    
    blackList works similarly; any filenames matching any of the items in blackList will be 
    excluded from the import, even if they are matched in whiteList. By default, any filename 
    with a dot (".") in it will be excluded. Since EPF filenames never include a dot, this permits 
    placing any file with an extension (e.g., .txt) in the directory without disrupting the import.
    
    Returns a list of any files for which the import failed (empty if all succeeded)
    """    
    #Exclude files with a dot (for example, the invisible .DSStore files HFS+ uses)
    if not allowExtensions:
        blackList.append(r'.*\..*?') 
       
    wListRe = (r"|".join(whiteList) if whiteList else r"$a^") #The latter can never match anything
    bListRe = (r"|".join(blackList) if blackList else r"$a^") #The latter can never match anything
    wMatcher = re.compile(wListRe)
    bMatcher = re.compile(bListRe)
    
    dirPath = os.path.abspath(directoryPath)
    fileList = os.listdir(dirPath)
    #filter the list down to the entries matching our whitelist/blacklist
    fileList = [f for f in fileList if (wMatcher.search(f) and not bMatcher.search(f))]
    fileList.sort()
    filesLeft = copy.copy(fileList)
    filesImported = []
    failedFiles = []
    
    SNAPSHOT_DICT['tablePrefix'] = tablePrefix
    SNAPSHOT_DICT['wList'] = whiteList
    SNAPSHOT_DICT['bList'] = blackList
    #remove this directory from the "left to do" directories
    try:
        SNAPSHOT_DICT['dirsLeft'].remove(dirPath)
    except ValueError:
        pass
        
    currentDict = SNAPSHOT_DICT['currentDict']
    currentDict['recordSep'] = recordDelim
    currentDict['fieldSep'] = fieldDelim
    currentDict['dirPath'] = dirPath
    currentDict['filesToImport'] = fileList
    currentDict['filesLeft'] = filesLeft
    currentDict['filesImported'] = filesImported
    currentDict['failedFiles'] = failedFiles
    
    
    _dumpDict(SNAPSHOT_DICT, SNAPSHOT_PATH)
    pathList = [os.path.join(dirPath, fileName) for fileName in fileList]
    
    startTime = datetime.datetime.now()
    LOGGER.info("Starting import of %s...", dirPath)
    for aPath in pathList:
        fName = os.path.basename(aPath)
        #In order to keep supposedly "matching" warnings from being suppressed during future
        #ingests, we need to clear the module's warning registry before each ingest
        try:
            EPFIngester.__warningregistry__.clear()
        except AttributeError:
            pass
            
        try: 
            ing = EPFIngester.Ingester(aPath,
                tablePrefix=tablePrefix,
                dbHost=dbHost,
                dbUser=dbUser,
                dbPassword=dbPassword,
                dbName=dbName,
                recordDelim=recordDelim,
                fieldDelim=fieldDelim)
        except Exception, e:
            LOGGER.error("Unable to create EPFIngester for %s", fName)
            LOGGER.exception(e)
            failedFiles.append(fName)
            _dumpDict(SNAPSHOT_DICT, SNAPSHOT_PATH)
            continue
                        
        try:
            ing.ingest(skipKeyViolators=skipKeyViolators)
            filesLeft.remove(fName)
            filesImported.append(fName)
            _dumpDict(SNAPSHOT_DICT, SNAPSHOT_PATH)
        except MySQLdb.Error, e:
            failedFiles.append(fName)
            _dumpDict(SNAPSHOT_DICT, SNAPSHOT_PATH)
            continue
    
    endTime = datetime.datetime.now()
    ts = str(endTime - startTime)
    dirName = os.path.basename(dirPath)
    LOGGER.info("Import of %s completed at: %s", dirName, 
        endTime.strftime(EPFIngester.DATETIME_FORMAT))
    LOGGER.info("Total import time for %s: %s" , dirName, ts[:len(ts)-4])
    if (failedFiles):
        LOGGER.warning("The following files encountered errors and were not imported:\n %s",
            ", ".join(failedFiles))
    return failedFiles


def resumeImport(currentDict,
        tablePrefix=None,
        dbHost='localhost',
        dbUser='epfimporter',
        dbPassword='epf123',
        dbName='epf',
        skipKeyViolators=False,
        recordDelim='\x02\n',
        fieldDelim='\x01'):
    """
    Resume an interrupted full import based on the values in currentDict, which will normally
    be the currentDict unarchived from the EPFSnapshot.json file.
    """
    dirPath = currentDict['dirPath'].encode('ascii')
    filesLeft = currentDict['filesLeft']
    recordDelim = currentDict['recordSep']
    fieldDelim = currentDict['fieldSep']
    wList = ["^%s$" % aFile for aFile in filesLeft] #anchor the regexes for exact matches
    filesImported = currentDict['filesImported']
    bList = ["^%s$" % aFile for aFile in filesImported] #anchor the regexes for exact matches
    
    failedFiles = doImport(dirPath,
        tablePrefix=tablePrefix,
        dbHost=dbHost,
        dbUser=dbUser,
        dbPassword=dbPassword,
        dbName=dbName,
        whiteList=wList,
        blackList=bList,
        recordDelim=recordDelim,
        fieldDelim=fieldDelim)
    return failedFiles
            

def _dumpDict(aDict, filePath):
    """
    Opens the file at filePath (creating it if it doesn't exist, overwriting if not),
    writes aDict to it in json format, then closes it
    """
    LOGGER.debug("Dumping dictionary: %s", str(aDict))
    LOGGER.debug("json path: %s", str(filePath))

    with open(filePath, mode='w+') as f:
        json.dump(aDict, f, indent=4)

    
def main():
    """
    Entry point for command-line execution
    """
    #If the default config file doesn't exist, create it using these values.
    if not os.path.exists(CONFIG_PATH):
        defaultOptions = dict(dbHost='localhost',
            dbUser='epfimporter',
            dbPassword='epf123',
            dbName='epf',
            allowExtensions=False,
            tablePrefix='epf',
            whiteList=[r'.*?'],
            blackList=[r'^\.'],
            recordSep='\x02\n',
            fieldSep='\x01')
        _dumpDict(defaultOptions, CONFIG_PATH)
    #likewise for the EPF Flat config file
    if not os.path.exists(FLAT_CONFIG_PATH):
        flatOptions = dict(dbHost='localhost',
            dbUser='epfimporter',
            dbPassword='epf123',
            dbName='epf',
            allowExtensions=True,
            tablePrefix='epfflat',
            whiteList=[r'.*?'],
            blackList=[r'^\.'],
            recordSep='\n',
            fieldSep='\t')
        _dumpDict(flatOptions, FLAT_CONFIG_PATH)
        
    #Command-line parsing
    usage = """usage: %prog [-fxrak] [-d db_host] [-u db_user] [-p db_password] [-n db_name]
    [-s record_separator] [-t field_separator] [-w regex [-w regex2 [...]]] 
    [-b regex [-b regex2 [...]]] source_directory [source_directory2 ...]"""
    
    op = optparse.OptionParser(version="%prog " + VERSION, description=DESCRIPTION, usage=usage)
    op.add_option('-f', '--flat', action='store_true', dest='isFlat', default=False,
        help="""Import EPF Flat files, using values from EPFFlat.config if not overridden""")
    op.add_option('-r', '--resume', action='store_true', dest='isResume', default=False,
        help="""Resume the most recent import according to the relevant .json status file (EPFStatusIncremental.json if -i, otherwise EPFStatusFull.json)""")
    op.add_option('-d', '--dbhost', dest='dbHost',
        help="""The hostname of the database (default is localhost)""")
    op.add_option('-u', '--dbuser', dest='dbUser',
        help="""The user which will execute the database commands; must have table create/drop priveleges""")
    op.add_option('-p', '--dbpassword', dest='dbPassword',
        help="""The user's password for the database""")
    op.add_option('-n', '--dbname', dest='dbName',
        help="""The name of the database to connect to""")
    op.add_option('-s', '--recordseparator', dest='recordSep',
        help="""The string separating records in the file""")
    op.add_option('-t', '--fieldseparator', dest='fieldSep',
        help="""The string separating fields in the file""")
    op.add_option('-a', '--allowextensions', action='store_true', dest='allowExtensions', default=False,
        help="""Include files with dots in their names in the import""")
    op.add_option('-x', '--tableprefix', dest='tablePrefix',
        help="""Optional prefix which will be added to all table names, e.g. 'MyPrefix_video_translation'""")
    op.add_option('-w', '--whitelist', action='append', dest='whiteList',
        help="""A regular expression to add to the whiteList; repeated -w arguments will append""")
    op.add_option('-b', '--blacklist', action='append', dest='blackList',
        help="""A regular expression to add to the whiteList; repeated -b arguments will append""")
    op.add_option('-k', '--skipkeyviolators', action='store_true', dest='skipKeyViolators', default=False,
        help="""Ignore inserts which would violate a primary key constraint; only applies to full imports""")
    
    (options, args) = op.parse_args() #parse command-line options
    
    if not args and not options.isResume: #no directory args were given, and we're not in resume mode
        op.print_usage()
        sys.exit()
        
    #roll over the log file, so each import has its own log
    for aHandler in LOGGER.handlers:
        try:
            aHandler.doRollover()
        except AttributeError:
            pass #only the file handler has a doRollover() method
    
    configPath = (FLAT_CONFIG_PATH if options.isFlat else CONFIG_PATH)
    with open(configPath) as configFile:
        configDict = json.load(configFile)
    
    #iterate through the options dict.
    #For each entry which is None, replace it with the value from the config file
    optDict = options.__dict__
    for aKey in optDict.keys():
        if (not optDict[aKey]) and (configDict.has_key(aKey)):
            optDict[aKey] = configDict[aKey]
            
    failedFilesDict = {}
    
    #bind these to locals here; they will be rebound later if this is a resume
    dirsToImport = args
    tablePrefix = options.tablePrefix
    wList = options.whiteList
    bList = options.blackList
    recordSep = options.recordSep
    fieldSep = options.fieldSep
    allowExtensions = options.allowExtensions
    
    global SNAPSHOT_DICT, SNAPSHOT_PATH
    SNAPSHOT_DICT['dirsToImport'] = copy.copy(dirsToImport)
    SNAPSHOT_DICT['dirsLeft'] = copy.copy(dirsToImport)
    
    startTime = datetime.datetime.now()

    #call the appropriate import function
    if options.isResume:
        with open(SNAPSHOT_PATH, mode='r') as f:
            SNAPSHOT_DICT = json.load(f)
        tablePrefix = SNAPSHOT_DICT['tablePrefix']
        currentDict = SNAPSHOT_DICT['currentDict']
        LOGGER.info("Resuming import for %s", currentDict['dirPath'])
        
        failedFiles = resumeImport(currentDict,
            tablePrefix=tablePrefix,
            dbHost=options.dbHost,
            dbUser=options.dbUser,
            dbPassword=options.dbPassword,
            dbName=options.dbName,
            skipKeyViolators=options.skipKeyViolators,
            recordDelim=recordSep,
            fieldDelim=fieldSep)
        if failedFiles:
            dirName = os.path.basename(currentDict['dirPath'])
            failedFilesDict[dirName] = failedFiles
        #We've finished with the directory that was interrupted; We'll now fall through to
        #importing any directories we hadn't gotten to
        dirsToImport = SNAPSHOT_DICT['dirsLeft']
        wList = SNAPSHOT_DICT['wList']
        bList = SNAPSHOT_DICT['bList']
    
    #non-resume
    if dirsToImport:
        LOGGER.info("Beginning import for the following directories:\n    %s", "\n    ".join(dirsToImport))
        for dirPath in dirsToImport:
            dirName = os.path.basename(dirPath)
            LOGGER.info("Importing files in %s", dirPath)
            failedFiles = doImport(dirPath,
                tablePrefix=tablePrefix,
                dbHost=options.dbHost,
                dbUser=options.dbUser,
                dbPassword=options.dbPassword,
                dbName=options.dbName,
                whiteList=wList,
                blackList=bList,
                allowExtensions=allowExtensions,
                skipKeyViolators=options.skipKeyViolators,
                recordDelim=recordSep,
                fieldDelim=fieldSep)

            if failedFiles:
                failedFilesDict[dirName] = failedFiles
                
    endTime = datetime.datetime.now()
    ts = str(endTime - startTime)
    
    if failedFilesDict:
        failedList = ["    %s/%s" % (str(aKey), str(failedFilesDict[aKey])) for aKey in failedFilesDict.keys()]
        failedString = "\n".join(failedList)
        LOGGER.warning("The following files encountered errors and were not imported:\n    %s", failedString)
            
    LOGGER.info("Total import time for all directories: %s", ts[:len(ts)-4])

#Execute
if __name__ == "__main__":
    main()


    
